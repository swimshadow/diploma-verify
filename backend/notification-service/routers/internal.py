import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from loguru import logger
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from audit_models import AuditLog
from database import get_db
from internal_deps import internal_only
from models import Notification
from schemas import (
    ALLOWED_TYPES,
    NotificationItem,
    NotificationListResponse,
    SendRequest,
)
from audit_schemas import AuditIn, AuditItem, AuditListResponse

router = APIRouter(
    prefix="/internal",
    tags=["internal"],
    dependencies=[Depends(internal_only)],
)


@router.post("/send", status_code=status.HTTP_201_CREATED)
def send_notification(payload: SendRequest, db: Session = Depends(get_db)):
    if payload.type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid type, allowed: {sorted(ALLOWED_TYPES)}",
        )
    try:
        aid = uuid.UUID(payload.account_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid account_id")
    n = Notification(
        account_id=aid,
        type=payload.type,
        subject=payload.subject,
        body=payload.body,
        route=payload.route,
        sent=False,
    )
    try:
        db.add(n)
        db.commit()
        db.refresh(n)
    except SQLAlchemyError as e:
        db.rollback()
        logger.exception(f"Notification persist failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save notification",
        )
    logger.info(
        "[notification stub] type={} account_id={} subject={}",
        payload.type,
        payload.account_id,
        payload.subject,
    )
    return {"id": str(n.id)}


@router.get("/notifications/{account_id}", response_model=NotificationListResponse)
def list_notifications(account_id: uuid.UUID, db: Session = Depends(get_db)):
    try:
        rows = (
            db.query(Notification)
            .filter(Notification.account_id == account_id)
            .order_by(Notification.created_at.desc())
            .all()
        )
    except SQLAlchemyError as e:
        logger.exception(f"Notification list failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error",
        )
    items = [
        NotificationItem(
            id=str(r.id),
            account_id=str(r.account_id),
            type=r.type,
            subject=r.subject,
            body=r.body,
            is_read=bool(r.is_read),
            route=r.route,
            sent=bool(r.sent),
            sent_at=r.sent_at.isoformat() if r.sent_at else None,
            created_at=r.created_at.isoformat() if r.created_at else "",
        )
        for r in rows
    ]
    return NotificationListResponse(notifications=items)


@router.patch("/notifications/{notification_id}/read")
def mark_read(notification_id: uuid.UUID, db: Session = Depends(get_db)):
    row = db.query(Notification).filter(Notification.id == notification_id).first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    row.is_read = True
    try:
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="DB error")
    return {"ok": True}


@router.patch("/notifications/{account_id}/read-all")
def mark_all_read(account_id: uuid.UUID, db: Session = Depends(get_db)):
    try:
        db.query(Notification).filter(
            Notification.account_id == account_id,
            Notification.is_read.is_(False),
        ).update({Notification.is_read: True})
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="DB error")
    return {"ok": True}


@router.post("/audit", status_code=status.HTTP_201_CREATED)
def create_audit(payload: AuditIn, db: Session = Depends(get_db)):
    row = AuditLog(
        actor_id=payload.actor_id,
        actor_role=payload.actor_role,
        actor_ip=payload.actor_ip,
        action=payload.action,
        resource_type=payload.resource_type,
        resource_id=payload.resource_id,
        old_value=payload.old_value,
        new_value=payload.new_value,
        success=payload.success,
        error_message=payload.error_message,
    )
    try:
        db.add(row)
        db.commit()
        db.refresh(row)
    except SQLAlchemyError as e:
        db.rollback()
        logger.exception(f"Audit persist failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to save audit")
    return {"id": str(row.id)}


@router.get("/audit", response_model=AuditListResponse)
def list_audit(
    actor_id: Optional[uuid.UUID] = Query(None),
    action: Optional[str] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    q = db.query(AuditLog)
    if actor_id:
        q = q.filter(AuditLog.actor_id == actor_id)
    if action:
        q = q.filter(AuditLog.action == action)
    if date_from:
        q = q.filter(AuditLog.timestamp >= date_from)
    if date_to:
        q = q.filter(AuditLog.timestamp <= date_to)
    total = q.count()
    rows = (
        q.order_by(AuditLog.timestamp.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )
    items = [
        AuditItem(
            id=str(r.id),
            timestamp=r.timestamp,
            actor_id=str(r.actor_id) if r.actor_id else None,
            actor_role=r.actor_role,
            actor_ip=r.actor_ip,
            action=r.action,
            resource_type=r.resource_type,
            resource_id=str(r.resource_id) if r.resource_id else None,
            old_value=r.old_value,
            new_value=r.new_value,
            success=bool(r.success),
            error_message=r.error_message,
        )
        for r in rows
    ]
    return AuditListResponse(items=items, total=total, page=page, limit=limit)
