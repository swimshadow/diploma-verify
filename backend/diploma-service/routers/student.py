import os
import uuid
from datetime import date

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, status
from loguru import logger

from deps import require_role
from http_client import HTTP_TIMEOUT
from schemas import StudentDiplomaItem, StudentDiplomaListResponse

router = APIRouter(prefix="/diplomas", tags=["student"])

AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8001")
UNIVERSITY_SERVICE_URL = os.getenv(
    "UNIVERSITY_SERVICE_URL", "http://university-service:8002"
)
CERTIFICATE_SERVICE_URL = os.getenv(
    "CERTIFICATE_SERVICE_URL", "http://certificate-service:8006"
)


@router.get("", response_model=StudentDiplomaListResponse)
async def list_my_diplomas(
    authorization: str = Header(..., alias="Authorization"),
    user: dict = Depends(require_role("student")),
):
    logger.info(f"[STUDENT] Запрос списка дипломов: user={user.get('sub')}")
    me_url = f"{AUTH_SERVICE_URL.rstrip('/')}/auth/me"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            mr = await client.get(me_url, headers={"Authorization": authorization})
    except httpx.RequestError as e:
        logger.warning(f"auth/me failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth service unavailable",
        )
    if mr.status_code != 200:
        logger.warning(f"[STUDENT] auth/me вернул {mr.status_code}")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    me = mr.json()
    profile = me.get("profile") or {}
    full_name = profile.get("full_name")
    dob_s = profile.get("date_of_birth")
    logger.info(f"[STUDENT] Профиль: full_name={full_name}, dob={dob_s}")
    if not full_name or not dob_s:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Profile incomplete",
        )
    try:
        dob = date.fromisoformat(dob_s)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid date_of_birth",
        )
    account_id = uuid.UUID(me["account_id"])
    search_url = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/search"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            sr = await client.get(
                search_url,
                params={"full_name": full_name, "date_of_birth": dob.isoformat()},
            )
            if sr.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="University service error",
                )
            data = sr.json()
            items_raw = data.get("diplomas") or []

            for d in items_raw:
                did = d.get("id")
                if not did:
                    continue
                sid = d.get("student_account_id")
                if sid is None:
                    link_url = (
                        f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/"
                        f"{did}/link-student"
                    )
                    try:
                        lr = await client.patch(
                            link_url,
                            json={"student_account_id": str(account_id)},
                        )
                        if lr.status_code >= 400:
                            logger.warning(f"link-student HTTP {lr.status_code}: {lr.text}")
                    except httpx.RequestError as e:
                        logger.warning(f"link-student failed: {e}")

            sr2 = await client.get(
                search_url,
                params={"full_name": full_name, "date_of_birth": dob.isoformat()},
            )
    except HTTPException:
        raise
    except httpx.RequestError as e:
        logger.exception(f"Search failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="University service unavailable",
        )

    if sr2.status_code != 200:
        logger.warning(f"[STUDENT] Повторный поиск вернул {sr2.status_code}")
        return StudentDiplomaListResponse(diplomas=[])
    items_raw = sr2.json().get("diplomas") or []
    logger.info(f"[STUDENT] Найдено дипломов: {len(items_raw)}")
    out: list[StudentDiplomaItem] = []
    for d in items_raw:
        if d.get("student_account_id") != str(account_id):
            continue
        status_val = d["status"]
        trust = _compute_trust_score(status_val, d.get("ai_confidence"), d.get("digital_signature"))
        af_score, af_verdict, af_warnings = _compute_antifraud(
            status_val, d.get("ai_confidence"), d.get("digital_signature")
        )
        # Fetch certificate ID if verified
        cert_id = None
        if status_val == "verified":
            try:
                cert_url = f"{CERTIFICATE_SERVICE_URL.rstrip('/')}/certificates/{d['id']}"
                async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as c2:
                    cr = await c2.get(cert_url)
                if cr.status_code == 200:
                    cert_id = cr.json().get("qr_token")
            except httpx.RequestError:
                pass
        out.append(
            StudentDiplomaItem(
                id=d["id"],
                full_name=d["full_name"],
                diploma_number=d["diploma_number"],
                series=d.get("series"),
                degree=d.get("degree", ""),
                specialization=d.get("specialization", ""),
                issue_date=date.fromisoformat(str(d["issue_date"])),
                university_name=d.get("university_name", ""),
                status=status_val,
                trust_score=trust,
                certificate_id=cert_id,
                file_id=d.get("file_id"),
                antifraud_score=af_score,
                antifraud_verdict=af_verdict,
                antifraud_warnings=af_warnings,
                ai_confidence=d.get("ai_confidence"),
                digital_signature=d.get("digital_signature"),
                created_at=d.get("created_at"),
            )
        )
    logger.info(f"[STUDENT] Возвращаем {len(out)} дипломов для user={user.get('sub')}")
    return StudentDiplomaListResponse(diplomas=out)


def _compute_trust_score(status: str, ai_conf: float | None, sig: str | None) -> float:
    if status == "revoked":
        return 0.0
    score = 0.0
    if status == "verified":
        score += 0.5
    elif status == "pending":
        score += 0.1
    if ai_conf is not None:
        score += ai_conf * 0.3
    if sig:
        score += 0.2
    return min(round(score, 2), 1.0)


def _compute_antifraud(
    status: str, ai_conf: float | None, sig: str | None
) -> tuple[float, str, list[str]]:
    warnings: list[str] = []
    score = 0.5
    if status == "verified" and sig:
        score += 0.3
    if status == "revoked":
        score = 0.1
        warnings.append("Диплом отозван")
    if ai_conf is not None:
        if ai_conf >= 0.85:
            score += 0.2
        elif ai_conf < 0.5:
            warnings.append("Низкая уверенность AI-распознавания")
    else:
        warnings.append("AI-проверка не выполнена")
    if not sig:
        warnings.append("Отсутствует цифровая подпись")
    score = min(round(score, 2), 1.0)
    if score >= 0.7:
        verdict = "Подлинный документ"
    elif score >= 0.4:
        verdict = "Требуется дополнительная проверка"
    else:
        verdict = "Подозрение на подделку"
    return score, verdict, warnings


@router.get("/{diploma_id}/certificate")
async def get_certificate(
    diploma_id: uuid.UUID,
    authorization: str = Header(..., alias="Authorization"),
    user: dict = Depends(require_role("student")),
):
    logger.info(f"[STUDENT] Запрос сертификата: diploma_id={diploma_id}, user={user.get('sub')}")
    me_url = f"{AUTH_SERVICE_URL.rstrip('/')}/auth/me"
    search_base = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/search"
    cert_url = f"{CERTIFICATE_SERVICE_URL.rstrip('/')}/certificates/{diploma_id}"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            mr = await client.get(me_url, headers={"Authorization": authorization})
            if mr.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Unauthorized",
                )
            me = mr.json()
            account_id = me["account_id"]
            profile = me.get("profile") or {}
            full_name = profile.get("full_name")
            dob_s = profile.get("date_of_birth")
            if not full_name or not dob_s:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Bad profile",
                )
            dob = date.fromisoformat(dob_s)
            sr = await client.get(
                search_base,
                params={"full_name": full_name, "date_of_birth": dob.isoformat()},
            )
            if sr.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Not found",
                )
            allowed = {
                x["id"]
                for x in (sr.json().get("diplomas") or [])
                if x.get("student_account_id") == account_id
            }
            if str(diploma_id) not in allowed:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Not found",
                )
            cr = await client.get(cert_url)
    except HTTPException:
        raise
    except httpx.RequestError as e:
        logger.warning(f"Certificate fetch chain failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Upstream service unavailable",
        )
    if cr.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate not found",
        )
    return cr.json()
