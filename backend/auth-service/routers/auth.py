import os
import uuid
from datetime import date, datetime, timezone

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Response, status
from loguru import logger
from pydantic import BaseModel, ValidationError
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from database import get_db
from models import (
    Account,
    EmployerProfile,
    RefreshToken,
    StudentProfile,
    UniversityProfile,
)
from redis_client import get_redis
from schemas import (
    EmployerProfileIn,
    LoginRequest,
    LoginResponse,
    LogoutRequest,
    MeResponse,
    RefreshRequest,
    RefreshResponse,
    RegisterRequest,
    RegisterResponse,
    StudentProfileIn,
    UniversityProfileIn,
)
from security import (
    REFRESH_TOKEN_EXPIRE_DAYS,
    create_access_token,
    create_refresh_token_string,
    decode_access_token,
    hash_password,
    hash_refresh_token,
    refresh_token_expires_at,
    verify_password,
)

NOTIFICATION_SERVICE_URL = os.getenv(
    "NOTIFICATION_SERVICE_URL", "http://notification-service:8008"
)
DEMO_MODE = os.getenv("DEMO_MODE", "false").lower() in ("1", "true", "yes")

router = APIRouter(prefix="/auth", tags=["auth"])


def _login_attempt_key(email: str) -> str:
    return f"login_attempts:{email.lower().strip()}"


def _check_login_attempts_allowed(email: str) -> None:
    r = get_redis()
    raw = r.get(_login_attempt_key(email))
    if raw is not None and int(raw) > 5:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many login attempts. Try again in 15 minutes.",
        )


def _record_failed_login(email: str) -> None:
    r = get_redis()
    key = _login_attempt_key(email)
    attempts = r.incr(key)
    if attempts == 1:
        r.expire(key, 900)
    if attempts > 5:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many login attempts. Try again in 15 minutes.",
        )


def _reset_login_attempts(email: str) -> None:
    try:
        get_redis().delete(_login_attempt_key(email))
    except Exception as e:
        logger.warning(f"Redis delete login_attempts failed: {e}")


def _profile_to_dict(account: Account) -> dict:
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


def _profile_id_for_account(account: Account) -> uuid.UUID:
    if account.role == "admin":
        return account.id
    if account.role == "university" and account.university_profile:
        return account.university_profile.id
    if account.role == "student" and account.student_profile:
        return account.student_profile.id
    if account.role == "employer" and account.employer_profile:
        return account.employer_profile.id
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Profile missing",
    )


async def _send_notification(
    account_id: uuid.UUID,
    notif_type: str,
    subject: str,
    body: str,
) -> None:
    url = f"{NOTIFICATION_SERVICE_URL.rstrip('/')}/internal/send"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            await client.post(
                url,
                json={
                    "account_id": str(account_id),
                    "type": notif_type,
                    "subject": subject,
                    "body": body,
                },
            )
    except Exception as e:
        logger.warning(f"Notification send failed: {e}")


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(Account).filter(Account.email == str(payload.email)).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    try:
        if payload.role == "university":
            UniversityProfileIn.model_validate(payload.profile)
        elif payload.role == "student":
            StudentProfileIn.model_validate(payload.profile)
        else:
            EmployerProfileIn.model_validate(payload.profile)
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=e.errors(),
        )

    account = Account(
        email=str(payload.email),
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_verified=False,
        is_blocked=False,
    )
    db.add(account)
    db.flush()

    profile_id: uuid.UUID
    if payload.role == "university":
        p = UniversityProfileIn.model_validate(payload.profile)
        up = UniversityProfile(
            account_id=account.id,
            name=p.name,
            inn=p.inn,
            ogrn=p.ogrn,
        )
        db.add(up)
        db.flush()
        profile_id = up.id
    elif payload.role == "student":
        p = StudentProfileIn.model_validate(payload.profile)
        sp = StudentProfile(
            account_id=account.id,
            full_name=p.full_name,
            date_of_birth=p.date_of_birth,
        )
        db.add(sp)
        db.flush()
        profile_id = sp.id
    else:
        p = EmployerProfileIn.model_validate(payload.profile)
        ep = EmployerProfile(
            account_id=account.id,
            company_name=p.company_name,
            inn=p.inn,
        )
        db.add(ep)
        db.flush()
        profile_id = ep.id
    access = create_access_token(account.id, account.role, profile_id)
    refresh_plain = create_refresh_token_string()
    db.add(
        RefreshToken(
            account_id=account.id,
            token_hash=hash_refresh_token(refresh_plain),
            expires_at=refresh_token_expires_at(),
            is_revoked=False,
        )
    )
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Registration conflict",
        )

    await _send_notification(
        account.id,
        "welcome",
        "Добро пожаловать",
        f"Регистрация завершена для {account.email}",
    )

    return RegisterResponse(
        account_id=str(account.id),
        access_token=access,
        refresh_token=refresh_plain,
        role=account.role,
    )


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest, db: Session = Depends(get_db)):
    email_key = str(payload.email)
    _check_login_attempts_allowed(email_key)
    account = (
        db.query(Account)
        .options(
            joinedload(Account.university_profile),
            joinedload(Account.student_profile),
            joinedload(Account.employer_profile),
        )
        .filter(Account.email == email_key)
        .first()
    )
    if account is None or not verify_password(payload.password, account.password_hash):
        _record_failed_login(email_key)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )
    if getattr(account, "is_blocked", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is blocked",
        )
    _reset_login_attempts(email_key)
    profile_id = _profile_id_for_account(account)
    access = create_access_token(account.id, account.role, profile_id)
    refresh_plain = create_refresh_token_string()
    db.add(
        RefreshToken(
            account_id=account.id,
            token_hash=hash_refresh_token(refresh_plain),
            expires_at=refresh_token_expires_at(),
            is_revoked=False,
        )
    )
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not issue session",
        )
    return LoginResponse(
        access_token=access,
        refresh_token=refresh_plain,
        role=account.role,
        profile=_profile_to_dict(account),
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_token(payload: RefreshRequest, db: Session = Depends(get_db)):
    th = hash_refresh_token(payload.refresh_token)
    try:
        revoked = get_redis().get(f"revoked_refresh:{th}")
    except Exception as e:
        logger.warning(f"Redis unavailable on refresh: {e}")
        revoked = None
    if revoked:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    row = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token_hash == th,
            RefreshToken.is_revoked.is_(False),
        )
        .first()
    )
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    exp = row.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    if exp < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Expired token")
    account = (
        db.query(Account)
        .options(
            joinedload(Account.university_profile),
            joinedload(Account.student_profile),
            joinedload(Account.employer_profile),
        )
        .filter(Account.id == row.account_id)
        .first()
    )
    if account is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    profile_id = _profile_id_for_account(account)
    access = create_access_token(account.id, account.role, profile_id)
    return RefreshResponse(access_token=access)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: LogoutRequest, db: Session = Depends(get_db)):
    th = hash_refresh_token(payload.refresh_token)
    row = db.query(RefreshToken).filter(RefreshToken.token_hash == th).first()
    if row:
        row.is_revoked = True
        db.commit()
    ttl = max(1, REFRESH_TOKEN_EXPIRE_DAYS * 86400)
    try:
        get_redis().setex(f"revoked_refresh:{th}", ttl, "1")
    except Exception as e:
        logger.warning(f"Redis setex on logout failed: {e}")
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=MeResponse)
async def me(
    authorization: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
):
    token = authorization.replace("Bearer ", "").strip()
    data = decode_access_token(token)
    if not data or data.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    try:
        aid = uuid.UUID(data["sub"])
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    account = (
        db.query(Account)
        .options(
            joinedload(Account.university_profile),
            joinedload(Account.student_profile),
            joinedload(Account.employer_profile),
        )
        .filter(Account.id == aid)
        .first()
    )
    if account is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    return MeResponse(
        account_id=str(account.id),
        email=account.email,
        role=account.role,
        profile=_profile_to_dict(account),
    )


class DemoSetupResponse(BaseModel):
    created: list[str]
    skipped: list[str]


def _ensure_demo_accounts(db: Session) -> tuple[list[str], list[str]]:
    """Idempotent demo users (DEMO_MODE). Password for all: Demo123"""
    demo_pw = "Demo123"
    specs: list[tuple[str, str, dict]] = [
        (
            "university@demo.ru",
            "university",
            {
                "name": "Демо ВУЗ",
                "inn": "7700000000",
                "ogrn": "1027700000000",
            },
        ),
        (
            "student@demo.ru",
            "student",
            {
                "full_name": "Студент Демо Демович",
                "date_of_birth": date(2000, 1, 15),
            },
        ),
        (
            "employer@demo.ru",
            "employer",
            {"company_name": "Демо работодатель", "inn": "7700000001"},
        ),
    ]
    created: list[str] = []
    skipped: list[str] = []
    for email, role, prof in specs:
        if db.query(Account).filter(Account.email == email).first():
            skipped.append(email)
            continue
        acc = Account(
            email=email,
            password_hash=hash_password(demo_pw),
            role=role,
            is_verified=True,
            is_blocked=False,
        )
        db.add(acc)
        db.flush()
        if role == "university":
            p = UniversityProfileIn.model_validate(prof)
            db.add(
                UniversityProfile(
                    account_id=acc.id,
                    name=p.name,
                    inn=p.inn,
                    ogrn=p.ogrn,
                )
            )
        elif role == "student":
            p = StudentProfileIn.model_validate(prof)
            db.add(
                StudentProfile(
                    account_id=acc.id,
                    full_name=p.full_name,
                    date_of_birth=p.date_of_birth,
                )
            )
        else:
            p = EmployerProfileIn.model_validate(prof)
            db.add(
                EmployerProfile(
                    account_id=acc.id,
                    company_name=p.company_name,
                    inn=p.inn,
                )
            )
        db.commit()
        created.append(email)

    admin_email = "admin@demo.ru"
    if db.query(Account).filter(Account.email == admin_email).first():
        skipped.append(admin_email)
    else:
        db.add(
            Account(
                email=admin_email,
                password_hash=hash_password(demo_pw),
                role="admin",
                is_verified=True,
                is_blocked=False,
            )
        )
        db.commit()
        created.append(admin_email)

    return created, skipped


@router.post("/setup-demo", response_model=DemoSetupResponse)
async def setup_demo(db: Session = Depends(get_db)):
    if not DEMO_MODE:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    created, skipped = _ensure_demo_accounts(db)
    return DemoSetupResponse(created=created, skipped=skipped)
