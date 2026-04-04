import uuid

from sqlalchemy import Boolean, Column, DateTime, Integer, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class VerificationLog(Base):
    __tablename__ = "verification_log"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diploma_id = Column(UUID(as_uuid=True), nullable=True)
    checker_account_id = Column(UUID(as_uuid=True), nullable=True)
    check_method = Column(String(64), nullable=False)
    result = Column(Boolean, nullable=False)
    checked_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
