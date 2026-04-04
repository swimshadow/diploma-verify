import sys

from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from routers.health import router as health_router
from routers.internal import router as internal_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Notification Service",
    description="Уведомления (SMTP позже через .env)",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(internal_router)


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
