import hashlib
import os

from cryptography.fernet import Fernet

_ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", "").strip()
_SECRET_SALT = os.getenv("SECRET_SALT", "").strip()
_fernet: Fernet | None = None


def _get_fernet() -> Fernet | None:
    global _fernet
    if not _ENCRYPTION_KEY:
        return None
    if _fernet is None:
        _fernet = Fernet(_ENCRYPTION_KEY.encode("utf-8"))
    return _fernet


def encrypt_field(value: str) -> str:
    f = _get_fernet()
    if f is None:
        return value
    return f.encrypt(value.encode("utf-8")).decode("utf-8")


def decrypt_field(encrypted: str) -> str:
    if not encrypted:
        return ""
    f = _get_fernet()
    if f is None:
        return encrypted
    return f.decrypt(encrypted.encode("utf-8")).decode("utf-8")


def make_search_hash(value: str) -> str:
    if not _SECRET_SALT:
        raise RuntimeError("SECRET_SALT must be set")
    return hashlib.sha256(
        f"{value.lower().strip()}{_SECRET_SALT}".encode("utf-8")
    ).hexdigest()


def display_full_name(diploma) -> str:
    enc = getattr(diploma, "full_name_encrypted", None)
    if enc:
        return decrypt_field(enc)
    return getattr(diploma, "full_name", "") or ""
