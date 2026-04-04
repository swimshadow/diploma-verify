import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from database import get_db
from models import Notification
from schemas import (
    ALLOWED_TYPES,
    NotificationItem,
    NotificationListResponse,
    SendRequest,
)

router = APIRouter(prefix="/internal", tags=["internal"])


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
            sent=bool(r.sent),
            sent_at=r.sent_at.isoformat() if r.sent_at else None,
            created_at=r.created_at.isoformat() if r.created_at else "",
        )
        for r in rows
    ]
    return NotificationListResponse(notifications=items)
