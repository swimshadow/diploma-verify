import hashlib
import json
import os
from datetime import date
from typing import Generator, Optional

import redis
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://hack:hack@localhost:5432/verifydb",
)
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

_redis: redis.Redis | None = None


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_redis() -> redis.Redis:
    global _redis
    if _redis is None:
        _redis = redis.Redis.from_url(REDIS_URL, decode_responses=True)
    return _redis


def compute_data_hash(
    diploma_number: str,
    full_name: str,
    issue_date: date | str,
    secret_salt: str,
) -> str:
    if hasattr(issue_date, "isoformat"):
        id_str = issue_date.isoformat()
    else:
        id_str = str(issue_date)
    raw = f"{diploma_number}|{full_name}|{id_str}|{secret_salt}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def cache_get_json(key: str) -> Optional[dict]:
    r = get_redis()
    raw = r.get(key)
    if raw is None:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def cache_set_json(key: str, payload: dict, ttl: int) -> None:
    get_redis().setex(key, ttl, json.dumps(payload, default=str))
