from datetime import date
from typing import List, Optional

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class StudentDiplomaItem(BaseModel):
    id: str
    full_name: str
    diploma_number: str
    issue_date: date
    status: str


class StudentDiplomaListResponse(BaseModel):
    diplomas: List[StudentDiplomaItem]
