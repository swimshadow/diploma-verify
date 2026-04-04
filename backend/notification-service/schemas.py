from typing import List

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    service: str


ALLOWED_TYPES = frozenset(
    {
        "welcome",
        "diploma_uploaded",
        "diploma_verified",
        "diploma_revoked",
        "diploma_checked",
    }
)


class SendRequest(BaseModel):
    account_id: str
    type: str = Field(..., max_length=64)
    subject: str
    body: str
    route: str | None = None


class NotificationItem(BaseModel):
    id: str
    account_id: str
    type: str
    subject: str
    body: str
    is_read: bool
    route: str | None
    sent: bool
    sent_at: str | None
    created_at: str


class NotificationListResponse(BaseModel):
    notifications: List[NotificationItem]
