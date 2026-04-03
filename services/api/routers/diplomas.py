import base64
import io
import uuid
from typing import Dict, Optional

import qrcode
from fastapi import APIRouter, Depends, Header, HTTPException, status
from loguru import logger
from qrcode.constants import ERROR_CORRECT_M
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import get_db, authenticate_university, hash_diploma_data
from models import Certificate, Diploma, University
from schemas import (
    DiplomaCreateRequest,
    DiplomaCreateResponse,
    DiplomaListItem,
    DiplomaListResponse,
    DiplomaRevokeResponse,
)


router = APIRouter(tags=["diplomas"])


def get_current_university(
    db: Session = Depends(get_db),
    x_api_key: Optional[str] = Header(default=None, alias="X-API-Key"),
) -> University:
    try:
        if not x_api_key:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing X-API-Key")

        uni = authenticate_university(db, x_api_key)
        if uni is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API key")

        return uni
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Auth error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")


def build_qr_code_base64(diploma_token: uuid.UUID) -> str:
    """
    Generates base64-encoded PNG QR containing:
    http://localhost/verify/{qr_token}
    """
    qr_url = f"http://localhost/verify/{diploma_token}"
    try:
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
    except Exception as e:
        logger.exception(f"QR generation failed: {e}")
        raise


@router.post("", response_model=DiplomaCreateResponse, status_code=status.HTTP_201_CREATED)
def add_diploma(
    payload: DiplomaCreateRequest,
    db: Session = Depends(get_db),
    uni: University = Depends(get_current_university),
):
    try:
        diploma_data_hash = hash_diploma_data(
            diploma_number=payload.diploma_number,
            student_name=payload.student_name,
            issue_date=payload.issue_date,
        )

        diploma = Diploma(
            university_id=int(uni.id),
            student_name=payload.student_name,
            student_dob=payload.student_dob,
            degree=payload.degree,
            specialization=payload.specialization,
            issue_date=payload.issue_date,
            diploma_number=payload.diploma_number,
            data_hash=diploma_data_hash,
        )
        db.add(diploma)
        db.flush()  # obtains diploma.id

        token = uuid.uuid4()
        qr_code_base64 = build_qr_code_base64(token)
        cert = Certificate(diploma_id=int(diploma.id), qr_token=token, is_active=True)
        db.add(cert)

        db.commit()
        db.refresh(diploma)

        return DiplomaCreateResponse(
            diploma_id=int(diploma.id),
            qr_token=str(token),
            qr_code_base64=qr_code_base64,
        )
    except IntegrityError as e:
        db.rollback()
        logger.exception(f"Add diploma failed (IntegrityError): {e}")
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Diploma already exists")
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        logger.exception(f"Add diploma failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")


@router.get("", response_model=DiplomaListResponse)
def list_diplomas(
    db: Session = Depends(get_db),
    uni: University = Depends(get_current_university),
):
    try:
        diplomas = db.query(Diploma).filter(Diploma.university_id == uni.id).all()
        diploma_ids = [int(d.id) for d in diplomas]

        active_certs: Dict[int, Certificate] = {}
        if diploma_ids:
            certs = (
                db.query(Certificate)
                .filter(Certificate.diploma_id.in_(diploma_ids), Certificate.is_active.is_(True))
                .all()
            )
            active_certs = {int(c.diploma_id): c for c in certs}

        items = []
        for d in diplomas:
            c = active_certs.get(int(d.id))
            items.append(
                DiplomaListItem(
                    id=int(d.id),
                    student_name=d.student_name,
                    student_dob=d.student_dob,
                    degree=d.degree,
                    specialization=d.specialization,
                    issue_date=d.issue_date,
                    diploma_number=d.diploma_number,
                    is_active=bool(c is not None),
                    qr_token=str(c.qr_token) if c is not None else None,
                )
            )

        return DiplomaListResponse(diplomas=items)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"List diplomas failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")


@router.delete("/{diploma_id}", response_model=DiplomaRevokeResponse)
def revoke_diploma(
    diploma_id: int,
    db: Session = Depends(get_db),
    uni: University = Depends(get_current_university),
):
    try:
        diploma = db.query(Diploma).filter(Diploma.id == diploma_id, Diploma.university_id == uni.id).first()
        if diploma is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diploma not found")

        updated = (
            db.query(Certificate)
            .filter(Certificate.diploma_id == diploma.id)
            .update({"is_active": False}, synchronize_session=False)
        )
        db.commit()

        return DiplomaRevokeResponse(revoked=bool(int(updated) > 0))
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        logger.exception(f"Revoke diploma failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")

