import os
import sys

from fastapi import FastAPI
from loguru import logger
from sqlalchemy import text

from database import engine
from models import Base
from routers.health import router as health_router
from routers.universities import get_public_key, internal_router, router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="University Service",
    description="Управление дипломами ВУЗа",
    version="1.0.0",
)

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
        conn.execute(
            text(
                "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS digital_signature TEXT"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS signed_at TIMESTAMP WITH TIME ZONE"
            )
        )
        conn.execute(
            text(
                "ALTER TABLE diplomas ADD COLUMN IF NOT EXISTS timestamp_hash TEXT"
            )
        )
