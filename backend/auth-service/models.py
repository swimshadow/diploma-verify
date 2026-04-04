import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    Date,
    DateTime,
    ForeignKey,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()


class Account(Base):
    __tablename__ = "accounts"
    __table_args__ = (
        CheckConstraint(
            "role IN ('university','student','employer','admin')",
            name="accounts_role_check",
        ),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(320), nullable=False, unique=True, index=True)
    password_hash = Column(Text, nullable=False)
    role = Column(String(32), nullable=False)
    is_verified = Column(Boolean, nullable=False, default=False)
    is_blocked = Column(Boolean, nullable=False, default=False)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )

    university_profile = relationship(
        "UniversityProfile", back_populates="account", uselist=False
    )
    student_profile = relationship(
        "StudentProfile", back_populates="account", uselist=False
    )
    employer_profile = relationship(
        "EmployerProfile", back_populates="account", uselist=False
    )


class UniversityProfile(Base):
    __tablename__ = "university_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        UUID(as_uuid=True),
        ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    name = Column(Text, nullable=False)
    inn = Column(String(32), nullable=False)
    ogrn = Column(String(32), nullable=False)
    short_name = Column(Text, nullable=True)
    city = Column(Text, nullable=True)
    address = Column(Text, nullable=True)
    university_type = Column(Text, nullable=True)
    license_number = Column(Text, nullable=True)
    contact_email = Column(String(320), nullable=True)
    phone = Column(String(64), nullable=True)
    website = Column(Text, nullable=True)
    responsible_person = Column(Text, nullable=True)
    api_key_hash = Column(Text, nullable=True)

    account = relationship("Account", back_populates="university_profile")


class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        UUID(as_uuid=True),
        ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    full_name = Column(Text, nullable=False)
    date_of_birth = Column(Date, nullable=False)

    account = relationship("Account", back_populates="student_profile")


class EmployerProfile(Base):
    __tablename__ = "employer_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        UUID(as_uuid=True),
        ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    company_name = Column(Text, nullable=False)
    inn = Column(String(32), nullable=False)

    account = relationship("Account", back_populates="employer_profile")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        UUID(as_uuid=True),
        ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    token_hash = Column(String(128), nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, nullable=False, default=False)


class ECPKey(Base):
    __tablename__ = "ecp_keys"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        UUID(as_uuid=True),
        ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    key_name = Column(String(200), nullable=False)
    public_key_pem = Column(Text, nullable=False)
    algorithm = Column(String(20), nullable=False, default="RS256")
    fingerprint = Column(String(100), nullable=False, unique=True, index=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
