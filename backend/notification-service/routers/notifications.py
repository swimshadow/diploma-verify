import os
import uuid

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, status
from loguru import logger
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from database import get_db
from models import Notification
from schemas import NotificationItem, NotificationListResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])

AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8001")
HTTP_TIMEOUT = float(os.getenv("HTTP_CLIENT_TIMEOUT", "10"))


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


@router.get("", response_model=NotificationListResponse)
async def my_notifications(
    authorization: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
):
    account_id = await _get_account_id(authorization)
    try:
        rows = (
            db.query(Notification)
            .filter(Notification.account_id == account_id)
            .order_by(Notification.created_at.desc())
            .limit(50)
            .all()
        )
    except SQLAlchemyError as e:
        logger.exception(f"Notification list failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="DB error")
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


@router.patch("/{notification_id}/read")
async def mark_notification_read(
    notification_id: uuid.UUID,
    authorization: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
):
    account_id = await _get_account_id(authorization)
    row = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.account_id == account_id,
    ).first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    row.is_read = True
    try:
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="DB error")
    return {"ok": True}


@router.patch("/read-all")
async def mark_all_notifications_read(
    authorization: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
):
    account_id = await _get_account_id(authorization)
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
