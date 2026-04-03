import base64
import secrets
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from loguru import logger
from sqlalchemy.orm import Session

from database import get_db
from internal_deps import internal_only
from models import Account, ECPKey, RefreshToken
from redis_client import get_redis
from security import (
    create_access_token,
    create_refresh_token_string,
    hash_refresh_token,
    refresh_token_expires_at,
)
from utils.ecp_utils import (
    calculate_fingerprint,
    parse_public_key,
    verify_signature,
)


router = APIRouter(
    prefix="/ecp",
    tags=["ecp"],
)


class ChallengeRequest:
    def __init__(self, email: str):
        self.email = email


class ECPKeyRegisterRequest:
    def __init__(self, public_key_pem: str, key_name: str, algorithm: str = "RS256"):
        self.public_key_pem = public_key_pem
        self.key_name = key_name
        self.algorithm = algorithm


class ECPVerifyRequest:
    def __init__(
        self,
        email: str,
        challenge: str,
        signature: str,
        key_fingerprint: Optional[str] = None,
    ):
        self.email = email
        self.challenge = challenge
        self.signature = signature
        self.key_fingerprint = key_fingerprint


async def check_ecp_rate_limit(email: str, client_ip: str):
    """Check rate limits for ECP challenge requests"""
    redis = get_redis()
    
    # Per IP: max 5 requests per minute
    ip_key = f"ecp_rate:{client_ip}"
    ip_count = redis.incr(ip_key)
    if ip_count == 1:
        redis.expire(ip_key, 60)
    if ip_count > 5:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many challenge requests from this IP",
        )

    # Per email: max 3 challenges per 5 minutes
    email_key = f"ecp_attempts:{email}"
    email_count = redis.incr(email_key)
    if email_count == 1:
        redis.expire(email_key, 300)
    if email_count > 3:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many challenge attempts for this account",
        )


@router.post("/keys")
async def register_ecp_key(
    request: dict,
    db: Session = Depends(get_db),
    current_user_id: uuid.UUID = Depends(internal_only),
):
    """Register a public ECP key for the current user"""
    
    public_key_pem = request.get("public_key_pem")
    key_name = request.get("key_name")
    algorithm = request.get("algorithm", "RS256")

    if not public_key_pem or not key_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="public_key_pem and key_name are required",
        )

    if algorithm not in ("RS256", "ES256"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="algorithm must be RS256 or ES256",
        )

    # Verify user is university or employer
    account = db.query(Account).filter(Account.id == current_user_id).first()
    if not account or account.role not in ("university", "employer"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only universities and employers can register ECP keys",
        )

    try:
        # Parse and validate public key
        parse_public_key(public_key_pem, algorithm)
        fingerprint = calculate_fingerprint(public_key_pem)
    except Exception as e:
        logger.warning(f"Invalid public key: {e}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid public key: {str(e)}",
        )

    # Check if fingerprint already exists
    existing_key = db.query(ECPKey).filter(
        ECPKey.fingerprint == fingerprint
    ).first()
    if existing_key:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This public key is already registered",
        )

    # Create new ECP key record
    ecp_key = ECPKey(
        account_id=current_user_id,
        key_name=key_name,
        public_key_pem=public_key_pem,
        algorithm=algorithm,
        fingerprint=fingerprint,
        is_active=True,
    )

    db.add(ecp_key)
    db.commit()
    db.refresh(ecp_key)

    logger.info(f"ECP key registered: account_id={current_user_id}, fingerprint={fingerprint}")

    return {
        "key_id": str(ecp_key.id),
        "fingerprint": fingerprint,
        "algorithm": algorithm,
        "created_at": ecp_key.created_at.isoformat() if ecp_key.created_at else None,
    }


@router.get("/keys")
async def list_ecp_keys(
    db: Session = Depends(get_db),
    current_user_id: uuid.UUID = Depends(internal_only),
):
    """List all ECP keys for the current user"""
    
    account = db.query(Account).filter(Account.id == current_user_id).first()
    if not account or account.role not in ("university", "employer"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only universities and employers can manage ECP keys",
        )

    ecp_keys = (
        db.query(ECPKey)
        .filter(ECPKey.account_id == current_user_id)
        .order_by(ECPKey.created_at.desc())
        .all()
    )

    return [
        {
            "key_id": str(key.id),
            "key_name": key.key_name,
            "fingerprint": key.fingerprint,
            "algorithm": key.algorithm,
            "is_active": key.is_active,
            "created_at": key.created_at.isoformat() if key.created_at else None,
            "last_used_at": key.last_used_at.isoformat() if key.last_used_at else None,
        }
        for key in ecp_keys
    ]


@router.delete("/keys/{key_id}")
async def deactivate_ecp_key(
    key_id: str,
    db: Session = Depends(get_db),
    current_user_id: uuid.UUID = Depends(internal_only),
):
    """Deactivate an ECP key"""
    
    try:
        key_uuid = uuid.UUID(key_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid key_id format",
        )

    ecp_key = db.query(ECPKey).filter(
        ECPKey.id == key_uuid,
        ECPKey.account_id == current_user_id,
    ).first()

    if not ecp_key:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ECP key not found",
        )

    ecp_key.is_active = False
    db.commit()

    logger.info(f"ECP key deactivated: key_id={key_id}")

    return {"status": "deactivated"}


@router.post("/challenge", status_code=status.HTTP_200_OK)
async def get_ecp_challenge(
    request: dict,
    db: Session = Depends(get_db),
    http_request: Request = None,
):
    """Get a challenge for ECP signing"""
    
    email = request.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="email is required",
        )

    # Rate limiting
    client_ip = (
        http_request.client.host
        if http_request and http_request.client
        else "unknown"
    )
    await check_ecp_rate_limit(email, client_ip)

    # Verify account exists and is university or employer
    account = db.query(Account).filter(Account.email == email).first()
    if not account:
        # Don't reveal if account exists
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or not eligible for ECP",
        )

    if account.role not in ("university", "employer"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="ECP login is only available for universities and employers",
        )

    if account.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is blocked",
        )

    # Check if account has any active ECP keys
    active_keys = (
        db.query(ECPKey)
        .filter(
            ECPKey.account_id == account.id,
            ECPKey.is_active == True,
        )
        .first()
    )

    if not active_keys:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No active ECP keys registered",
        )

    # Generate challenge
    challenge = secrets.token_hex(32)  # 64 character hex string
    challenge_key = f"ecp_challenge:{email}"

    # Store in Redis with 5 minute TTL
    redis = get_redis()
    redis.setex(challenge_key, 300, challenge)

    logger.info(f"ECP challenge generated for: {email}")

    return {
        "challenge": challenge,
        "expires_in": 300,
    }


@router.post("/verify", status_code=status.HTTP_200_OK)
async def verify_ecp_signature(
    request: dict,
    db: Session = Depends(get_db),
):
    """Verify ECP signature and issue tokens"""
    
    email = request.get("email")
    challenge = request.get("challenge")
    signature_b64 = request.get("signature")
    key_fingerprint = request.get("key_fingerprint")

    if not email or not challenge or not signature_b64:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="email, challenge, and signature are required",
        )

    # Retrieve stored challenge from Redis
    challenge_key = f"ecp_challenge:{email}"
    redis = get_redis()
    stored_challenge = redis.get(challenge_key)

    if not stored_challenge:
        logger.warning(f"ECP verification failed: expired or missing challenge for {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired challenge",
        )

    # Compare challenges
    if stored_challenge != challenge:
        logger.warning(f"ECP verification failed: challenge mismatch for {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid challenge",
        )

    # Delete challenge (one-time use)
    redis.delete(challenge_key)

    # Get account
    account = db.query(Account).filter(Account.email == email).first()
    if not account or account.role not in ("university", "employer"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid account",
        )

    if account.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is blocked",
        )

    # Get active ECP keys
    ecp_keys = (
        db.query(ECPKey)
        .filter(
            ECPKey.account_id == account.id,
            ECPKey.is_active == True,
        )
        .all()
    )

    if not ecp_keys:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No active ECP keys registered",
        )

    # Decode signature
    try:
        signature = base64.b64decode(signature_b64)
    except Exception as e:
        logger.warning(f"ECP verification failed: invalid signature encoding: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature encoding",
        )

    # Try to verify with each active key
    verified_key = None
    last_error = None

    for key in ecp_keys:
        # If fingerprint was specified, only try that key
        if key_fingerprint and key.fingerprint != key_fingerprint:
            continue

        try:
            verify_signature(
                challenge,
                signature,
                key.public_key_pem,
                key.algorithm,
            )
            verified_key = key
            break
        except Exception as e:
            last_error = str(e)
            continue

    if not verified_key:
        logger.warning(f"ECP verification failed: invalid signature for {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature",
        )

    # Update last_used_at
    verified_key.last_used_at = datetime.utcnow()

    # Get profile_id based on role
    profile_id: uuid.UUID | None = None
    if account.role == "university":
        university = db.query(Account.id).from_statement(
            "SELECT university_profiles.id FROM university_profiles WHERE account_id = :account_id"
        ).first()
        if account.university_profile:
            profile_id = account.university_profile.id
    elif account.role == "employer":
        if account.employer_profile:
            profile_id = account.employer_profile.id

    if not profile_id:
        logger.warning(f"ECP verification failed: no profile found for {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User profile not found",
        )

    db.commit()

    # Generate tokens
    access_token = create_access_token(account.id, account.role, profile_id)
    refresh_plain = create_refresh_token_string()
    
    db.add(
        RefreshToken(
            account_id=account.id,
            token_hash=hash_refresh_token(refresh_plain),
            expires_at=refresh_token_expires_at(),
            is_revoked=False,
        )
    )
    db.commit()

    logger.info(f"ECP login successful: email={email}, key_fingerprint={verified_key.fingerprint}")

    return {
        "access_token": access_token,
        "refresh_token": refresh_plain,
        "role": account.role,
        "auth_method": "ecp",
        "key_fingerprint": verified_key.fingerprint,
    }
