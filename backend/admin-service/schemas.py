from datetime import date, datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class AdminSetupRequest(BaseModel):
    secret_key: str
    email: str
    password: str


class AccountProfile(BaseModel):
    name: Optional[str] = None
    inn: Optional[str] = None
    ogrn: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[date] = None
    company_name: Optional[str] = None


class AccountItem(BaseModel):
    id: UUID
    email: str
    role: str
    is_verified: bool
    is_blocked: bool
    created_at: datetime
    profile: AccountProfile


class AccountListResponse(BaseModel):
    accounts: List[AccountItem]
    total: int
    page: int
    limit: int


class AccountDetailResponse(BaseModel):
    id: UUID
    email: str
    role: str
    is_verified: bool
    is_blocked: bool
    created_at: datetime
    profile: AccountProfile
    diplomas: Optional[List[dict]] = None  # For students
    diploma_count: Optional[int] = None  # For universities


class BlockResponse(BaseModel):
    account_id: UUID
    is_blocked: bool
    blocked_at: Optional[datetime] = None


class AccountsStatsResponse(BaseModel):
    total: int
    by_role: dict
    blocked: int
    registered_today: int
    registered_this_week: int


class DiplomaItem(BaseModel):
    id: UUID
    diploma_number: str
    series: Optional[str]
    full_name: str
    degree: str
    specialization: str
    issue_date: date
    status: str
    created_at: datetime
    verified_at: Optional[datetime]
    university_name: str
    student_account_id: Optional[UUID]


class DiplomaListResponse(BaseModel):
    diplomas: List[DiplomaItem]
    total: int
    page: int
    limit: int


class DiplomaDetailResponse(BaseModel):
    id: UUID
    diploma_number: str
    series: Optional[str]
    full_name: str
    degree: str
    specialization: str
    issue_date: date
    status: str
    created_at: datetime
    verified_at: Optional[datetime]
    university_name: str
    student_account_id: Optional[UUID]
    ai_extracted_data: Optional[dict]


class DiplomasStatsResponse(BaseModel):
    total: int
    by_status: dict
    verified_today: int
    verified_this_week: int
    verified_this_month: int


class VerificationLogItem(BaseModel):
    id: int
    diploma_id: Optional[UUID]
    diploma_number: Optional[str]
    full_name: Optional[str]
    checker_account_id: Optional[UUID]
    checker_email: Optional[str]
    check_method: str
    result: bool
    checked_at: datetime


class VerificationLogsResponse(BaseModel):
    logs: List[VerificationLogItem]
    total: int
    page: int
    limit: int


class LogsStatsResponse(BaseModel):
    total_checks: int
    successful_checks: int
    failed_checks: int
    checks_today: int
    checks_this_week: int
    most_checked_diplomas: List[dict]
    checks_by_method: dict