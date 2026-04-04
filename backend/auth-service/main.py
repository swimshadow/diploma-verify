import sys

from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from security import get_jwt_secret
from routers.auth import router as auth_router
from routers.health import router as health_router
from routers.internal import router as internal_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Auth Service",
    description="Регистрация, JWT, профили, refresh-токены",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(internal_router)


@app.on_event("startup")
def create_tables():
    get_jwt_secret()
    Base.metadata.create_all(bind=engine)
    logger.info("Auth service tables ready")
