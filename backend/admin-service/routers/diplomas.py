import uuid
from datetime import date, datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database import get_auth_db, get_university_db, Diploma, Account
from routers.accounts import get_admin_user
from schemas import DiplomaDetailResponse, DiplomaItem, DiplomaListResponse, DiplomasStatsResponse

router = APIRouter(prefix="/admin", tags=["admin"])


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
        query = query.filter(Diploma.created_at >= date_from)
    if date_to:
        query = query.filter(Diploma.created_at <= date_to)

    total = query.count()
    diplomas = query.offset((page - 1) * limit).limit(limit).all()

    items = []
    for d in diplomas:
        university_name = _get_university_name(d.university_account_id, auth_db)
        items.append(DiplomaItem(
            id=d.id,
            diploma_number=d.diploma_number,
            series=d.series,
            full_name=d.full_name,
            degree=d.degree,
            specialization=d.specialization,
            issue_date=d.issue_date,
            status=d.status,
            created_at=d.created_at,
            university_name=university_name,
            student_account_id=d.student_account_id
        ))

    return DiplomaListResponse(diplomas=items, total=total, page=page, limit=limit)


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
        full_name=d.full_name,
        degree=d.degree,
        specialization=d.specialization,
        issue_date=d.issue_date,
        status=d.status,
        created_at=d.created_at,
        university_name=university_name,
        student_account_id=d.student_account_id,
        ai_extracted_data=d.ai_extracted_data
    )


@router.get("/diplomas/stats", response_model=DiplomasStatsResponse)
async def diplomas_stats(
    db: Session = Depends(get_university_db),
    admin: dict = Depends(get_admin_user),
):
    total = db.query(Diploma).count()
    by_status = {}
    for status in ["pending", "verified", "revoked"]:
        by_status[status] = db.query(Diploma).filter(Diploma.status == status).count()

    today = datetime.utcnow().date()
    verified_today = db.query(Diploma).filter(
        Diploma.status == "verified",
        Diploma.created_at >= today
    ).count()

    week_ago = datetime.utcnow() - timedelta(days=7)
    verified_this_week = db.query(Diploma).filter(
        Diploma.status == "verified",
        Diploma.created_at >= week_ago
    ).count()

    month_ago = datetime.utcnow() - timedelta(days=30)
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