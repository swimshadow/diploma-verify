import os

import httpx
from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from loguru import logger

from http_client import AI_FILE_FETCH_TIMEOUT, HTTP_TIMEOUT
from schemas import ExtractRequest, ExtractResponse

router = APIRouter(prefix="/ai", tags=["ai"])

FILE_SERVICE_URL = os.getenv("FILE_SERVICE_URL", "http://file-service:8005")
UNIVERSITY_SERVICE_URL = os.getenv("UNIVERSITY_SERVICE_URL", "http://university-service:8002")


async def run_extract_pipeline(file_id: str, diploma_id: str) -> None:
    file_url = f"{FILE_SERVICE_URL.rstrip('/')}/files/{file_id}"
    try:
        async with httpx.AsyncClient(timeout=AI_FILE_FETCH_TIMEOUT) as client:
            resp = await client.get(file_url)
        if resp.status_code != 200:
            logger.warning(f"File fetch failed {resp.status_code} for {file_id}")
    except httpx.RequestError as e:
        logger.warning(f"File fetch error: {e}")

    # Заглушка: интерфейс стабилен для замены на реальную нейросеть
    ai_extracted_data = {
        "full_name": "Иванов Иван Иванович",
        "diploma_number": "АА123456",
        "series": "АА",
        "degree": "Бакалавр",
        "specialization": "Информатика",
        "issue_date": "2024-06-15",
    }
    confidence = 0.95
    raw_text = "текст диплома"

    ai_extracted_data["raw_text"] = raw_text

    patch_url = (
        f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/{diploma_id}/ai-data"
    )
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.patch(
                patch_url,
                json={"ai_extracted_data": ai_extracted_data, "confidence": confidence},
            )
        if r.status_code >= 400:
            logger.warning(f"PATCH ai-data failed: {r.status_code} {r.text}")
    except httpx.RequestError as e:
        logger.exception(f"PATCH ai-data error: {e}")


@router.post("/extract", response_model=ExtractResponse)
async def extract(payload: ExtractRequest, background_tasks: BackgroundTasks):
    try:
        background_tasks.add_task(run_extract_pipeline, payload.file_id, payload.diploma_id)
    except Exception as e:
        logger.exception(f"Background task schedule failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to schedule processing",
        )
    return ExtractResponse(status="processing", diploma_id=payload.diploma_id)
