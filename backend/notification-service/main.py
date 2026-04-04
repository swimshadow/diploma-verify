import os
import sys

from fastapi import FastAPI, Request
from loguru import logger
from sqlalchemy import text

from database import engine
from models import Base
from audit_models import AuditBase
from routers.health import router as health_router
from routers.internal import router as internal_router
from routers.notifications import router as notifications_router

SERVICE_NAME = os.getenv("SERVICE_NAME", "notification-service")

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
    title="Notification Service",
    description="Уведомления (SMTP позже через .env)",
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


app.include_router(health_router)
app.include_router(internal_router)
app.include_router(notifications_router)


@app.on_event("startup")
def create_tables():
    with engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS audit"))
        conn.commit()
    Base.metadata.create_all(bind=engine)
    AuditBase.metadata.create_all(bind=engine)
