import secrets

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from loguru import logger

from database import get_db, generate_api_key, hash_api_key
from models import University
from schemas import UniversityCreateRequest, UniversityCreateResponse


router = APIRouter(tags=["universities"])


@router.post("", response_model=UniversityCreateResponse, status_code=status.HTTP_201_CREATED)
def create_university(
    payload: UniversityCreateRequest,
    db: Session = Depends(get_db),
):
    """
    Creates a university and returns an API key (demo endpoint, no auth required).
    """
    try:
        api_key = generate_api_key()
        api_key_hash = hash_api_key(api_key)

        uni = University(name=payload.name, api_key_hash=api_key_hash)
        db.add(uni)
        db.commit()
        db.refresh(uni)

        return UniversityCreateResponse(
            university_id=int(uni.id),
            name=uni.name,
            api_key=api_key,
        )
    except IntegrityError as e:
        db.rollback()
        logger.exception(f"University create failed (IntegrityError): {e}")
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="University already exists")
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.exception(f"University create failed: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal server error")

