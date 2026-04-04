import sys

from fastapi import FastAPI
from loguru import logger

from routers.ai import router as ai_router
from routers.health import router as health_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="AI Integration Service",
    description="Извлечение данных из сканов дипломов (прокси / заглушка)",
    version="1.0.0",
)

app.include_router(health_router)
app.include_router(ai_router)
