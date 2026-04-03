from datetime import date
from typing import List, Optional

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str


class UniversityCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=500)


class UniversityCreateResponse(BaseModel):
    university_id: int
    name: str
    api_key: str


class DiplomaCreateRequest(BaseModel):
    student_name: str = Field(min_length=1, max_length=500)
    student_dob: date
    degree: str = Field(min_length=1, max_length=500)
    specialization: str = Field(min_length=1, max_length=500)
    issue_date: date
    diploma_number: str = Field(min_length=1, max_length=200)


class DiplomaCreateResponse(BaseModel):
    diploma_id: int
    qr_token: str
    qr_code_base64: str


class DiplomaListItem(BaseModel):
    id: int
    student_name: str
    student_dob: date
    degree: str
    specialization: str
    issue_date: date
    diploma_number: str

    is_active: bool
    qr_token: Optional[str] = None


class DiplomaListResponse(BaseModel):
    diplomas: List[DiplomaListItem]


class DiplomaRevokeResponse(BaseModel):
    revoked: bool


class VerifyResponse(BaseModel):
    valid: bool
    student_name: Optional[str] = None
    degree: Optional[str] = None
    specialization: Optional[str] = None
    issue_date: Optional[date] = None
    university_name: Optional[str] = None


class ManualVerifyRequest(BaseModel):
    diploma_number: str = Field(min_length=1, max_length=200)
    student_name: str = Field(min_length=1, max_length=500)
    issue_date: date

