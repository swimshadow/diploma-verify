import os
import sys

from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from routers.health import router as health_router
from routers.verify import router as verify_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Verify Service",
    description="Публичная проверка дипломов по QR и вручную",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(verify_router)


@app.on_event("startup")
def create_tables():
    if not os.getenv("SECRET_SALT", "").strip():
        raise RuntimeError("SECRET_SALT environment variable is required")
    Base.metadata.create_all(bind=engine)
