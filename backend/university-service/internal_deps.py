from fastapi import HTTPException, Request, status


def internal_only(request: Request) -> None:
    client_ip = request.client.host if request.client else ""
    allowed_prefixes = ("127.0.0.1", "::1", "172.", "10.", "192.168.")
    if not any(client_ip.startswith(p) for p in allowed_prefixes):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Internal endpoint only",
        )
