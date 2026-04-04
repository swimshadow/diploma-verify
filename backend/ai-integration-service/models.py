from sqlalchemy import Boolean, Column, Date, DateTime, Float, Integer, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Diploma(Base):
    """Read-only mirror — таблица создаётся university-service, AI читает напрямую."""
    __tablename__ = "diplomas"

    id = Column(UUID(as_uuid=True), primary_key=True)
    university_account_id = Column(UUID(as_uuid=True), nullable=False)
    file_id = Column(UUID(as_uuid=True), nullable=True)
    status = Column(String(32), nullable=False)
    full_name = Column(Text, nullable=True)
    full_name_encrypted = Column(Text, nullable=True)
    full_name_hash = Column(String(64), nullable=True)
    diploma_number = Column(Text, nullable=False)
    series = Column(Text, nullable=True)
    degree = Column(Text, nullable=False)
    specialization = Column(Text, nullable=False)
    issue_date = Column(Date, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    university_name = Column(Text, nullable=False)
    data_hash = Column(String(64), nullable=False)
    digital_signature = Column(Text, nullable=True)
    signed_at = Column(DateTime(timezone=True), nullable=True)
    timestamp_hash = Column(Text, nullable=True)
    student_account_id = Column(UUID(as_uuid=True), nullable=True)
    ai_extracted_data = Column(JSONB, nullable=True)
    ai_confidence = Column(Float, nullable=True)
    blockchain_block_index = Column(Integer, nullable=True)
    moderator_note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()"))


class MlProcessingLog(Base):
    __tablename__ = "ml_processing_log"

    id = Column(Integer, primary_key=True, autoincrement=True)
    diploma_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    confidence = Column(Float, nullable=True)
    processing_time_ms = Column(Integer, nullable=True)
    auto_verified = Column(Boolean, nullable=False, default=False)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
