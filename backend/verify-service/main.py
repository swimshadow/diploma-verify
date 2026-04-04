import hashlib
import hmac
import os
import sys
import time

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from loguru import logger

from database import engine
from models import Base
from routers.health import router as health_router
from routers.verify import router as verify_router

SERVICE_NAME = os.getenv("SERVICE_NAME", "verify-service")

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

SECRET_SALT = os.getenv("SECRET_SALT", "")

app = FastAPI(
    title="Verify Service",
    description="Публичная проверка дипломов по QR и вручную",
    version="1.0.0",
)

try:
    from payload_crypto import PayloadEncryptionMiddleware
    app.add_middleware(PayloadEncryptionMiddleware)
except Exception:
    pass


@app.middleware("http")
async def request_timestamp_check(request: Request, call_next):
    timestamp_header = request.headers.get("X-Request-Timestamp")
    if request.method == "POST" and timestamp_header:
        try:
            request_time = int(timestamp_header)
        except ValueError:
            return JSONResponse(
                {"error": "Invalid X-Request-Timestamp"},
                status_code=400,
            )
        current_time = int(time.time())
        if abs(current_time - request_time) > 300:
            return JSONResponse(
                {"error": "Request timestamp too old"},
                status_code=400,
            )
    return await call_next(request)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response


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
    headers["X-Timestamp"] = str(int(time.time()))
    return Response(
        content=body,
        headers=headers,
        status_code=response.status_code,
        media_type=response.media_type,
    )


app.include_router(health_router)
app.include_router(verify_router)


@app.on_event("startup")
def create_tables():
    if not SECRET_SALT.strip():
        raise RuntimeError("SECRET_SALT environment variable is required")
    Base.metadata.create_all(bind=engine)
