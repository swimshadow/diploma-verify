import os
from datetime import datetime
from typing import Generator
import uuid

from dotenv import load_dotenv
from sqlalchemy import Column, Date, DateTime, Integer, String, Text, Boolean, text, ForeignKey, Float
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy import create_engine

load_dotenv()

# Единая БД — все таблицы в diplomadb
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://hack:hack@localhost:5432/diplomadb",
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Алиасы для обратной совместимости
auth_engine = engine
university_engine = engine
verify_engine = engine
AuthSessionLocal = SessionLocal
UniversitySessionLocal = SessionLocal
VerifySessionLocal = SessionLocal

Base = declarative_base()


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Обратная совместимость
def get_auth_db() -> Generator:
    return get_db()


def get_university_db() -> Generator:
    return get_db()


def get_verify_db() -> Generator:
    return get_db()


# ===== AUTHDB models =====

class Account(Base):
    __tablename__ = "accounts"
    __table_args__ = {"schema": "public"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(320), unique=True, nullable=False)
    password_hash = Column(Text, nullable=False)
    role = Column(String(32), nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    is_blocked = Column(Boolean, default=False, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class UniversityProfile(Base):
    __tablename__ = "university_profiles"
    __table_args__ = {"schema": "public"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(UUID(as_uuid=True), ForeignKey("public.accounts.id"), nullable=False)
    name = Column(Text, nullable=False)
    inn = Column(String(32), nullable=False)
    ogrn = Column(String(32), nullable=False)
    api_key_hash = Column(Text, nullable=True)


class StudentProfile(Base):
    __tablename__ = "student_profiles"
    __table_args__ = {"schema": "public"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(UUID(as_uuid=True), ForeignKey("public.accounts.id"), nullable=False)
    full_name = Column(Text, nullable=False)
    date_of_birth = Column(Date, nullable=False)


class EmployerProfile(Base):
    __tablename__ = "employer_profiles"
    __table_args__ = {"schema": "public"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(UUID(as_uuid=True), ForeignKey("public.accounts.id"), nullable=False)
    company_name = Column(Text, nullable=False)
    inn = Column(String(32), nullable=False)


# ===== UNIVERSITYDB models =====

class Diploma(Base):
    __tablename__ = "diplomas"
    __table_args__ = {"schema": "public"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    university_account_id = Column(UUID(as_uuid=True), nullable=False)
    file_id = Column(UUID(as_uuid=True), nullable=True)
    status = Column(String(32), nullable=False)
    full_name = Column(Text, nullable=False)
    diploma_number = Column(Text, nullable=False)
    series = Column(Text, nullable=True)
    degree = Column(Text, nullable=False)
    specialization = Column(Text, nullable=False)
    issue_date = Column(Date, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    university_name = Column(Text, nullable=False)
    data_hash = Column(String(64), nullable=False)
    digital_signature = Column(Text, nullable=True)
    signed_at = Column(DateTime, nullable=True)
    timestamp_hash = Column(Text, nullable=True)
    signed_at = Column(DateTime, nullable=True)
    student_account_id = Column(UUID(as_uuid=True), nullable=True)
    ai_extracted_data = Column(JSONB, nullable=True)
    ai_confidence = Column(Float, nullable=True)
    moderator_note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ===== VERIFYDB models =====

class VerificationLog(Base):
    __tablename__ = "verification_log"
    __table_args__ = {"schema": "public"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    diploma_id = Column(UUID(as_uuid=True), nullable=True)
    checker_account_id = Column(UUID(as_uuid=True), nullable=True)
    check_method = Column(String(64), nullable=False)
    result = Column(Boolean, nullable=False)
    checked_at = Column(DateTime, default=datetime.utcnow)