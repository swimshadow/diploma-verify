import os
import sys

from fastapi import FastAPI
from loguru import logger
from sqlalchemy import text

from database import auth_engine
from routers import accounts, diplomas, logs

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Admin Service",
    description="Панель администратора diploma-platform",
    version="1.0.0"
)

app.include_router(accounts.router)
app.include_router(diplomas.router)
app.include_router(logs.router)


@app.on_event("startup")
async def startup():
    logger.info("Admin service starting...")
    # Добавляем колонку is_blocked если её нет
    with auth_engine.connect() as conn:
        try:
            conn.execute(text("""
                ALTER TABLE accounts
                ADD COLUMN IF NOT EXISTS is_blocked
                BOOLEAN DEFAULT FALSE
            """))
            conn.commit()
        except Exception as e:
            logger.warning(f"Column may already exist: {e}")
    logger.info("Admin service started on port 8010")


@app.get("/health")
def health():
    return {"status": "ok", "service": "admin-service"}