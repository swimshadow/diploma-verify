import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from database import engine
from models import Base
from routers.files import router as files_router
from routers.health import router as health_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="File Service",
    description="Загрузка и выдача файлов дипломов",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(files_router)


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
