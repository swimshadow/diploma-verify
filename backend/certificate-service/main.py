import sys

from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from routers.certificates import router as cert_router
from routers.health import router as health_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Certificate Service",
    description="QR-сертификаты для дипломов",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(cert_router)


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
