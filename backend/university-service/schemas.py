from datetime import date
from typing import Any, List, Optional

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    service: str


class DiplomaMetadata(BaseModel):
    full_name: str
    diploma_number: str
    series: str = ""
    degree: str
    specialization: str
    issue_date: date
    date_of_birth: Optional[date] = None


class UploadDiplomaResponse(BaseModel):
    diploma_id: str
    status: str


class DiplomaListItem(BaseModel):
    id: str
    full_name: str
    diploma_number: str
    series: Optional[str]
    degree: str
    specialization: str
    issue_date: date
    status: str
    file_id: Optional[str]
    student_account_id: Optional[str]


class DiplomaListResponse(BaseModel):
    diplomas: List[DiplomaListItem]


class AiDataPatch(BaseModel):
    ai_extracted_data: dict[str, Any]
    confidence: float


class LinkStudentBody(BaseModel):
    student_account_id: str


class InternalDiplomaResponse(BaseModel):
    id: str
    full_name: str
    diploma_number: str
    degree: str
    specialization: str
    issue_date: date
    university_name: str
    data_hash: str
    status: str
    student_account_id: Optional[str] = None
    series: Optional[str] = None


class SearchDiplomaItem(BaseModel):
    id: str
    full_name: str
    diploma_number: str
    issue_date: date
    status: str
    student_account_id: Optional[str] = None


class SearchDiplomaResponse(BaseModel):
    diplomas: List[SearchDiplomaItem]
