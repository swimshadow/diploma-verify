from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class AuditIn(BaseModel):
    actor_id: Optional[UUID] = None
    actor_role: Optional[str] = None
    actor_ip: Optional[str] = None
    action: str = Field(..., max_length=128)
    resource_type: Optional[str] = None
    resource_id: Optional[UUID] = None
    old_value: Optional[dict[str, Any]] = None
    new_value: Optional[dict[str, Any]] = None
    success: bool = True
    error_message: Optional[str] = None


class AuditItem(BaseModel):
    id: str
    timestamp: datetime
    actor_id: Optional[str] = None
    actor_role: Optional[str] = None
    actor_ip: Optional[str] = None
    action: str
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    old_value: Optional[dict[str, Any]] = None
    new_value: Optional[dict[str, Any]] = None
    success: bool
    error_message: Optional[str] = None


class AuditListResponse(BaseModel):
    items: list[AuditItem]
    total: int
    page: int
    limit: int
