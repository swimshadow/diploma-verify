import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import declarative_base

AuditBase = declarative_base()


class AuditLog(AuditBase):
    __tablename__ = "audit_log"
    __table_args__ = {"schema": "audit"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    timestamp = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
    actor_id = Column(UUID(as_uuid=True), nullable=True)
    actor_role = Column(String(64), nullable=True)
    actor_ip = Column(String(64), nullable=True)
    action = Column(String(128), nullable=False)
    resource_type = Column(String(64), nullable=True)
    resource_id = Column(UUID(as_uuid=True), nullable=True)
    old_value = Column(JSONB, nullable=True)
    new_value = Column(JSONB, nullable=True)
    success = Column(Boolean, nullable=False, default=True)
    error_message = Column(Text, nullable=True)
