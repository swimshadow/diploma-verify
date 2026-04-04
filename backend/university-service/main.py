import os
import sys

from fastapi import FastAPI, Request
from loguru import logger
from sqlalchemy import text

from database import engine
from models import Base
from routers.health import router as health_router
from routers.universities import get_public_key, internal_router, router

SERVICE_NAME = os.getenv("SERVICE_NAME", "university-service")

logger.remove()
logger.add(
    sys.stdout,
    format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {name} | {message}",
    level="INFO",
)
try:
    logger.add(
        f"/logs/{SERVICE_NAME}.log",
        rotation="100 MB",
        retention="30 days",
        level="DEBUG",
    )
except OSError:
    pass

app = FastAPI(
    title="University Service",
    description="Управление дипломами ВУЗа",
    version="1.0.0",
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response


app.include_router(health_router)
app.include_router(router, prefix="/university")
app.include_router(internal_router, prefix="/internal")


@app.get("/university/public-key")
def university_public_key():
    return get_public_key()


@app.on_event("startup")
def create_tables():
    if not os.getenv("SECRET_SALT", "").strip():
        raise RuntimeError("SECRET_SALT environment variable is required")
    Base.metadata.create_all(bind=engine)
    with engine.connect() as conn:
        for stmt in (
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS digital_signature TEXT",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS signed_at TIMESTAMP WITH TIME ZONE",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS timestamp_hash TEXT",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS full_name_encrypted TEXT",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS full_name_hash VARCHAR(64)",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS blockchain_block_index INTEGER",
            "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS moderator_note TEXT",
        ):
            conn.execute(text(stmt))
        conn.execute(text("ALTER TABLE diplomas ALTER COLUMN full_name DROP NOT NULL"))
        conn.commit()
    logger.info("University service tables ready")
