import base64
import hashlib
import hmac
import os
import time
import uuid
from datetime import date
from typing import Any, Optional

import httpx
import rsa
from fastapi import APIRouter, Depends, Header, HTTPException, Request, Response, status
from loguru import logger
from sqlalchemy.orm import Session

from database import (
    cache_get_json,
    cache_set_json,
    compute_data_hash,
    get_db,
    get_redis,
)
from http_client import HTTP_TIMEOUT
from models import VerificationLog
from schemas import ManualVerifyRequest, VerifyPublicResponse

UNIVERSITY_SERVICE_URL = os.getenv(
    "UNIVERSITY_SERVICE_URL", "http://university-service:8002"
)
BLOCKCHAIN_SERVICE_URL = os.getenv(
    "BLOCKCHAIN_SERVICE_URL", "http://blockchain-service:8009"
)


def _verify_signature(diploma_data: dict, signature: str, public_key_data: bytes) -> bool:
    if not signature:
        return False
    try:
        public_key = rsa.PublicKey.load_pkcs1(public_key_data)
        message = (
            f"{diploma_data['diploma_number']}|{diploma_data['full_name']}|{diploma_data['issue_date']}|{diploma_data['university_name']}"
        )
        rsa.verify(message.encode(), base64.b64decode(signature), public_key)
        return True
    except Exception:
        return False


async def check_rate_limit(client_ip: str, redis_client):
    key = f"ratelimit:{client_ip}"
    count = redis_client.incr(key)
    if count == 1:
        redis_client.expire(key, 60)
    ttl = redis_client.ttl(key)
    if ttl < 0:
        ttl = 60
    if count > 20:
        raise HTTPException(429, "Too many requests. Try again later.")
    return count, ttl


def _rate_limit_headers(response: Response, count: int, ttl: int) -> None:
    response.headers["X-RateLimit-Limit"] = "20"
    response.headers["X-RateLimit-Remaining"] = str(max(0, 20 - count))
    response.headers["X-RateLimit-Reset"] = str(int(time.time()) + ttl)


router = APIRouter(prefix="/verify", tags=["verify"])

def _secret_salt() -> str:
    s = os.getenv("SECRET_SALT", "").strip()
    if not s:
        raise RuntimeError("SECRET_SALT must be set in the environment")
    return s


CERTIFICATE_SERVICE_URL = os.getenv(
    "CERTIFICATE_SERVICE_URL", "http://certificate-service:8006"
)
NOTIFICATION_SERVICE_URL = os.getenv(
    "NOTIFICATION_SERVICE_URL", "http://notification-service:8008"
)
AUTH_SERVICE_URL = os.getenv(
    "AUTH_SERVICE_URL", "http://auth-service:8001"
)


async def _get_account_id(authorization: str) -> uuid.UUID:
    url = f"{AUTH_SERVICE_URL.rstrip('/')}/internal/verify-token"
    token = authorization.replace("Bearer ", "").strip()
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.get(url, params={"token": token})
    except httpx.RequestError:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Auth unavailable")
    if r.status_code != 200:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    return uuid.UUID(r.json()["account_id"])


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
        "signature_verified": False,
        "blockchain_verified": False,
        "blockchain_block": None,
        "chain_intact": False,
        "timestamp_proof": d.get("timestamp_hash"),
        "reason": None,
    }


def _invalid_payload() -> dict[str, Any]:
    return {
        "valid": False,
        "full_name": None,
        "degree": None,
        "specialization": None,
        "issue_date": None,
        "university_name": None,
        "signature_verified": False,
        "blockchain_verified": False,
        "blockchain_block": None,
        "chain_intact": False,
        "timestamp_proof": None,
        "reason": None,
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
        str(d["diploma_number"]),
        str(d["full_name"]),
        d["issue_date"],
        _secret_salt(),
    )
    signature_verified = False
    reason = None
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            pk_resp = await client.get(f"{uni_base}/university/public-key")
        if pk_resp.status_code == 200:
            signature_verified = _verify_signature(
                {
                    "diploma_number": str(d["diploma_number"]),
                    "full_name": str(d["full_name"]),
                    "issue_date": str(d["issue_date"]),
                    "university_name": str(d["university_name"]),
                },
                str(d.get("digital_signature") or ""),
                pk_resp.content,
            )
        if not signature_verified:
            reason = "signature_invalid"
    except httpx.RequestError as e:
        logger.warning(f"Public key lookup failed: {e}")

    ok = (
        d.get("data_hash") == expected_hash
        and d.get("status") == "verified"
        and signature_verified
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
    out["signature_verified"] = signature_verified
    out["reason"] = reason
    out["timestamp_proof"] = d.get("timestamp_hash")
    out["blockchain_verified"] = False
    out["blockchain_block"] = None
    out["chain_intact"] = False
    if diploma_uuid is not None:
        try:
            async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
                br = await client.get(f"{BLOCKCHAIN_SERVICE_URL.rstrip('/')}/blockchain/verify/{diploma_uuid}")
            if br.status_code == 200:
                chain_data = br.json()
                out["blockchain_verified"] = bool(chain_data.get("valid", False))
                out["blockchain_block"] = chain_data.get("block_index")
                out["chain_intact"] = bool(chain_data.get("chain_intact", False))
        except httpx.RequestError as e:
            logger.warning(f"Blockchain check failed: {e}")
    cache_set_json(cache_key, out, 60)
    return out


@router.get("/history")
async def verification_history(
    authorization: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
):
    account_id = await _get_account_id(authorization)
    rows = (
        db.query(VerificationLog)
        .filter(VerificationLog.checker_account_id == account_id)
        .order_by(VerificationLog.checked_at.desc())
        .limit(50)
        .all()
    )
    items = [
        {
            "id": r.id,
            "diploma_id": str(r.diploma_id) if r.diploma_id else None,
            "check_method": r.check_method,
            "result": r.result,
            "checked_at": r.checked_at.isoformat() if r.checked_at else None,
        }
        for r in rows
    ]
    return {"items": items}


@router.get("/qr/{qr_token}", response_model=VerifyPublicResponse)
async def verify_qr(
    qr_token: str,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    count, ttl = await check_rate_limit(request.client.host or "unknown", get_redis())
    _rate_limit_headers(response, count, ttl)
    data = await _verify_qr_core(qr_token, db)
    return VerifyPublicResponse.model_validate(data)


@router.get("/{qr_token}", response_model=VerifyPublicResponse)
async def verify_qr_legacy(qr_token: str, db: Session = Depends(get_db)):
    """Совместимость: /api/verify/{uuid} из frontend (без сегмента qr)."""
    data = await _verify_qr_core(qr_token, db)
    return VerifyPublicResponse.model_validate(data)


@router.post("/manual", response_model=VerifyPublicResponse)
async def verify_manual(
    payload: ManualVerifyRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
):
    count, ttl = await check_rate_limit(request.client.host or "unknown", get_redis())
    _rate_limit_headers(response, count, ttl)

    h = compute_data_hash(
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
    registered = bool(d.get("student_account_id"))
    check_method = "manual_registered" if registered else "manual_unregistered"
    signature_verified = False
    reason = None
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            pk_resp = await client.get(f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/university/public-key")
        if pk_resp.status_code == 200:
            signature_verified = _verify_signature(
                {
                    "diploma_number": str(d["diploma_number"]),
                    "full_name": str(d["full_name"]),
                    "issue_date": str(d["issue_date"]),
                    "university_name": str(d["university_name"]),
                },
                str(d.get("digital_signature") or ""),
                pk_resp.content,
            )
        if not signature_verified:
            reason = "signature_invalid"
    except httpx.RequestError as e:
        logger.warning(f"Public key lookup failed: {e}")

    ok = d.get("status") == "verified" and signature_verified
    try:
        did = uuid.UUID(d["id"]) if d.get("id") else None
    except Exception:
        did = None
    _log(db, did, check_method, ok)
    out = _invalid_payload()
    if ok:
        out = _build_success_payload(d)
    out["signature_verified"] = signature_verified
    out["reason"] = reason
    out["timestamp_proof"] = d.get("timestamp_hash")
    out["blockchain_verified"] = False
    out["blockchain_block"] = None
    out["chain_intact"] = False
    if did is not None:
        try:
            async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
                br = await client.get(f"{BLOCKCHAIN_SERVICE_URL.rstrip('/')}/blockchain/verify/{did}")
            if br.status_code == 200:
                chain_data = br.json()
                out["blockchain_verified"] = bool(chain_data.get("valid", False))
                out["blockchain_block"] = chain_data.get("block_index")
                out["chain_intact"] = bool(chain_data.get("chain_intact", False))
        except httpx.RequestError as e:
            logger.warning(f"Blockchain check failed: {e}")
    return VerifyPublicResponse.model_validate(out)
