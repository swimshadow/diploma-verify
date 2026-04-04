import os
import sys

from fastapi import FastAPI, Request
from loguru import logger
from sqlalchemy import text

from database import auth_engine
from routers import accounts, audit, diplomas, logs

SERVICE_NAME = os.getenv("SERVICE_NAME", "admin-service")

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
    title="Admin Service",
    description="Панель администратора diploma-platform",
    version="1.0.0",
)

try:
    from payload_crypto import PayloadEncryptionMiddleware
    app.add_middleware(PayloadEncryptionMiddleware)
except Exception:
    pass


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response


app.include_router(accounts.router)
app.include_router(diplomas.router)
app.include_router(logs.router)
app.include_router(audit.router)


@app.on_event("startup")
async def startup():
    logger.info("Admin service starting...")
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
