import base64
import hashlib
import os
import uuid
from datetime import datetime, timedelta
from typing import Optional

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, utils
from cryptography.exceptions import InvalidSignature
from fastapi import APIRouter, Depends, Header, HTTPException, Query
from loguru import logger
from sqlalchemy.orm import Session

from database import get_auth_db, Account, UniversityProfile, StudentProfile, EmployerProfile, Diploma
from schemas import (
    AccountDetailResponse,
    AccountItem,
    AccountListResponse,
    AccountsStatsResponse,
    AdminSetupRequest,
    BlockResponse,
)

router = APIRouter(prefix="/admin", tags=["admin"])

AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8001")
ADMIN_SETUP_KEY = os.getenv("ADMIN_SETUP_KEY", "change_me_admin_setup_secret")


async def get_admin_user(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.get(
                f"{AUTH_SERVICE_URL}/internal/verify-token",
                params={"token": token}
            )
        if r.status_code != 200:
            raise HTTPException(401, "Unauthorized")
        user = r.json()
        if user.get("role") != "admin":
            raise HTTPException(403, "Admin access required")
        return user
    except httpx.RequestError:
        raise HTTPException(503, "Auth service unavailable")


def _get_profile(account_id: uuid.UUID, role: str, db: Session) -> dict:
    if role == "university":
        profile = db.query(UniversityProfile).filter(UniversityProfile.account_id == account_id).first()
        if profile:
            return {"name": profile.name, "inn": profile.inn, "ogrn": profile.ogrn}
    elif role == "student":
        profile = db.query(StudentProfile).filter(StudentProfile.account_id == account_id).first()
        if profile:
            return {"full_name": profile.full_name, "date_of_birth": profile.date_of_birth}
    elif role == "employer":
        profile = db.query(EmployerProfile).filter(EmployerProfile.account_id == account_id).first()
        if profile:
            return {"company_name": profile.company_name, "inn": profile.inn}
    return {}


@router.post("/setup", response_model=dict)
async def setup_admin(request: AdminSetupRequest, db: Session = Depends(get_auth_db)):
    if ADMIN_SETUP_KEY != request.secret_key:
        raise HTTPException(403, "Invalid setup key")

    existing_admin = db.query(Account).filter(Account.role == "admin").first()
    if existing_admin:
        raise HTTPException(409, "Admin already exists")

    # Create admin in auth-service (it will handle password hashing and account creation)
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.post(
                f"{AUTH_SERVICE_URL}/internal/create-admin",
                json={
                    "email": request.email,
                    "password": request.password
                }
            )
        if r.status_code not in (200, 201):
            logger.error(f"Failed to create admin in auth-service: {r.text}")
            raise HTTPException(500, "Failed to create admin")
        
        admin_data = r.json()
        new_admin_id = admin_data.get("account_id")
        
        # Add is_blocked column if needed
        return {"message": "Admin created successfully", "account_id": new_admin_id}
    except httpx.RequestError as e:
        logger.error(f"Auth service error: {e}")
        raise HTTPException(503, "Auth service unavailable")


@router.get("/accounts", response_model=AccountListResponse)
async def list_accounts(
    role: Optional[str] = Query(None),
    is_blocked: Optional[bool] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    query = db.query(Account)
    if role:
        query = query.filter(Account.role == role)
    if is_blocked is not None:
        query = query.filter(Account.is_blocked == is_blocked)

    total = query.count()
    accounts = query.offset((page - 1) * limit).limit(limit).all()

    items = []
    for acc in accounts:
        profile = _get_profile(acc.id, acc.role, db)
        items.append(AccountItem(
            id=acc.id,
            email=acc.email,
            role=acc.role,
            is_verified=acc.is_verified,
            is_blocked=acc.is_blocked,
            created_at=acc.created_at,
            profile=profile
        ))

    return AccountListResponse(accounts=items, total=total, page=page, limit=limit)


@router.get("/accounts/stats", response_model=AccountsStatsResponse)
async def accounts_stats(
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    total = db.query(Account).count()
    by_role = {}
    for role in ["university", "student", "employer"]:
        by_role[role] = db.query(Account).filter(Account.role == role).count()

    blocked = db.query(Account).filter(Account.is_blocked == True).count()

    today = datetime.utcnow().date()
    registered_today = db.query(Account).filter(Account.created_at >= today).count()

    week_ago = datetime.utcnow() - timedelta(days=7)
    registered_this_week = db.query(Account).filter(Account.created_at >= week_ago).count()

    return AccountsStatsResponse(
        total=total,
        by_role=by_role,
        blocked=blocked,
        registered_today=registered_today,
        registered_this_week=registered_this_week
    )


@router.get("/accounts/{account_id}", response_model=AccountDetailResponse)
async def get_account(
    account_id: uuid.UUID,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")

    profile = _get_profile(acc.id, acc.role, db)
    response = AccountDetailResponse(
        id=acc.id,
        email=acc.email,
        role=acc.role,
        is_verified=acc.is_verified,
        is_blocked=acc.is_blocked,
        created_at=acc.created_at,
        profile=profile
    )

    if acc.role == "student":
        diplomas = db.query(Diploma).filter(Diploma.student_account_id == acc.id).all()
        response.diplomas = [
            {
                "id": str(d.id),
                "diploma_number": d.diploma_number,
                "status": d.status,
                "issue_date": d.issue_date.isoformat()
            } for d in diplomas
        ]
    elif acc.role == "university":
        count = db.query(Diploma).filter(Diploma.university_account_id == acc.id).count()
        response.diploma_count = count

    return response


@router.post("/accounts/{account_id}/block", response_model=BlockResponse)
async def block_account(
    account_id: uuid.UUID,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")

    acc.is_blocked = True
    db.commit()

    return BlockResponse(
        account_id=acc.id,
        is_blocked=True,
        blocked_at=datetime.utcnow()
    )


@router.post("/accounts/{account_id}/unblock", response_model=BlockResponse)
async def unblock_account(
    account_id: uuid.UUID,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")

    acc.is_blocked = False
    db.commit()

    return BlockResponse(
        account_id=acc.id,
        is_blocked=False
    )


@router.post("/accounts/{account_id}/verify")
async def verify_account(
    account_id: uuid.UUID,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")
    acc.is_verified = True
    db.commit()
    return {"account_id": str(acc.id), "is_verified": True}


@router.post("/accounts/{account_id}/unverify")
async def unverify_account(
    account_id: uuid.UUID,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")
    acc.is_verified = False
    db.commit()
    return {"account_id": str(acc.id), "is_verified": False}


@router.post("/accounts/{account_id}/verify-ecp")
async def verify_account_ecp(
    account_id: uuid.UUID,
    body: dict,
    db: Session = Depends(get_auth_db),
    admin: dict = Depends(get_admin_user),
):
    """
    Подтверждение организации с электронной подписью (ЭП).
    Принимает payload, подпись (base64) и публичный ключ (PEM).
    Верифицирует подпись RSA-SHA256 и одобряет аккаунт.
    """
    payload = body.get("payload")
    signature_b64 = body.get("signature")
    public_key_pem = body.get("public_key_pem")

    if not payload or not signature_b64 or not public_key_pem:
        raise HTTPException(422, "payload, signature and public_key_pem are required")

    # Decode signature
    try:
        signature_bytes = base64.b64decode(signature_b64)
    except Exception:
        raise HTTPException(422, "Invalid base64 signature")

    # Parse public key
    try:
        public_key = serialization.load_pem_public_key(public_key_pem.encode())
    except Exception as e:
        raise HTTPException(422, f"Invalid public key: {e}")

    # Verify RSA-SHA256 signature
    try:
        public_key.verify(
            signature_bytes,
            payload.encode(),
            padding.PKCS1v15(),
            hashes.SHA256(),
        )
    except InvalidSignature:
        raise HTTPException(401, "Invalid digital signature")
    except Exception as e:
        logger.error(f"Signature verification error: {e}")
        raise HTTPException(422, f"Signature verification error: {e}")

    # Approve account
    acc = db.query(Account).filter(Account.id == account_id).first()
    if not acc:
        raise HTTPException(404, "Account not found")

    acc.is_verified = True
    db.commit()

    fingerprint = hashlib.sha256(public_key_pem.encode()).hexdigest()
    logger.info(
        f"Account {account_id} verified via ECP by admin {admin.get('account_id')}, "
        f"key fingerprint: {fingerprint}"
    )

    return {
        "account_id": str(acc.id),
        "is_verified": True,
        "ecp_verified": True,
        "key_fingerprint": fingerprint,
        "signed_payload": payload,
    }