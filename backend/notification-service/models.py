import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    type = Column(String(64), nullable=False)
    subject = Column(String(500), nullable=False)
    body = Column(Text, nullable=False)
    is_read = Column(Boolean, nullable=False, default=False)
    route = Column(String(500), nullable=True)
    sent = Column(Boolean, nullable=False, default=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
