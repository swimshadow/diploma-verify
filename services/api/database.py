import os
import hashlib
import secrets
from typing import Generator, Optional

import redis
from dotenv import load_dotenv
from loguru import logger
from passlib.context import CryptContext
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()


DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://user:password@postgres:5432/diplomas"
)
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
SECRET_SALT = os.getenv("SECRET_SALT", "change_me_random_string")


# passlib is required by the task; bcrypt is widely supported for demo purposes.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

_redis_client: Optional[redis.Redis] = None


def get_redis_client() -> redis.Redis:
    """
    Lazily creates and returns a Redis client.
    """
    global _redis_client
    if _redis_client is not None:
        return _redis_client
    try:
        _redis_client = redis.Redis.from_url(REDIS_URL)
        # Basic connectivity check (non-fatal for local start).
        _redis_client.ping()
        logger.info("Connected to Redis")
    except Exception as e:
        logger.exception(f"Failed to connect to Redis: {e}")
        raise
    return _redis_client


def get_db() -> Generator:
    """
    FastAPI dependency that yields a SQLAlchemy session.
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        logger.exception(f"DB session error: {e}")
        raise
    finally:
        try:
            db.close()
        except Exception as e:
            logger.exception(f"Failed to close DB session: {e}")


def generate_api_key() -> str:
    return secrets.token_urlsafe(32)


def hash_api_key(api_key: str) -> str:
    return pwd_context.hash(api_key)


def verify_api_key(api_key: str, api_key_hash: str) -> bool:
    try:
        return bool(pwd_context.verify(api_key, api_key_hash))
    except Exception:
        return False


def hash_diploma_data(
    diploma_number: str,
    student_name: str,
    issue_date,  # date or ISO string
) -> str:
    """
    data_hash = SHA-256(diploma_number + student_name + issue_date + secret_salt)
    """
    if issue_date is None:
        raise ValueError("issue_date is required")
    issue_date_iso = issue_date.isoformat() if hasattr(issue_date, "isoformat") else str(issue_date)

    raw = f"{diploma_number}{student_name}{issue_date_iso}{SECRET_SALT}".encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def authenticate_university(db, api_key: str):
    """
    Authenticates the university by verifying provided API key against stored hashes.
    """
    try:
        # local import to avoid circular deps
        from models import University

        if not api_key:
            return None

        universities = db.query(University).all()
        for uni in universities:
            if verify_api_key(api_key, uni.api_key_hash):
                return uni
        return None
    except Exception as e:
        logger.exception(f"Failed to authenticate university: {e}")
        return None

