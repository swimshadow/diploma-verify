import base64
import hashlib
import io
import os
import uuid
from datetime import datetime, timezone

import qrcode
from fastapi import APIRouter, Depends, HTTPException, Response, status
from loguru import logger
from qrcode.constants import ERROR_CORRECT_M
from sqlalchemy.orm import Session

from database import get_db
from models import Certificate
from schemas import CertificateOut, GenerateRequest, GenerateResponse

router = APIRouter(prefix="/certificates", tags=["certificates"])

VERIFY_PUBLIC_BASE_URL = os.getenv(
    "VERIFY_PUBLIC_BASE_URL", "http://localhost"
).rstrip("/")


def generate_certificate_id(diploma_id: str, issued_at: datetime) -> str:
    hash_part = hashlib.sha256(
        f"{diploma_id}{issued_at.isoformat()}".encode()
    ).hexdigest()[:6].upper()
    year = issued_at.year
    return f"CERT-{year}-{hash_part}"


def _build_qr_base64(qr_token: uuid.UUID) -> str:
    qr_url = f"{VERIFY_PUBLIC_BASE_URL}/api/verify/qr/{qr_token}"
    qr = qrcode.QRCode(
        version=None,
        error_correction=ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("utf-8")


@router.post(
    "/generate",
    response_model=GenerateResponse,
    status_code=status.HTTP_201_CREATED,
)
def generate_certificate(payload: GenerateRequest, db: Session = Depends(get_db)):
    try:
        did = uuid.UUID(payload.diploma_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid diploma_id")
    existing = db.query(Certificate).filter(Certificate.diploma_id == did).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Certificate already exists for this diploma",
        )
    qr_token = uuid.uuid4()
    b64 = _build_qr_base64(qr_token)
    now = datetime.now(timezone.utc)
    cert_num = generate_certificate_id(str(did), now)
    cert = Certificate(
        diploma_id=did,
        qr_token=qr_token,
        qr_code_base64=b64,
        is_active=True,
        certificate_number=cert_num,
    )
    db.add(cert)
    try:
        db.commit()
        db.refresh(cert)
    except Exception as e:
        db.rollback()
        logger.exception(f"Certificate create failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create certificate",
        )
    return GenerateResponse(
        certificate_id=str(cert.id),
        qr_token=str(qr_token),
        qr_code_base64=b64,
    )


def _to_out(c: Certificate) -> CertificateOut:
    return CertificateOut(
        certificate_id=str(c.id),
        certificate_number=c.certificate_number,
        diploma_id=str(c.diploma_id),
        qr_token=str(c.qr_token),
        qr_code_base64=c.qr_code_base64,
        issued_at=c.issued_at.isoformat() if c.issued_at else "",
        is_active=bool(c.is_active),
    )


@router.get("/by-token/{qr_token}", response_model=CertificateOut)
def get_by_token(qr_token: uuid.UUID, db: Session = Depends(get_db)):
    c = db.query(Certificate).filter(Certificate.qr_token == qr_token).first()
    if c is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return _to_out(c)


@router.get("/{diploma_id}", response_model=CertificateOut)
def get_by_diploma(diploma_id: uuid.UUID, db: Session = Depends(get_db)):
    c = db.query(Certificate).filter(Certificate.diploma_id == diploma_id).first()
    if c is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return _to_out(c)


@router.post("/{diploma_id}/deactivate", status_code=status.HTTP_204_NO_CONTENT)
def deactivate(diploma_id: uuid.UUID, db: Session = Depends(get_db)):
    c = db.query(Certificate).filter(Certificate.diploma_id == diploma_id).first()
    if c is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    c.is_active = False
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
