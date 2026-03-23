import hashlib
import hmac
import os
import sys

from fastapi import FastAPI, Request, Response
from loguru import logger

from database import engine
from models import Base
from routers.health import router as health_router
from routers.verify import router as verify_router

logger.remove()
logger.add(sys.stdout, level="INFO")

SECRET_SALT = os.getenv("SECRET_SALT", "")

app = FastAPI(
    title="Verify Service",
    description="Публичная проверка дипломов по QR и вручную",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(verify_router)


@app.middleware("http")
async def add_hmac_signature(request: Request, call_next):
    response = await call_next(request)
    body = b""
    async for chunk in response.body_iterator:
        body += chunk
    signature = hmac.new(
        SECRET_SALT.encode(),
        body,
        hashlib.sha256,
    ).hexdigest()
    headers = dict(response.headers)
    headers["X-Response-Signature"] = signature
    return Response(
        content=body,
        headers=headers,
        status_code=response.status_code,
        media_type=response.media_type,
    )


@app.on_event("startup")
def create_tables():
    if not SECRET_SALT.strip():
        raise RuntimeError("SECRET_SALT environment variable is required")
    Base.metadata.create_all(bind=engine)
