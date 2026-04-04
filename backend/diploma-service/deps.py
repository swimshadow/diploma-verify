import os

import httpx
from fastapi import Header, HTTPException, status
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
