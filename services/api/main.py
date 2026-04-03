import sys

from fastapi import FastAPI
from loguru import logger

from database import get_redis_client
from routers.diplomas import router as diplomas_router
from routers.universities import router as universities_router
from routers.verify import router as verify_router
from schemas import HealthResponse


def setup_logging() -> None:
    # Keep logs simple and visible in docker logs.
    logger.remove()
    logger.add(sys.stdout, level="INFO")


setup_logging()

app = FastAPI(title="Diploma Verification Platform")

app.include_router(universities_router, prefix="/api/universities")
app.include_router(diplomas_router, prefix="/api/diplomas")
app.include_router(verify_router, prefix="/api")


@app.get("/health", response_model=HealthResponse)
def health():
    try:
        return HealthResponse(status="ok")
    except Exception as e:
        logger.exception(f"Health check failed: {e}")
        return HealthResponse(status="error")


@app.on_event("startup")
def on_startup():
    try:
        # Pre-warm Redis connection (optional).
        get_redis_client()
        logger.info("Startup complete")
    except Exception as e:
        # Continue startup; verify endpoints will fallback to DB if Redis is down.
        logger.warning(f"Startup Redis connection failed: {e}")

