import uuid
from datetime import datetime

from sqlalchemy import BigInteger, Column, DateTime, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class FileRecord(Base):
    __tablename__ = "files"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    original_name = Column(Text, nullable=False)
    stored_path = Column(Text, nullable=False)
    mime_type = Column(String(255), nullable=True)
    size_bytes = Column(BigInteger, nullable=False)
    uploader_account_id = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
