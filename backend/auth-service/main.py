import os
import sys

from fastapi import FastAPI, Request
from loguru import logger
from sqlalchemy import text

from database import engine
from models import Base
from security import get_jwt_secret
from routers.auth import router as auth_router
from routers.health import router as health_router
from routers.internal import router as internal_router
from routers.ecp import router as ecp_router

SERVICE_NAME = os.getenv("SERVICE_NAME", "auth-service")

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
    title="Auth Service",
    description="Регистрация, JWT, профили, refresh-токены",
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
app.include_router(auth_router)
app.include_router(internal_router)
app.include_router(ecp_router)


@app.on_event("startup")
def create_tables():
    get_jwt_secret()
    Base.metadata.create_all(bind=engine)
    with engine.connect() as conn:
        conn.execute(
            text(
                "ALTER TABLE accounts ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN NOT NULL DEFAULT FALSE"
            )
        )
        conn.execute(text("ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_role_check"))
        conn.execute(
            text(
                "ALTER TABLE accounts ADD CONSTRAINT accounts_role_check "
                "CHECK (role IN ('university','student','employer','admin'))"
            )
        )
        conn.commit()
    logger.info("Auth service tables ready")
