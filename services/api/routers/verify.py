import json
from datetime import date
from typing import Any, Dict, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from sqlalchemy.orm import Session, joinedload

from database import get_db, get_redis_client, hash_diploma_data
from models import Certificate, Diploma
from schemas import ManualVerifyRequest, VerifyResponse


router = APIRouter(tags=["verify"])


def _invalid_response() -> Dict[str, Any]:
    return VerifyResponse(valid=False).model_dump()


def _serialize_payload(payload: VerifyResponse) -> Dict[str, Any]:
    """
    Ensure payload is JSON-serializable for Redis.
    """
    data = payload.model_dump()
    if data.get("issue_date") is not None:
        issue_date = data["issue_date"]
        data["issue_date"] = issue_date.isoformat() if hasattr(issue_date, "isoformat") else str(issue_date)
    return data


@router.get("/verify/{qr_token}", response_model=VerifyResponse)
def verify_by_qr(
    qr_token: str,
    db: Session = Depends(get_db),
):
    try:
        try:
            token = UUID(qr_token)
        except Exception:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid qr_token format")

        redis_cache_key = f"verify:{qr_token}"

        # Try Redis cache first.
        try:
            redis_client = get_redis_client()
            cached = redis_client.get(redis_cache_key)
            if cached:
                payload = json.loads(cached.decode("utf-8"))
                return payload
        except Exception as e:
            logger.warning(f"Redis cache read failed (fallback to DB): {e}")

        cert = (
            db.query(Certificate)
            .options(joinedload(Certificate.diploma).joinedload(Diploma.university))
            .filter(Certificate.qr_token == token, Certificate.is_active.is_(True))
            .first()
        )

        if cert is None or cert.diploma is None:
            invalid_payload = _invalid_response()
            try:
                redis_client = get_redis_client()
                redis_client.setex(redis_cache_key, 60, json.dumps(invalid_payload))
            except Exception as e:
                logger.warning(f"Redis cache set failed: {e}")
            return invalid_payload

        d = cert.diploma
        payload_obj = VerifyResponse(
            valid=True,
            student_name=d.student_name,
            degree=d.degree,
            specialization=d.specialization,
            issue_date=d.issue_date,
            university_name=d.university.name if d.university is not None else None,
        )
        payload = _serialize_payload(payload_obj)

        try:
            redis_client = get_redis_client()
            redis_client.setex(redis_cache_key, 60, json.dumps(payload))
        except Exception as e:
            logger.warning(f"Redis cache set failed: {e}")

        return payload
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Verify by QR failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")


@router.post("/verify/manual", response_model=VerifyResponse)
def verify_manual(
    payload: ManualVerifyRequest,
    db: Session = Depends(get_db),
):
    try:
        diploma_hash = hash_diploma_data(
            diploma_number=payload.diploma_number,
            student_name=payload.student_name,
            issue_date=payload.issue_date,
        )

        diploma = db.query(Diploma).options(joinedload(Diploma.university)).filter(Diploma.data_hash == diploma_hash).first()
        if diploma is None:
            return _invalid_response()

        cert = (
            db.query(Certificate)
            .filter(Certificate.diploma_id == diploma.id, Certificate.is_active.is_(True))
            .first()
        )

        if cert is None:
            return _invalid_response()

        return VerifyResponse(
            valid=True,
            student_name=diploma.student_name,
            degree=diploma.degree,
            specialization=diploma.specialization,
            issue_date=diploma.issue_date,
            university_name=diploma.university.name if diploma.university is not None else None,
        )
    except Exception as e:
        logger.exception(f"Manual verify failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")

