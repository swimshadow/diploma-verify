from datetime import date, datetime
from typing import Any, List, Optional

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class StudentDiplomaItem(BaseModel):
    id: str
    full_name: str
    diploma_number: str
    series: Optional[str] = None
    degree: str
    specialization: str
    issue_date: date
    university_name: str
    status: str
    trust_score: float
    certificate_id: Optional[str] = None
    file_id: Optional[str] = None
    antifraud_score: float = 0.0
    antifraud_verdict: str = ""
    antifraud_warnings: List[str] = []
    ai_confidence: Optional[float] = None
    digital_signature: Optional[str] = None
    created_at: Optional[str] = None


class StudentDiplomaListResponse(BaseModel):
    diplomas: List[StudentDiplomaItem]
