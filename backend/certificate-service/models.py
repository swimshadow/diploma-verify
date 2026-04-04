import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    certificate_number = Column(String(20), nullable=True, unique=True)
    diploma_id = Column(UUID(as_uuid=True), nullable=False, unique=True)
    qr_token = Column(UUID(as_uuid=True), nullable=False, unique=True)
    qr_code_base64 = Column(Text, nullable=False)
    issued_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
    is_active = Column(Boolean, nullable=False, default=True)
