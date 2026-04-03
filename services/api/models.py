from sqlalchemy import Boolean, BigInteger, Column, Date, ForeignKey, String, Text, TIMESTAMP, text
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()


class University(Base):
    __tablename__ = "universities"
    # SQLAlchemy 2.0+ is strict about type annotations for ORM mappings.
    # We don't use Mapped[] generics here, so we allow legacy annotations.
    __allow_unmapped__ = True

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(Text, nullable=False, unique=True)
    api_key_hash = Column(Text, nullable=False)

    diplomas = relationship("Diploma", back_populates="university")


class Diploma(Base):
    __tablename__ = "diplomas"
    __allow_unmapped__ = True

    id = Column(BigInteger, primary_key=True, index=True)
    university_id = Column(BigInteger, ForeignKey("universities.id", ondelete="CASCADE"), nullable=False, index=True)

    student_name = Column(Text, nullable=False)
    student_dob = Column(Date, nullable=False)
    degree = Column(Text, nullable=False)
    specialization = Column(Text, nullable=False)
    issue_date = Column(Date, nullable=False)
    diploma_number = Column(Text, nullable=False)

    # SHA-256(diploma_number + student_name + issue_date + secret_salt)
    data_hash = Column(String(64), nullable=False, unique=True)

    created_at = Column(
        TIMESTAMP(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )

    university = relationship("University", back_populates="diplomas")
    certificates = relationship("Certificate", back_populates="diploma")


class Certificate(Base):
    __tablename__ = "certificates"
    __allow_unmapped__ = True

    id = Column(BigInteger, primary_key=True, index=True)
    diploma_id = Column(BigInteger, ForeignKey("diplomas.id", ondelete="CASCADE"), nullable=False, index=True)

    qr_token = Column(PG_UUID(as_uuid=True), nullable=False, unique=True, index=True)
    created_at = Column(
        TIMESTAMP(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
    is_active = Column(Boolean, nullable=False, default=True)

    diploma: Diploma = relationship("Diploma", back_populates="certificates")

