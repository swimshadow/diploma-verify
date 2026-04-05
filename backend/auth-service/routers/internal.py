import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session, joinedload

from database import get_db
from internal_deps import internal_only
from models import Account, StudentProfile
from schemas import InternalProfileResponse, VerifyTokenResponse
from security import decode_access_token, hash_password

router = APIRouter(
    prefix="/internal",
    tags=["internal"],
    dependencies=[Depends(internal_only)],
)


class CreateAdminRequest(BaseModel):
    email: str
    password: str


class CreateAdminResponse(BaseModel):
    account_id: str
    email: str


@router.get("/verify-token", response_model=VerifyTokenResponse)
async def verify_token(token: str, db: Session = Depends(get_db)):
    data = decode_access_token(token)
    if not data or data.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    try:
        account_id = uuid.UUID(data["sub"])
        profile_id = uuid.UUID(data["profile_id"])
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    account = (
        db.query(Account)
        .options(
            joinedload(Account.university_profile),
            joinedload(Account.student_profile),
            joinedload(Account.employer_profile),
        )
        .filter(Account.id == account_id)
        .first()
    )
    if account is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")

    if getattr(account, "is_blocked", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is blocked",
        )

    if account.role == "admin":
        if profile_id != account_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
        return VerifyTokenResponse(
            account_id=str(account_id),
            role=account.role,
            profile_id=str(profile_id),
            is_verified=True,
        )

    actual_pid: uuid.UUID | None = None
    if account.role == "university" and account.university_profile:
        actual_pid = account.university_profile.id
    elif account.role == "student" and account.student_profile:
        actual_pid = account.student_profile.id
    elif account.role == "employer" and account.employer_profile:
        actual_pid = account.employer_profile.id
    if actual_pid is None or actual_pid != profile_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    return VerifyTokenResponse(
        account_id=str(account_id),
        role=account.role,
        profile_id=str(profile_id),
        is_verified=getattr(account, 'is_verified', False),
    )


def _profile_dict(account: Account) -> dict:
    if account.role == "admin":
        return {}
    if account.role == "university" and account.university_profile:
        p = account.university_profile
        return {"name": p.name, "inn": p.inn, "ogrn": p.ogrn}
    if account.role == "student" and account.student_profile:
        p = account.student_profile
        return {
            "full_name": p.full_name,
            "date_of_birth": p.date_of_birth.isoformat(),
        }
    if account.role == "employer" and account.employer_profile:
        p = account.employer_profile
        return {"company_name": p.company_name, "inn": p.inn}
    return {}


@router.get("/profile/{account_id}", response_model=InternalProfileResponse)
async def profile_by_account(account_id: uuid.UUID, db: Session = Depends(get_db)):
    account = (
        db.query(Account)
        .options(
            joinedload(Account.university_profile),
            joinedload(Account.student_profile),
            joinedload(Account.employer_profile),
        )
        .filter(Account.id == account_id)
        .first()
    )
    if account is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return InternalProfileResponse(
        account_id=str(account.id),
        role=account.role,
        email=account.email,
        profile=_profile_dict(account),
    )


@router.post("/create-admin", response_model=CreateAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_admin(payload: CreateAdminRequest, db: Session = Depends(get_db)):
    """Create an admin account"""
    # Check if email already exists
    existing = db.query(Account).filter(Account.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    
    # Create admin account
    account = Account(
        email=payload.email,
        password_hash=hash_password(payload.password),
        role="admin",
        is_verified=True,
    )
    db.add(account)
    db.commit()
    db.refresh(account)
    
    return CreateAdminResponse(
        account_id=str(account.id),
        email=account.email,
    )


class RegisterStudentRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    date_of_birth: Optional[date] = None


class RegisterStudentResponse(BaseModel):
    account_id: str
    email: str


@router.post("/register-student", response_model=RegisterStudentResponse, status_code=status.HTTP_201_CREATED)
async def register_student(payload: RegisterStudentRequest, db: Session = Depends(get_db)):
    existing = db.query(Account).filter(Account.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    account = Account(
        email=payload.email,
        password_hash=hash_password(payload.password),
        role="student",
        is_verified=True,
        is_blocked=False,
    )
    db.add(account)
    db.flush()

    dob = payload.date_of_birth if payload.date_of_birth else date(2000, 1, 1)
    sp = StudentProfile(
        account_id=account.id,
        full_name=payload.full_name,
        date_of_birth=dob,
    )
    db.add(sp)
    db.commit()
    db.refresh(account)

    return RegisterStudentResponse(
        account_id=str(account.id),
        email=account.email,
    )
