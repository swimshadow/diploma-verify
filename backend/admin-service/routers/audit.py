import os
import uuid
from datetime import datetime
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from loguru import logger

from routers.accounts import get_admin_user
from schemas import AuditItemResponse, AuditListResponse

router = APIRouter(prefix="/admin", tags=["admin"])

NOTIFICATION_SERVICE_URL = os.getenv(
    "NOTIFICATION_SERVICE_URL", "http://notification-service:8008"
)


@router.get("/audit", response_model=AuditListResponse)
async def list_audit(
    actor_id: Optional[uuid.UUID] = Query(None),
    action: Optional[str] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    admin: dict = Depends(get_admin_user),
):
    url = f"{NOTIFICATION_SERVICE_URL.rstrip('/')}/internal/audit"
    params: dict = {"page": page, "limit": limit}
    if actor_id:
        params["actor_id"] = str(actor_id)
    if action:
        params["action"] = action
    if date_from:
        params["date_from"] = date_from.isoformat()
    if date_to:
        params["date_to"] = date_to.isoformat()
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            r = await client.get(url, params=params)
    except httpx.RequestError as e:
        logger.error(f"Notification audit unreachable: {e}")
        raise HTTPException(503, "Audit service unavailable")
    if r.status_code != 200:
        raise HTTPException(r.status_code, r.text)
    data = r.json()
    items = [
        AuditItemResponse(
            id=i["id"],
            timestamp=datetime.fromisoformat(str(i["timestamp"]).replace("Z", "+00:00")),
            actor_id=i.get("actor_id"),
            actor_role=i.get("actor_role"),
            actor_ip=i.get("actor_ip"),
            action=i["action"],
            resource_type=i.get("resource_type"),
            resource_id=i.get("resource_id"),
            old_value=i.get("old_value"),
            new_value=i.get("new_value"),
            success=i.get("success", True),
            error_message=i.get("error_message"),
        )
        for i in data.get("items", [])
    ]
    return AuditListResponse(
        items=items,
        total=data.get("total", 0),
        page=data.get("page", page),
        limit=data.get("limit", limit),
    )
