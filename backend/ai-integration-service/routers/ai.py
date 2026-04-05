import os
import uuid
import time

import httpx
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from loguru import logger
from sqlalchemy.orm import Session

from database import get_db
from http_client import AI_FILE_FETCH_TIMEOUT, HTTP_TIMEOUT
from models import Diploma, MlProcessingLog
from schemas import AiResultRequest, AiResultResponse, ExtractRequest, ExtractResponse

router = APIRouter(prefix="/ai", tags=["ai"])

FILE_SERVICE_URL = os.getenv("FILE_SERVICE_URL", "http://file-service:8005")
UNIVERSITY_SERVICE_URL = os.getenv("UNIVERSITY_SERVICE_URL", "http://university-service:8002")
ML_EXTRACT_URL = os.getenv("ML_EXTRACT_URL", "http://ml-extract-service:3000")
ML_CLASSIFIER_URL = os.getenv("ML_CLASSIFIER_URL", "http://ml-classifier-service:3001")


async def run_extract_pipeline(file_id: str, diploma_id: str) -> None:
    """Extract diploma data using ML-сервис"""
    file_url = f"{FILE_SERVICE_URL.rstrip('/')}/files/{file_id}"
    
    try:
        # Получаем файл из file-service
        async with httpx.AsyncClient(timeout=AI_FILE_FETCH_TIMEOUT) as client:
            resp = await client.get(file_url)
        
        if resp.status_code != 200:
            logger.warning(f"File fetch failed {resp.status_code} for {file_id}")
            return
        
        file_bytes = resp.content
        file_name = resp.headers.get("content-disposition", "diploma.pdf")
        
        # Вызываем ML Extract Service
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            files = {"file": (file_name, file_bytes)}
            ml_resp = await client.post(f"{ML_EXTRACT_URL}/ml/extract-diploma", files=files)
        
        if ml_resp.status_code != 200:
            logger.warning(f"ML Extract failed {ml_resp.status_code} for {diploma_id}")
            return
        
        ml_result = ml_resp.json()
        extracted_data = ml_result.get("data", {})
        raw_text = extracted_data.get("raw_text", "")
        
        # Классифицируем диплом
        classification_result = {"is_authentic": True, "confidence": 0.9, "details": {}}
        try:
            async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
                files = {"file": (file_name, file_bytes)}
                classifier_resp = await client.post(f"{ML_CLASSIFIER_URL}/ml/classify-diploma", files=files)
            
            if classifier_resp.status_code == 200:
                classification_result = classifier_resp.json()
            else:
                logger.warning(f"ML Classifier failed {classifier_resp.status_code} for {diploma_id}")
        except Exception as e:
            logger.warning(f"Classifier error: {e}, using default confidence")
        
        # Подготавливаем данные для сохранения
        ai_extracted_data = {
            "full_name": extracted_data.get("student_name"),
            "diploma_number": extracted_data.get("diploma_number"),
            "degree": extracted_data.get("degree"),
            "specialization": extracted_data.get("specialty"),
            "graduation_year": extracted_data.get("graduation_year"),
            "university_name": extracted_data.get("university"),
            "raw_text": raw_text,
            "is_authentic": classification_result.get("is_authentic", True),
        }
        
        confidence = float(classification_result.get("confidence", 0.9))
        
        # Сохраняем в БД
        from database import SessionLocal
        db = SessionLocal()
        try:
            diploma = db.query(Diploma).filter(Diploma.id == uuid.UUID(diploma_id)).first()
            if diploma:
                diploma.ai_extracted_data = ai_extracted_data
                diploma.ai_confidence = confidence
                if confidence > 0.85 and diploma.status == "pending":
                    diploma.status = "verified"
                db.commit()
                logger.info(f"AI data saved for diploma {diploma_id}, confidence={confidence}, authentic={classification_result.get('is_authentic')}")
            else:
                logger.warning(f"Diploma {diploma_id} not found in DB")
        except Exception as e:
            db.rollback()
            logger.exception(f"Direct DB update failed: {e}")
        finally:
            db.close()
    
    except httpx.RequestError as e:
        logger.warning(f"File fetch error: {e}")


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

    # Прямой доступ к таблице diplomas (единая БД)
    diploma = db.query(Diploma).filter(Diploma.id == did).first()
    if not diploma:
        raise HTTPException(status_code=404, detail="Diploma not found")

    diploma.ai_extracted_data = merged_extracted
    diploma.ai_confidence = payload.confidence
    next_status = diploma.status
    if payload.confidence > 0.85 and diploma.status == "pending":
        diploma.status = "verified"
        next_status = "verified"

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


@router.post("/classify", response_model=AiResultResponse)
async def classify_diploma(payload: ExtractRequest, db: Session = Depends(get_db)):
    """Classify diploma authenticity using ML service"""
    try:
        did = uuid.UUID(payload.diploma_id)
    except ValueError:
        raise HTTPException(status_code=422, detail="Invalid diploma_id")
    
    # Получаем файл
    file_url = f"{FILE_SERVICE_URL.rstrip('/')}/files/{payload.file_id}"
    try:
        async with httpx.AsyncClient(timeout=AI_FILE_FETCH_TIMEOUT) as client:
            resp = await client.get(file_url)
        
        if resp.status_code != 200:
            raise HTTPException(status_code=503, detail="Could not fetch file")
        
        file_bytes = resp.content
        file_name = resp.headers.get("content-disposition", "diploma.pdf")
        
        # Вызываем классификатор
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            files = {"file": (file_name, file_bytes)}
            classifier_resp = await client.post(f"{ML_CLASSIFIER_URL}/ml/classify-diploma", files=files)
        
        if classifier_resp.status_code != 200:
            raise HTTPException(status_code=503, detail="Classification service error")
        
        classifier_result = classifier_resp.json()
        
        # Обновляем диплом в БД
        diploma = db.query(Diploma).filter(Diploma.id == did).first()
        if not diploma:
            raise HTTPException(status_code=404, detail="Diploma not found")
        
        confidence = float(classifier_result.get("confidence", 0.5))
        is_authentic = classifier_result.get("is_authentic", False)
        
        # Сохраняем результаты классификации
        if "ai_extracted_data" not in diploma.ai_extracted_data or not diploma.ai_extracted_data:
            diploma.ai_extracted_data = {}
        
        diploma.ai_extracted_data["is_authentic"] = is_authentic
        diploma.ai_confidence = confidence
        
        # Автоматически верифицируем если высокая уверенность
        next_status = diploma.status
        if confidence > 0.85 and is_authentic and diploma.status == "pending":
            diploma.status = "verified"
            next_status = "verified"
        elif not is_authentic and diploma.status == "pending":
            diploma.status = "rejected"
            next_status = "rejected"
        
        # Логируем обработку
        auto_verified = confidence > 0.85 and is_authentic and next_status == "verified"
        row = MlProcessingLog(
            diploma_id=did,
            confidence=confidence,
            processing_time_ms=0,
            auto_verified=auto_verified,
        )
        db.add(row)
        db.commit()
        
        logger.info(f"Diploma {did} classified: authentic={is_authentic}, confidence={confidence}")
        
        return AiResultResponse(
            received=True,
            diploma_id=str(did),
            next_status=next_status,
        )
    
    except httpx.RequestError as e:
        logger.warning(f"Request error: {e}")
        raise HTTPException(status_code=503, detail="Service unavailable")
