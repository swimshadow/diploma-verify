from datetime import date
from typing import Any, Literal

from pydantic import BaseModel, EmailStr, Field


class HealthResponse(BaseModel):
    status: str
    service: str


class UniversityProfileIn(BaseModel):
    name: str
    inn: str
    ogrn: str


class StudentProfileIn(BaseModel):
    full_name: str
    date_of_birth: date


class EmployerProfileIn(BaseModel):
    company_name: str
    inn: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    role: Literal["university", "student", "employer"]
    profile: dict[str, Any]


class RegisterResponse(BaseModel):
    account_id: str
    access_token: str
    refresh_token: str
    role: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    role: str
    profile: dict[str, Any]


class RefreshRequest(BaseModel):
    refresh_token: str


class RefreshResponse(BaseModel):
    access_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class MeResponse(BaseModel):
    account_id: str
    email: str
    role: str
    profile: dict[str, Any]


class VerifyTokenResponse(BaseModel):
    account_id: str
    role: str
    profile_id: str
    is_verified: bool = False


class InternalProfileResponse(BaseModel):
    account_id: str
    role: str
    email: str
    profile: dict[str, Any]


class UpdateProfileRequest(BaseModel):
    profile: dict[str, Any]
