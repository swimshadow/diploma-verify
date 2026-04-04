import os
import uuid
from datetime import date
from typing import Any, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from sqlalchemy.orm import Session

from database import (
    cache_get_json,
    cache_set_json,
    compute_data_hash,
    get_db,
)
from http_client import HTTP_TIMEOUT
from models import VerificationLog
from schemas import ManualVerifyRequest, VerifyPublicResponse

router = APIRouter(prefix="/verify", tags=["verify"])

def _secret_salt() -> str:
    s = os.getenv("SECRET_SALT", "").strip()
    if not s:
        raise RuntimeError("SECRET_SALT must be set in the environment")
    return s


UNIVERSITY_SERVICE_URL = os.getenv(
    "UNIVERSITY_SERVICE_URL", "http://university-service:8002"
)
CERTIFICATE_SERVICE_URL = os.getenv(
    "CERTIFICATE_SERVICE_URL", "http://certificate-service:8006"
)


def _log(
    db: Session,
    diploma_id: Optional[uuid.UUID],
    method: str,
    result: bool,
    checker: Optional[uuid.UUID] = None,
):
    db.add(
        VerificationLog(
            diploma_id=diploma_id,
            checker_account_id=checker,
            check_method=method,
            result=result,
        )
    )
    db.commit()


def _build_success_payload(d: dict[str, Any]) -> dict[str, Any]:
    id_raw = d.get("issue_date")
    if isinstance(id_raw, str):
        issue_date = date.fromisoformat(id_raw[:10])
    else:
        issue_date = id_raw
    return {
        "valid": True,
        "full_name": d.get("full_name"),
        "degree": d.get("degree"),
        "specialization": d.get("specialization"),
        "issue_date": issue_date.isoformat() if hasattr(issue_date, "isoformat") else str(issue_date),
        "university_name": d.get("university_name"),
    }


def _invalid_payload() -> dict[str, Any]:
    return {
        "valid": False,
        "full_name": None,
        "degree": None,
        "specialization": None,
        "issue_date": None,
        "university_name": None,
    }


async def _verify_qr_core(qr_token: str, db: Session) -> dict[str, Any]:
    cache_key = f"verify:qr:{qr_token}"
    cached = cache_get_json(cache_key)
    if cached is not None:
        return cached

    cert_url = f"{CERTIFICATE_SERVICE_URL.rstrip('/')}/certificates/by-token/{qr_token}"
    uni_base = UNIVERSITY_SERVICE_URL.rstrip("/")
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            cr = await client.get(cert_url)
            if cr.status_code != 200:
                out = _invalid_payload()
                _log(db, None, "qr", False)
                cache_set_json(cache_key, out, 60)
                return out
            cert = cr.json()
            raw_did = cert.get("diploma_id")
            try:
                diploma_id = uuid.UUID(str(raw_did)) if raw_did else None
            except (ValueError, TypeError):
                out = _invalid_payload()
                _log(db, None, "qr", False)
                cache_set_json(cache_key, out, 60)
                return out
            if not cert.get("is_active"):
                out = _invalid_payload()
                _log(db, diploma_id, "qr", False)
                cache_set_json(cache_key, out, 60)
                return out
            if diploma_id is None:
                out = _invalid_payload()
                _log(db, None, "qr", False)
                cache_set_json(cache_key, out, 60)
                return out
            dr = await client.get(f"{uni_base}/internal/diplomas/{diploma_id}")
            if dr.status_code != 200:
                out = _invalid_payload()
                _log(db, diploma_id, "qr", False)
                cache_set_json(cache_key, out, 60)
                return out
            d = dr.json()
    except httpx.RequestError as e:
        logger.exception(f"Verify QR failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Verification upstream unavailable",
        )

    required = (
        "diploma_number",
        "full_name",
        "issue_date",
        "data_hash",
        "status",
        "id",
    )
    if not d or not all(d.get(k) is not None and d.get(k) != "" for k in required):
        out = _invalid_payload()
        _log(db, None, "qr", False)
        cache_set_json(cache_key, out, 60)
        return out

    expected_hash = compute_data_hash(
        str(d.get("series") or ""),
        str(d["diploma_number"]),
        str(d["full_name"]),
        d["issue_date"],
        _secret_salt(),
    )
    ok = (
        d.get("data_hash") == expected_hash
        and d.get("status") == "verified"
    )
    try:
        diploma_uuid = uuid.UUID(str(d["id"]))
    except (ValueError, TypeError):
        diploma_uuid = None
    _log(db, diploma_uuid, "qr", ok)
    if ok:
        out = _build_success_payload(d)
    else:
        out = _invalid_payload()
    cache_set_json(cache_key, out, 60)
    return out


@router.get("/qr/{qr_token}", response_model=VerifyPublicResponse)
async def verify_qr(qr_token: str, db: Session = Depends(get_db)):
    data = await _verify_qr_core(qr_token, db)
    return VerifyPublicResponse.model_validate(data)


@router.get("/{qr_token}", response_model=VerifyPublicResponse)
async def verify_qr_legacy(qr_token: str, db: Session = Depends(get_db)):
    """Совместимость: /api/verify/{uuid} из frontend (без сегмента qr)."""
    data = await _verify_qr_core(qr_token, db)
    return VerifyPublicResponse.model_validate(data)


@router.post("/manual", response_model=VerifyPublicResponse)
async def verify_manual(payload: ManualVerifyRequest, db: Session = Depends(get_db)):
    h = compute_data_hash(
        payload.series or "",
        payload.diploma_number,
        payload.full_name,
        payload.issue_date,
        _secret_salt(),
    )
    url = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/by-hash/{h}"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.get(url)
    except httpx.RequestError as e:
        logger.exception(f"Manual verify failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="University service unavailable",
        )
    if r.status_code != 200:
        _log(db, None, "manual_not_found", False)
        return VerifyPublicResponse.model_validate(_invalid_payload())
    d = r.json()
    # Сценарий А: студент привязан к диплому; Б: только хеш (студент не в системе / не привязан)
    registered = bool(d.get("student_account_id"))
    check_method = "manual_registered" if registered else "manual_unregistered"
    ok = d.get("status") == "verified"
    try:
        did = uuid.UUID(d["id"]) if d.get("id") else None
    except Exception:
        did = None
    _log(db, did, check_method, ok)
    if ok:
        return VerifyPublicResponse.model_validate(_build_success_payload(d))
    return VerifyPublicResponse.model_validate(_invalid_payload())
