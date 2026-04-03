import uuid
from datetime import date, datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_verify_db, get_university_db, get_auth_db, VerificationLog, Diploma, Account
from routers.accounts import get_admin_user
from schemas import LogsStatsResponse, VerificationLogItem, VerificationLogsResponse

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/logs/verifications", response_model=VerificationLogsResponse)
async def list_verification_logs(
    diploma_id: Optional[uuid.UUID] = Query(None),
    check_method: Optional[str] = Query(None),
    result: Optional[bool] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    verify_db: Session = Depends(get_verify_db),
    university_db: Session = Depends(get_university_db),
    auth_db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    query = verify_db.query(VerificationLog)

    if diploma_id:
        query = query.filter(VerificationLog.diploma_id == diploma_id)
    if check_method:
        query = query.filter(VerificationLog.check_method == check_method)
    if result is not None:
        query = query.filter(VerificationLog.result == result)
    if date_from:
        query = query.filter(VerificationLog.checked_at >= date_from)
    if date_to:
        query = query.filter(VerificationLog.checked_at <= date_to)

    total = query.count()
    logs = query.offset((page - 1) * limit).limit(limit).all()

    items = []
    for log in logs:
        # Get diploma data from universitydb
        diploma = None
        if log.diploma_id:
            diploma = university_db.query(Diploma).filter(Diploma.id == log.diploma_id).first()
        diploma_number = diploma.diploma_number if diploma else None
        full_name = diploma.full_name if diploma else None

        # Get checker data from authdb
        account = None
        if log.checker_account_id:
            account = auth_db.query(Account).filter(Account.id == log.checker_account_id).first()
        checker_email = account.email if account else None

        items.append(VerificationLogItem(
            id=log.id,
            diploma_id=log.diploma_id,
            diploma_number=diploma_number,
            full_name=full_name,
            checker_account_id=log.checker_account_id,
            checker_email=checker_email,
            check_method=log.check_method,
            result=log.result,
            checked_at=log.checked_at
        ))

    return VerificationLogsResponse(logs=items, total=total, page=page, limit=limit)


@router.get("/logs/stats", response_model=LogsStatsResponse)
async def logs_stats(
    verify_db: Session = Depends(get_verify_db),
    university_db: Session = Depends(get_university_db),
    admin: dict = Depends(get_admin_user),
):
    all_logs = verify_db.query(VerificationLog).all()
    
    total_checks = len(all_logs)
    successful_checks = len([l for l in all_logs if l.result == True])
    failed_checks = len([l for l in all_logs if l.result == False])

    today = datetime.utcnow().date()
    checks_today = len([l for l in all_logs if l.checked_at.date() == today])

    week_ago = datetime.utcnow() - timedelta(days=7)
    checks_this_week = len([l for l in all_logs if l.checked_at >= week_ago])

    # Most checked diplomas
    diploma_check_counts = {}
    for log in all_logs:
        if log.diploma_id:
            diploma_check_counts[log.diploma_id] = diploma_check_counts.get(log.diploma_id, 0) + 1
    
    most_checked_diplomas = []
    for diploma_id, count in sorted(diploma_check_counts.items(), key=lambda x: x[1], reverse=True)[:10]:
        diploma = university_db.query(Diploma).filter(Diploma.id == diploma_id).first()
        if diploma:
            most_checked_diplomas.append({
                "diploma_id": str(diploma_id),
                "full_name": diploma.full_name,
                "check_count": count
            })

    # Checks by method
    checks_by_method = {}
    for log in all_logs:
        method = log.check_method
        checks_by_method[method] = checks_by_method.get(method, 0) + 1

    return LogsStatsResponse(
        total_checks=total_checks,
        successful_checks=successful_checks,
        failed_checks=failed_checks,
        checks_today=checks_today,
        checks_this_week=checks_this_week,
        most_checked_diplomas=most_checked_diplomas,
        checks_by_method=checks_by_method
    )