import os
import uuid

import httpx
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from loguru import logger
from sqlalchemy.orm import Session

from database import get_db
from http_client import AI_FILE_FETCH_TIMEOUT, HTTP_TIMEOUT
from models import MlProcessingLog
from schemas import AiResultRequest, AiResultResponse, ExtractRequest, ExtractResponse

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


@router.post("/result", response_model=AiResultResponse)
async def ai_result(
    payload: AiResultRequest,
    db: Session = Depends(get_db),
):
    try:
        did = uuid.UUID(payload.diploma_id)
    except ValueError:
        raise HTTPException(status_code=422, detail="Invalid diploma_id")

    merged_extracted = payload.extracted_data.model_dump()
    merged_extracted["raw_text"] = payload.raw_text

    patch_url = f"{UNIVERSITY_SERVICE_URL.rstrip('/')}/internal/diplomas/{did}/ai-data"
    next_status = "pending"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.patch(
                patch_url,
                json={
                    "ai_extracted_data": merged_extracted,
                    "confidence": payload.confidence,
                },
            )
        if r.status_code >= 400:
            logger.warning(f"PATCH ai-data failed: {r.status_code} {r.text}")
            raise HTTPException(status_code=502, detail="University service rejected AI data")
        body = r.json()
        next_status = str(body.get("status", "pending"))
    except httpx.RequestError as e:
        logger.exception(f"PATCH ai-data error: {e}")
        raise HTTPException(status_code=503, detail="University service unavailable")

    auto_verified = payload.confidence > 0.85 and next_status == "verified"
    row = MlProcessingLog(
        diploma_id=did,
        confidence=payload.confidence,
        processing_time_ms=payload.processing_time_ms,
        auto_verified=auto_verified,
    )
    db.add(row)
    db.commit()

    return AiResultResponse(
        received=True,
        diploma_id=str(did),
        next_status=next_status,
    )
