import hashlib
import os
from datetime import date
from typing import Generator

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://hack:hack@localhost:5432/diplomadb",
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def compute_data_hash(
    diploma_number: str,
    full_name: str,
    issue_date: date | str,
    secret_salt: str,
) -> str:
    """SHA-256(diploma_number|full_name|issue_date|SECRET_SALT)."""
    if hasattr(issue_date, "isoformat"):
        id_str = issue_date.isoformat()
    else:
        id_str = str(issue_date)
    raw = f"{diploma_number}|{full_name}|{id_str}|{secret_salt}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()
