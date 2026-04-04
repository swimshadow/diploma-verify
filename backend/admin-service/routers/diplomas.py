import os
import uuid
from datetime import date, datetime, timedelta, timezone
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from loguru import logger
from sqlalchemy.orm import Session

from database import get_auth_db, get_university_db, Diploma, Account
from routers.accounts import get_admin_user
from schemas import (
    DiplomaDetailResponse,
    DiplomaItem,
    DiplomaListResponse,
    DiplomasStatsResponse,
    ForceModerationBody,
)

router = APIRouter(prefix="/admin", tags=["admin"])

UNIVERSITY_SERVICE_URL = os.getenv(
    "UNIVERSITY_SERVICE_URL", "http://university-service:8002"
)
NOTIFICATION_SERVICE_URL = os.getenv(
    "NOTIFICATION_SERVICE_URL", "http://notification-service:8008"
)


async def _post_audit(
    *,
    actor_id: uuid.UUID,
    action: str,
    resource_id: uuid.UUID,
    new_value: dict,
) -> None:
    url = f"{NOTIFICATION_SERVICE_URL.rstrip('/')}/internal/audit"
    body = {
        "actor_id": str(actor_id),
        "actor_role": "admin",
        "actor_ip": None,
        "action": action,
        "resource_type": "diploma",
        "resource_id": str(resource_id),
        "old_value": None,
        "new_value": new_value,
        "success": True,
        "error_message": None,
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            await client.post(url, json=body)
    except httpx.RequestError as e:
        logger.warning(f"Audit post failed: {e}")


def _get_university_name(university_account_id: uuid.UUID, auth_db: Session) -> str:
    acc = auth_db.query(Account).filter(Account.id == university_account_id).first()
    if acc:
        return acc.email  # Or fetch from profile if needed
    return "Unknown"


@router.get("/diplomas", response_model=DiplomaListResponse)
async def list_diplomas(
    status: Optional[str] = Query(None),
    university_id: Optional[uuid.UUID] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_university_db),
    auth_db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    query = db.query(Diploma)
    if status:
        query = query.filter(Diploma.status == status)
    if university_id:
        query = query.filter(Diploma.university_account_id == university_id)
    if date_from:
        query = query.filter(Diploma.created_at >= datetime.combine(date_from, datetime.min.time()))
    if date_to:
        query = query.filter(Diploma.created_at <= datetime.combine(date_to, datetime.max.time()))

    total = query.count()
    diplomas = query.offset((page - 1) * limit).limit(limit).all()

    items = []
    for d in diplomas:
        university_name = _get_university_name(d.university_account_id, auth_db)
        items.append(DiplomaItem(
            id=d.id,
            diploma_number=d.diploma_number,
            series=d.series,
            full_name=d.full_name or "",
            degree=d.degree,
            specialization=d.specialization,
            issue_date=d.issue_date,
            status=d.status,
            created_at=d.created_at,
            verified_at=getattr(d, "signed_at", None),
            university_name=university_name,
            student_account_id=d.student_account_id
        ))

    return DiplomaListResponse(diplomas=items, total=total, page=page, limit=limit)


@router.get("/diplomas/stats", response_model=DiplomasStatsResponse)
async def diplomas_stats(
    db: Session = Depends(get_university_db),
    admin: dict = Depends(get_admin_user),
):
    total = db.query(Diploma).count()
    by_status = {}
    for status in ["pending", "verified", "revoked"]:
        by_status[status] = db.query(Diploma).filter(Diploma.status == status).count()

    today = datetime.now(timezone.utc).date()
    verified_today = db.query(Diploma).filter(
        Diploma.status == "verified",
        Diploma.created_at >= datetime.combine(today, datetime.min.time())
    ).count()

    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    verified_this_week = db.query(Diploma).filter(
        Diploma.status == "verified",
        Diploma.created_at >= week_ago
    ).count()

    month_ago = datetime.now(timezone.utc) - timedelta(days=30)
    verified_this_month = db.query(Diploma).filter(
        Diploma.status == "verified",
        Diploma.created_at >= month_ago
    ).count()

    return DiplomasStatsResponse(
        total=total,
        by_status=by_status,
        verified_today=verified_today,
        verified_this_week=verified_this_week,
        verified_this_month=verified_this_month
    )


@router.get("/diplomas/{diploma_id}", response_model=DiplomaDetailResponse)
async def get_diploma(
    diploma_id: uuid.UUID,
    db: Session = Depends(get_university_db),
    auth_db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    d = db.query(Diploma).filter(Diploma.id == diploma_id).first()
    if not d:
        raise HTTPException(404, "Diploma not found")

    university_name = _get_university_name(d.university_account_id, auth_db)

    return DiplomaDetailResponse(
        id=d.id,
        diploma_number=d.diploma_number,
        series=d.series,
        full_name=d.full_name or "",
        degree=d.degree,
        specialization=d.specialization,
        issue_date=d.issue_date,
        status=d.status,
        created_at=d.created_at,
        verified_at=getattr(d, "signed_at", None),
        university_name=university_name,
        student_account_id=d.student_account_id,
        ai_extracted_data=d.ai_extracted_data
    )


@router.post("/diplomas/{diploma_id}/force-verify")
async def force_verify(
    diploma_id: uuid.UUID,
    body: ForceModerationBody,
    admin: dict = Depends(get_admin_user),
):
    url = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/{diploma_id}/status"
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            r = await client.patch(
                url,
                json={"status": "verified", "moderator_note": body.reason},
            )
    except httpx.RequestError as e:
        logger.error(f"University PATCH failed: {e}")
        raise HTTPException(503, "University service unavailable")
    if r.status_code >= 400:
        raise HTTPException(r.status_code, r.text)
    aid = uuid.UUID(admin["account_id"])
    await _post_audit(
        actor_id=aid,
        action="DIPLOMA_FORCE_VERIFIED",
        resource_id=diploma_id,
        new_value={"status": "verified", "moderator_note": body.reason},
    )
    return {"ok": True, "diploma_id": str(diploma_id)}


@router.post("/diplomas/{diploma_id}/force-revoke")
async def force_revoke(
    diploma_id: uuid.UUID,
    body: ForceModerationBody,
    admin: dict = Depends(get_admin_user),
):
    url = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/{diploma_id}/status"
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            r = await client.patch(
                url,
                json={"status": "revoked", "moderator_note": body.reason},
            )
    except httpx.RequestError as e:
        logger.error(f"University PATCH failed: {e}")
        raise HTTPException(503, "University service unavailable")
    if r.status_code >= 400:
        raise HTTPException(r.status_code, r.text)
    aid = uuid.UUID(admin["account_id"])
    await _post_audit(
        actor_id=aid,
        action="DIPLOMA_FORCE_REVOKED",
        resource_id=diploma_id,
        new_value={"status": "revoked", "moderator_note": body.reason},
    )
    return {"ok": True, "diploma_id": str(diploma_id)}