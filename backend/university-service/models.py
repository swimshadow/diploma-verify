import uuid
from datetime import datetime

from sqlalchemy import Column, Date, DateTime, Float, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Diploma(Base):
    __tablename__ = "diplomas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    university_account_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    file_id = Column(UUID(as_uuid=True), nullable=True)
    status = Column(String(32), nullable=False, default="pending")
    full_name = Column(Text, nullable=False)
    diploma_number = Column(Text, nullable=False)
    series = Column(Text, nullable=True)
    degree = Column(Text, nullable=False)
    specialization = Column(Text, nullable=False)
    issue_date = Column(Date, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    university_name = Column(Text, nullable=False)
    data_hash = Column(String(64), nullable=False, index=True)
    student_account_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    ai_extracted_data = Column(JSONB, nullable=True)
    ai_confidence = Column(Float, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
