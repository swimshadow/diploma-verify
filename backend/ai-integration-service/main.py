import os
import sys

from fastapi import FastAPI, Request
from loguru import logger

from database import engine
from models import Base
from routers.ai import router as ai_router
from routers.health import router as health_router

SERVICE_NAME = os.getenv("SERVICE_NAME", "ai-integration-service")

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
    title="AI Integration Service",
    description="Извлечение данных из сканов дипломов (прокси / заглушка)",
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
app.include_router(ai_router)


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
