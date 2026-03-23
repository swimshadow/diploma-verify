from datetime import date
from typing import Any, Optional

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class VerifyPublicResponse(BaseModel):
    valid: bool
    full_name: Optional[str] = None
    degree: Optional[str] = None
    specialization: Optional[str] = None
    issue_date: Optional[date] = None
    university_name: Optional[str] = None
    signature_verified: bool = False
    blockchain_verified: bool = False
    blockchain_block: Optional[int] = None
    chain_intact: bool = False
    timestamp_proof: Optional[str] = None
    reason: Optional[str] = None


class ManualVerifyRequest(BaseModel):
    diploma_number: str
    series: str = ""
    full_name: str
    issue_date: date
