import sys

from fastapi import FastAPI
from loguru import logger

from routers.employer import router as employer_router
from routers.health import router as health_router
from routers.student import router as student_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Diploma Service",
    description="Студенческий кабинет",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(student_router, prefix="/student")
app.include_router(employer_router)
