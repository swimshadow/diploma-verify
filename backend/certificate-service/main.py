import os
import sys

from fastapi import FastAPI, Request
from loguru import logger
from sqlalchemy import text

from database import engine
from models import Base
from routers.certificates import router as cert_router
from routers.health import router as health_router

SERVICE_NAME = os.getenv("SERVICE_NAME", "certificate-service")

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
    title="Certificate Service",
    description="QR-сертификаты для дипломов",
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
app.include_router(cert_router)


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
    with engine.connect() as conn:
        conn.execute(
            text(
                "ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_number VARCHAR(20)"
            )
        )
        conn.commit()
