import os
import uuid
from datetime import date

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, status
from loguru import logger

from deps import get_current_user
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


async def require_student(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "student":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return user


@router.get("", response_model=StudentDiplomaListResponse)
async def list_my_diplomas(
    authorization: str = Header(..., alias="Authorization"),
    user: dict = Depends(require_student),
):
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
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    me = mr.json()
    profile = me.get("profile") or {}
    full_name = profile.get("full_name")
    dob_s = profile.get("date_of_birth")
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
        return StudentDiplomaListResponse(diplomas=[])
    items_raw = sr2.json().get("diplomas") or []
    out: list[StudentDiplomaItem] = []
    for d in items_raw:
        if d.get("student_account_id") != str(account_id):
            continue
        out.append(
            StudentDiplomaItem(
                id=d["id"],
                full_name=d["full_name"],
                diploma_number=d["diploma_number"],
                issue_date=date.fromisoformat(str(d["issue_date"])),
                status=d["status"],
            )
        )
    return StudentDiplomaListResponse(diplomas=out)


@router.get("/{diploma_id}/certificate")
async def get_certificate(
    diploma_id: uuid.UUID,
    authorization: str = Header(..., alias="Authorization"),
    user: dict = Depends(require_student),
):
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
