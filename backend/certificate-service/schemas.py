from datetime import date
from typing import Any

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    service: str


class DiplomaData(BaseModel):
    full_name: str
    degree: str
    specialization: str
    issue_date: date
    university_name: str


class GenerateRequest(BaseModel):
    diploma_id: str
    diploma_data: DiplomaData


class GenerateResponse(BaseModel):
    certificate_id: str
    qr_token: str
    qr_code_base64: str


class CertificateOut(BaseModel):
    certificate_id: str
    certificate_number: str | None = None
    diploma_id: str
    qr_token: str
    qr_code_base64: str
    issued_at: str
    is_active: bool
