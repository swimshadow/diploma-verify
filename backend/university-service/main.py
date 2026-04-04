import os
import sys

from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from routers.health import router as health_router
from routers.universities import internal_router, router

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


@app.on_event("startup")
def create_tables():
    if not os.getenv("SECRET_SALT", "").strip():
        raise RuntimeError("SECRET_SALT environment variable is required")
    Base.metadata.create_all(bind=engine)
