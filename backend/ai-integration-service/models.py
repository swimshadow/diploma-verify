from sqlalchemy import Boolean, Column, DateTime, Float, Integer, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


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
