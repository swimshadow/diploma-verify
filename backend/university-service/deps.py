import os
from typing import Callable

import httpx
from fastapi import Depends, Header, HTTPException, status
from loguru import logger

from http_client import HTTP_TIMEOUT

AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8001")


async def get_current_user(
    authorization: str = Header(..., alias="Authorization"),
):
    token = authorization.replace("Bearer ", "").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized",
        )
    url = f"{AUTH_SERVICE_URL.rstrip('/')}/internal/verify-token"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.get(url, params={"token": token})
    except httpx.RequestError as e:
        logger.warning(f"Auth verify-token unreachable: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )
    if r.status_code != 200:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    return r.json()


def require_role(*roles: str) -> Callable:
    async def _dep(user: dict = Depends(get_current_user)) -> dict:
        if user.get("role") not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required role: {roles}, your role: {user.get('role')}",
            )
        return user

    return _dep


def require_verified_university() -> Callable:
    async def _dep(user: dict = Depends(require_role("university"))) -> dict:
        if not user.get("is_verified"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="University must be verified by admin to perform this action",
            )
        return user

    return _dep
