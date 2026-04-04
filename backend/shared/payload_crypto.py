"""
AES-256-GCM payload encryption middleware for FastAPI.

Mirrors the Flutter CryptoInterceptor:
- Requests with header ``X-Encrypted: 1`` carry JSON ``{"_enc": "<base64>"}``
  where the base64 payload is ``IV (12 bytes) ‖ ciphertext ‖ GCM tag (16 bytes)``.
- Responses to such requests are encrypted the same way.

Env var ``PAYLOAD_ENCRYPTION_KEY`` must contain a **base64-encoded 32-byte** key.
If the var is empty the middleware passes traffic through unmodified (dev mode).
"""

from __future__ import annotations

import base64
import json
import os
import secrets
from typing import Callable

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

_KEY_B64 = os.getenv(
    "PAYLOAD_ENCRYPTION_KEY",
    "RGlwbG9tYVZlcmlmeUFFUzI1NlNlY3JldEtleTB4T0s=",
)
_KEY: bytes | None = None
_GCM: AESGCM | None = None


def _get_gcm() -> AESGCM | None:
    global _KEY, _GCM
    if _GCM is not None:
        return _GCM
    raw = _KEY_B64.strip()
    if not raw:
        return None
    _KEY = base64.b64decode(raw)
    if len(_KEY) != 32:
        raise ValueError(
            f"PAYLOAD_ENCRYPTION_KEY must decode to 32 bytes, got {len(_KEY)}"
        )
    _GCM = AESGCM(_KEY)
    return _GCM


def _encrypt(plaintext: bytes) -> str:
    gcm = _get_gcm()
    if gcm is None:
        raise RuntimeError("Encryption not configured")
    iv = secrets.token_bytes(12)
    ct = gcm.encrypt(iv, plaintext, None)  # ct includes 16-byte tag
    return base64.b64encode(iv + ct).decode()


def _decrypt(payload_b64: str) -> bytes:
    gcm = _get_gcm()
    if gcm is None:
        raise RuntimeError("Encryption not configured")
    raw = base64.b64decode(payload_b64)
    iv = raw[:12]
    ct_with_tag = raw[12:]
    return gcm.decrypt(iv, ct_with_tag, None)


# ── Paths that must NOT be encrypted (health checks, OpenAPI, etc.) ──
_SKIP_PREFIXES = ("/health", "/docs", "/openapi.json", "/redoc")


class PayloadEncryptionMiddleware(BaseHTTPMiddleware):
    """Drop-in middleware: add via ``app.add_middleware(PayloadEncryptionMiddleware)``."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Skip if encryption key not set or path is excluded
        if _get_gcm() is None:
            return await call_next(request)

        path = request.url.path
        if any(path.startswith(p) for p in _SKIP_PREFIXES):
            return await call_next(request)

        encrypted_request = request.headers.get("x-encrypted") == "1"

        # ── Decrypt incoming body ──────────────────────────────
        if encrypted_request:
            try:
                body = await request.body()
                if body:
                    envelope = json.loads(body)
                    if isinstance(envelope, dict) and "_enc" in envelope:
                        decrypted = _decrypt(envelope["_enc"])
                        # Replace request body with decrypted data
                        request._body = decrypted
            except Exception:
                return JSONResponse(
                    {"error": "Failed to decrypt request payload"},
                    status_code=400,
                )

        response = await call_next(request)

        # ── Encrypt outgoing body ──────────────────────────────
        if encrypted_request:
            body_bytes = b""
            async for chunk in response.body_iterator:
                if isinstance(chunk, str):
                    body_bytes += chunk.encode()
                else:
                    body_bytes += chunk

            if body_bytes:
                try:
                    enc_payload = _encrypt(body_bytes)
                    new_body = json.dumps({"_enc": enc_payload}).encode()
                    headers = dict(response.headers)
                    headers["content-length"] = str(len(new_body))
                    headers["x-encrypted"] = "1"
                    return Response(
                        content=new_body,
                        status_code=response.status_code,
                        headers=headers,
                        media_type="application/json",
                    )
                except Exception:
                    pass  # fallback: return unencrypted

        return response
