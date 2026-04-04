import base64
import hashlib
import os
import uuid
from datetime import date, datetime, timezone
from typing import Optional

import httpx
import rsa
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Response, UploadFile, status
from loguru import logger
from sqlalchemy import or_
from sqlalchemy.orm import Session

from database import compute_data_hash, get_db
from deps import get_current_user, require_role
from field_crypto import display_full_name, encrypt_field, make_search_hash
from internal_deps import internal_only
from http_client import HTTP_TIMEOUT, UPLOAD_HTTP_TIMEOUT
from models import Diploma
from schemas import (
    AiDataPatch,
    DiplomaListItem,
    DiplomaListResponse,
    DiplomaMetadata,
    DiplomaStatusPatch,
    InternalDiplomaResponse,
    LinkStudentBody,
    SearchDiplomaItem,
    SearchDiplomaResponse,
    UploadDiplomaResponse,
)

KEY_DIR = "/keys"
PRIVATE_KEY_PATH = os.path.join(KEY_DIR, "private.pem")
PUBLIC_KEY_PATH = os.path.join(KEY_DIR, "public.pem")

BLOCKCHAIN_SERVICE_URL = os.getenv(
    "BLOCKCHAIN_SERVICE_URL", "http://blockchain-service:8009"
)

PRIVATE_KEY = None
PUBLIC_KEY = None
PUBLIC_KEY_PEM = None


def _ensure_keys() -> None:
    global PRIVATE_KEY, PUBLIC_KEY, PUBLIC_KEY_PEM
    os.makedirs(KEY_DIR, exist_ok=True)
    if os.path.exists(PRIVATE_KEY_PATH) and os.path.exists(PUBLIC_KEY_PATH):
        with open(PRIVATE_KEY_PATH, "rb") as f:
            PRIVATE_KEY = rsa.PrivateKey.load_pkcs1(f.read())
        with open(PUBLIC_KEY_PATH, "rb") as f:
            PUBLIC_KEY_PEM = f.read()
            PUBLIC_KEY = rsa.PublicKey.load_pkcs1(PUBLIC_KEY_PEM)
    else:
        PUBLIC_KEY, PRIVATE_KEY = rsa.newkeys(2048)
        with open(PRIVATE_KEY_PATH, "wb") as f:
            f.write(PRIVATE_KEY.save_pkcs1("PEM"))
        with open(PUBLIC_KEY_PATH, "wb") as f:
            PUBLIC_KEY_PEM = PUBLIC_KEY.save_pkcs1("PEM")
            f.write(PUBLIC_KEY_PEM)


def sign_diploma(diploma_data: dict, private_key) -> str:
    message = (
        f"{diploma_data['diploma_number']}|{diploma_data['full_name']}|"
        f"{diploma_data['issue_date']}|{diploma_data['university_name']}"
    )
    signature = rsa.sign(message.encode(), private_key, "SHA-256")
    return base64.b64encode(signature).decode()


def verify_signature(diploma_data: dict, signature: str, public_key) -> bool:
    message = (
        f"{diploma_data['diploma_number']}|{diploma_data['full_name']}|"
        f"{diploma_data['issue_date']}|{diploma_data['university_name']}"
    )
    try:
        rsa.verify(message.encode(), base64.b64decode(signature), public_key)
        return True
    except Exception:
        return False


def generate_timestamp_proof(diploma_id: str, verified_at: datetime) -> str:
    salt = _secret_salt()
    data = f"{diploma_id}|{verified_at.isoformat()}|{salt}"
    return hashlib.sha256(data.encode()).hexdigest()


def _sign_and_timestamp_diploma(diploma: Diploma) -> None:
    if PRIVATE_KEY is None:
        _ensure_keys()
    plain_name = display_full_name(diploma)
    diploma_data = {
        "diploma_number": diploma.diploma_number,
        "full_name": plain_name,
        "issue_date": diploma.issue_date.isoformat(),
        "university_name": diploma.university_name,
    }
    diploma.digital_signature = sign_diploma(diploma_data, PRIVATE_KEY)
    verified_at = datetime.now(timezone.utc)
    diploma.signed_at = verified_at
    diploma.timestamp_hash = generate_timestamp_proof(str(diploma.id), verified_at)


def get_public_key() -> Response:
    if PUBLIC_KEY_PEM is None:
        _ensure_keys()
    return Response(content=PUBLIC_KEY_PEM, media_type="text/plain")

router = APIRouter(prefix="/diplomas", tags=["university"])
internal_router = APIRouter(
    prefix="/diplomas",
    tags=["internal"],
    dependencies=[Depends(internal_only)],
)

def _secret_salt() -> str:
    s = os.getenv("SECRET_SALT", "").strip()
    if not s:
        raise RuntimeError("SECRET_SALT must be set in the environment")
    return s


AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8001")
FILE_SERVICE_URL = os.getenv("FILE_SERVICE_URL", "http://file-service:8005")
CERTIFICATE_SERVICE_URL = os.getenv(
    "CERTIFICATE_SERVICE_URL", "http://certificate-service:8006"
)
AI_SERVICE_URL = os.getenv("AI_SERVICE_URL", "http://ai-integration-service:8007")
NOTIFICATION_SERVICE_URL = os.getenv(
    "NOTIFICATION_SERVICE_URL", "http://notification-service:8008"
)


async def _notify(account_id: uuid.UUID, ntype: str, subject: str, body: str) -> None:
    url = f"{NOTIFICATION_SERVICE_URL.rstrip('/')}/internal/send"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            await client.post(
                url,
                json={
                    "account_id": str(account_id),
                    "type": ntype,
                    "subject": subject,
                    "body": body,
                },
            )
    except httpx.RequestError as e:
        logger.warning(f"Notification failed: {e}")


async def _university_display_name(account_id: uuid.UUID) -> str:
    url = f"{AUTH_SERVICE_URL.rstrip('/')}/internal/profile/{account_id}"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.get(url)
        if r.status_code == 200:
            data = r.json()
            prof = data.get("profile") or {}
            return str(prof.get("name") or "ВУЗ")
    except httpx.RequestError as e:
        logger.warning(f"Auth profile fetch failed: {e}")
    return "ВУЗ"


async def _post_certificate_generate(diploma: Diploma) -> None:
    url = f"{CERTIFICATE_SERVICE_URL.rstrip('/')}/certificates/generate"
    payload = {
        "diploma_id": str(diploma.id),
        "diploma_data": {
            "full_name": display_full_name(diploma),
            "degree": diploma.degree,
            "specialization": diploma.specialization,
            "issue_date": diploma.issue_date.isoformat(),
            "university_name": diploma.university_name,
        },
    }
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.post(url, json=payload)
        if r.status_code not in (200, 201):
            logger.warning(f"Certificate generate failed: {r.status_code} {r.text}")
    except httpx.RequestError as e:
        logger.warning(f"Certificate generate unreachable: {e}")


async def _write_blockchain_record(diploma: Diploma, db: Session) -> None:
    url = f"{BLOCKCHAIN_SERVICE_URL.rstrip('/')}/blockchain/add"
    payload = {
        "diploma_id": str(diploma.id),
        "data_hash": diploma.data_hash,
    }
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.post(url, json=payload)
        if r.status_code not in (200, 201):
            logger.warning(f"Blockchain add failed: {r.status_code} {r.text}")
            return
        data = r.json()
        idx = data.get("block_index")
        if idx is not None:
            diploma.blockchain_block_index = int(idx)
            db.commit()
            db.refresh(diploma)
        await _send_audit(
            actor_id=None,
            actor_role=None,
            actor_ip=None,
            action="BLOCKCHAIN_RECORD_ADDED",
            resource_type="diploma",
            resource_id=diploma.id,
            old_value=None,
            new_value={"block_index": idx},
            success=True,
            error_message=None,
        )
    except httpx.RequestError as e:
        logger.warning(f"Blockchain service unreachable: {e}")


async def _send_audit(
    *,
    actor_id: uuid.UUID | None,
    actor_role: str | None,
    actor_ip: str | None,
    action: str,
    resource_type: str | None,
    resource_id: uuid.UUID | None,
    old_value: dict | None,
    new_value: dict | None,
    success: bool = True,
    error_message: str | None = None,
) -> None:
    url = f"{NOTIFICATION_SERVICE_URL.rstrip('/')}/internal/audit"
    body = {
        "actor_id": str(actor_id) if actor_id else None,
        "actor_role": actor_role,
        "actor_ip": actor_ip,
        "action": action,
        "resource_type": resource_type,
        "resource_id": str(resource_id) if resource_id else None,
        "old_value": old_value,
        "new_value": new_value,
        "success": success,
        "error_message": error_message,
    }
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            await client.post(url, json=body)
    except httpx.RequestError as e:
        logger.warning(f"Audit log failed: {e}")


async def _post_certificate_deactivate(diploma_id: uuid.UUID) -> None:
    url = f"{CERTIFICATE_SERVICE_URL.rstrip('/')}/certificates/{diploma_id}/deactivate"
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            r = await client.post(url)
        if r.status_code not in (200, 204):
            logger.warning(f"Certificate deactivate failed: {r.status_code} {r.text}")
    except httpx.RequestError as e:
        logger.warning(f"Certificate deactivate unreachable: {e}")


def _diploma_to_internal(d: Diploma) -> InternalDiplomaResponse:
    return InternalDiplomaResponse(
        id=str(d.id),
        full_name=display_full_name(d),
        diploma_number=d.diploma_number,
        degree=d.degree,
        specialization=d.specialization,
        issue_date=d.issue_date,
        university_name=d.university_name,
        data_hash=d.data_hash,
        digital_signature=d.digital_signature,
        timestamp_hash=d.timestamp_hash,
        status=d.status,
        student_account_id=str(d.student_account_id) if d.student_account_id else None,
        series=d.series,
    )


@router.post("/upload", response_model=UploadDiplomaResponse)
async def upload_diploma(
    file: UploadFile = File(...),
    metadata: str = Form(...),
    db: Session = Depends(get_db),
    user: dict = Depends(require_role("university")),
):
    logger.info(f"[UPLOAD] Начало загрузки диплома. user={user.get('account_id')}")
    logger.info(f"[UPLOAD] Файл: name={file.filename}, content_type={file.content_type}, size={file.size}")
    logger.info(f"[UPLOAD] Metadata (raw): {metadata[:500]}")
    try:
        meta = DiplomaMetadata.model_validate_json(metadata)
        logger.info(f"[UPLOAD] Metadata parsed: full_name={meta.full_name}, diploma_number={meta.diploma_number}, degree={meta.degree}")
    except Exception as e:
        logger.error(f"[UPLOAD] Invalid metadata: {e}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid metadata: {e}",
        )
    fname = (file.filename or "").lower()
    ct = (file.content_type or "").lower()
    logger.info(f"[UPLOAD] Валидация файла: fname={fname}, content_type={ct}")
    if not (fname.endswith(".pdf") or ct == "application/pdf" or ct.endswith("/pdf")):
        logger.error(f"[UPLOAD] Файл не PDF! fname={fname}, ct={ct}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Only PDF files are allowed (use .pdf or application/pdf)",
        )
    uni_account = uuid.UUID(user["account_id"])
    uni_name = await _university_display_name(uni_account)
    logger.info(f"[UPLOAD] Университет: {uni_name} ({uni_account})")
    plain_name = meta.full_name
    dh = compute_data_hash(
        meta.diploma_number,
        plain_name,
        meta.issue_date,
        _secret_salt(),
    )
    logger.info(f"[UPLOAD] Data hash computed: {dh[:16]}...")
    file_bytes = await file.read()
    logger.info(f"[UPLOAD] Прочитано {len(file_bytes)} bytes из файла")
    upload_url = f"{FILE_SERVICE_URL.rstrip('/')}/files/upload"
    logger.info(f"[UPLOAD] Загрузка файла в file-service: {upload_url}")
    try:
        async with httpx.AsyncClient(timeout=UPLOAD_HTTP_TIMEOUT) as client:
            files = {
                "file": (
                    file.filename or "upload.bin",
                    file_bytes,
                    file.content_type or "application/octet-stream",
                )
            }
            data = {"uploader_account_id": str(uni_account)}
            ur = await client.post(upload_url, files=files, data=data)
    except httpx.RequestError as e:
        logger.exception(f"[UPLOAD] File upload failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="File service unavailable",
        )
    if ur.status_code not in (200, 201):
        logger.error(f"[UPLOAD] File service error: status={ur.status_code}, body={ur.text}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"File service: {ur.text}",
        )
    file_id = uuid.UUID(ur.json()["file_id"])
    logger.info(f"[UPLOAD] Файл загружен, file_id={file_id}")
    enc_key = os.getenv("ENCRYPTION_KEY", "").strip()
    if enc_key:
        logger.info("[UPLOAD] Используется шифрование полей")
        diploma = Diploma(
            university_account_id=uni_account,
            file_id=file_id,
            status="pending",
            full_name=None,
            full_name_encrypted=encrypt_field(plain_name),
            full_name_hash=make_search_hash(plain_name),
            diploma_number=meta.diploma_number,
            series=meta.series or None,
            degree=meta.degree,
            specialization=meta.specialization,
            issue_date=meta.issue_date,
            date_of_birth=meta.date_of_birth,
            university_name=uni_name,
            data_hash=dh,
        )
    else:
        logger.info("[UPLOAD] Без шифрования полей")
        diploma = Diploma(
            university_account_id=uni_account,
            file_id=file_id,
            status="pending",
            full_name=plain_name,
            full_name_encrypted=None,
            full_name_hash=None,
            diploma_number=meta.diploma_number,
            series=meta.series or None,
            degree=meta.degree,
            specialization=meta.specialization,
            issue_date=meta.issue_date,
            date_of_birth=meta.date_of_birth,
            university_name=uni_name,
            data_hash=dh,
        )
    db.add(diploma)
    db.commit()
    db.refresh(diploma)
    logger.info(f"[UPLOAD] Диплом создан в БД: id={diploma.id}, status=pending")

    ai_url = f"{AI_SERVICE_URL.rstrip('/')}/ai/extract"
    logger.info(f"[UPLOAD] Запуск AI extraction: {ai_url}")
    try:
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
            await client.post(
                ai_url,
                json={"file_id": str(file_id), "diploma_id": str(diploma.id)},
            )
        logger.info("[UPLOAD] AI extraction запущен")
    except httpx.RequestError as e:
        logger.warning(f"[UPLOAD] AI extract trigger failed: {e}")

    await _notify(
        uni_account,
        "diploma_uploaded",
        "Диплом загружен",
        f"Диплом {meta.diploma_number} отправлен на обработку",
    )
    logger.info(f"[UPLOAD] Уведомление отправлено")
    await _send_audit(
        actor_id=uni_account,
        actor_role="university",
        actor_ip=None,
        action="DIPLOMA_UPLOADED",
        resource_type="diploma",
        resource_id=diploma.id,
        old_value=None,
        new_value={"status": "pending"},
        success=True,
        error_message=None,
    )
    logger.info(f"[UPLOAD] Аудит записан. Загрузка завершена успешно. diploma_id={diploma.id}")
    return UploadDiplomaResponse(diploma_id=str(diploma.id), status="pending")


@router.get("", response_model=DiplomaListResponse)
async def list_diplomas(
    db: Session = Depends(get_db),
    user: dict = Depends(require_role("university")),
    status: Optional[str] = Query(None),
):
    uid = uuid.UUID(user["account_id"])
    q = db.query(Diploma).filter(Diploma.university_account_id == uid)
    if status:
        q = q.filter(Diploma.status == status)
    rows = q.order_by(Diploma.created_at.desc()).all()
    items = [
        DiplomaListItem(
            id=str(d.id),
            full_name=display_full_name(d),
            diploma_number=d.diploma_number,
            series=d.series,
            degree=d.degree,
            specialization=d.specialization,
            issue_date=d.issue_date,
            status=d.status,
            file_id=str(d.file_id) if d.file_id else None,
            student_account_id=str(d.student_account_id) if d.student_account_id else None,
        )
        for d in rows
    ]
    return DiplomaListResponse(diplomas=items)


@router.get("/{diploma_id}", response_model=DiplomaListItem)
async def get_diploma(
    diploma_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: dict = Depends(require_role("university")),
):
    uid = uuid.UUID(user["account_id"])
    d = (
        db.query(Diploma)
        .filter(
            Diploma.id == diploma_id,
            Diploma.university_account_id == uid,
        )
        .first()
    )
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return DiplomaListItem(
        id=str(d.id),
        full_name=display_full_name(d),
        diploma_number=d.diploma_number,
        series=d.series,
        degree=d.degree,
        specialization=d.specialization,
        issue_date=d.issue_date,
        status=d.status,
        file_id=str(d.file_id) if d.file_id else None,
        student_account_id=str(d.student_account_id) if d.student_account_id else None,
    )


@router.post("/{diploma_id}/verify", response_model=UploadDiplomaResponse)
async def verify_manual(
    diploma_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: dict = Depends(require_role("university")),
):
    logger.info(f"[VERIFY] Начало верификации diploma_id={diploma_id}, user={user.get('account_id')}")
    uid = uuid.UUID(user["account_id"])
    d = (
        db.query(Diploma)
        .filter(
            Diploma.id == diploma_id,
            Diploma.university_account_id == uid,
        )
        .first()
    )
    if d is None:
        logger.warning(f"[VERIFY] Диплом не найден: {diploma_id}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    logger.info(f"[VERIFY] Диплом найден: status={d.status}")
    if d.status == "revoked":
        logger.warning(f"[VERIFY] Попытка верификации отозванного диплома {diploma_id}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot verify a revoked diploma",
        )
    if d.status == "verified":
        logger.info(f"[VERIFY] Диплом уже верифицирован: {diploma_id}")
        return UploadDiplomaResponse(diploma_id=str(d.id), status="verified")
    d.status = "verified"
    _sign_and_timestamp_diploma(d)
    db.commit()
    logger.info(f"[VERIFY] Диплом подписан и сохранён: {diploma_id}")
    await _post_certificate_generate(d)
    logger.info(f"[VERIFY] Сертификат сгенерирован")
    await _write_blockchain_record(d, db)
    logger.info(f"[VERIFY] Блокчейн запись добавлена")
    await _send_audit(
        actor_id=uid,
        actor_role="university",
        actor_ip=None,
        action="DIPLOMA_VERIFIED",
        resource_type="diploma",
        resource_id=d.id,
        old_value={"status": "pending"},
        new_value={"status": "verified"},
        success=True,
        error_message=None,
    )
    return UploadDiplomaResponse(diploma_id=str(d.id), status="verified")


@router.post("/{diploma_id}/revoke", response_model=UploadDiplomaResponse)
async def revoke_diploma(
    diploma_id: uuid.UUID,
    db: Session = Depends(get_db),
    user: dict = Depends(require_role("university")),
):
    logger.info(f"[REVOKE] Начало отзыва diploma_id={diploma_id}, user={user.get('account_id')}")
    uid = uuid.UUID(user["account_id"])
    d = (
        db.query(Diploma)
        .filter(
            Diploma.id == diploma_id,
            Diploma.university_account_id == uid,
        )
        .first()
    )
    if d is None:
        logger.warning(f"[REVOKE] Диплом не найден: {diploma_id}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if d.status == "revoked":
        logger.info(f"[REVOKE] Диплом уже отозван: {diploma_id}")
        return UploadDiplomaResponse(diploma_id=str(d.id), status="revoked")
    prev_status = d.status
    d.status = "revoked"
    db.commit()
    logger.info(f"[REVOKE] Диплом отозван: {diploma_id}, prev_status={prev_status}")
    await _post_certificate_deactivate(diploma_id)
    logger.info(f"[REVOKE] Сертификат деактивирован")
    await _notify(
        uid,
        "diploma_revoked",
        "Диплом отозван",
        f"Диплом {d.diploma_number} отозван",
    )
    await _send_audit(
        actor_id=uid,
        actor_role="university",
        actor_ip=None,
        action="DIPLOMA_REVOKED",
        resource_type="diploma",
        resource_id=d.id,
        old_value={"status": prev_status},
        new_value={"status": "revoked"},
        success=True,
        error_message=None,
    )
    return UploadDiplomaResponse(diploma_id=str(d.id), status="revoked")


@internal_router.get("/search", response_model=SearchDiplomaResponse)
def internal_search(
    full_name: str,
    date_of_birth: date,
    db: Session = Depends(get_db),
):
    q = db.query(Diploma).filter(Diploma.date_of_birth == date_of_birth)
    if os.getenv("ENCRYPTION_KEY", "").strip():
        h = make_search_hash(full_name)
        q = q.filter(
            or_(Diploma.full_name_hash == h, Diploma.full_name == full_name)
        )
    else:
        q = q.filter(Diploma.full_name == full_name)
    rows = q.all()
    items = [
        SearchDiplomaItem(
            id=str(r.id),
            full_name=display_full_name(r),
            diploma_number=r.diploma_number,
            series=r.series,
            degree=r.degree,
            specialization=r.specialization,
            issue_date=r.issue_date,
            university_name=r.university_name,
            status=r.status,
            student_account_id=str(r.student_account_id) if r.student_account_id else None,
            digital_signature=r.digital_signature,
            ai_confidence=r.ai_confidence,
            created_at=r.created_at.isoformat() if r.created_at else None,
        )
        for r in rows
    ]
    return SearchDiplomaResponse(diplomas=items)


@internal_router.get("/by-hash/{data_hash}", response_model=InternalDiplomaResponse)
def internal_by_hash(data_hash: str, db: Session = Depends(get_db)):
    d = db.query(Diploma).filter(Diploma.data_hash == data_hash).first()
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return _diploma_to_internal(d)


@internal_router.patch("/{diploma_id}/status", response_model=InternalDiplomaResponse)
async def internal_patch_status(
    diploma_id: uuid.UUID,
    payload: DiplomaStatusPatch,
    db: Session = Depends(get_db),
):
    d = db.query(Diploma).filter(Diploma.id == diploma_id).first()
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if payload.status not in ("verified", "revoked"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="status must be verified or revoked",
        )
    if payload.moderator_note is not None:
        d.moderator_note = payload.moderator_note
    if payload.status == "verified":
        if d.status == "revoked":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot verify a revoked diploma",
            )
        if d.status != "verified":
            d.status = "verified"
            _sign_and_timestamp_diploma(d)
            db.commit()
            db.refresh(d)
            await _post_certificate_generate(d)
            await _write_blockchain_record(d, db)
        else:
            db.commit()
            db.refresh(d)
    else:
        if d.status == "revoked":
            db.commit()
            db.refresh(d)
            return _diploma_to_internal(d)
        d.status = "revoked"
        db.commit()
        db.refresh(d)
        await _post_certificate_deactivate(diploma_id)
    return _diploma_to_internal(d)


@internal_router.get("/{diploma_id}", response_model=InternalDiplomaResponse)
def internal_get_diploma(diploma_id: uuid.UUID, db: Session = Depends(get_db)):
    d = db.query(Diploma).filter(Diploma.id == diploma_id).first()
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return _diploma_to_internal(d)


@internal_router.patch("/{diploma_id}/ai-data", response_model=InternalDiplomaResponse)
async def internal_ai_data(
    diploma_id: uuid.UUID,
    payload: AiDataPatch,
    db: Session = Depends(get_db),
):
    d = db.query(Diploma).filter(Diploma.id == diploma_id).first()
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if d.status == "revoked":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Diploma is revoked",
        )
    d.ai_extracted_data = payload.ai_extracted_data
    d.ai_confidence = payload.confidence
    if payload.confidence > 0.85:
        if d.status == "pending":
            d.status = "verified"
            _sign_and_timestamp_diploma(d)
            db.commit()
            db.refresh(d)
            await _post_certificate_generate(d)
            await _write_blockchain_record(d, db)
            await _notify(
                d.university_account_id,
                "diploma_verified",
                "Диплом проверен",
                f"Диплом {d.diploma_number} подтверждён автоматически",
            )
        else:
            db.commit()
            db.refresh(d)
    else:
        db.commit()
        db.refresh(d)
    return _diploma_to_internal(d)


@internal_router.patch("/{diploma_id}/link-student", response_model=InternalDiplomaResponse)
def internal_link_student(
    diploma_id: uuid.UUID,
    body: LinkStudentBody,
    db: Session = Depends(get_db),
):
    d = db.query(Diploma).filter(Diploma.id == diploma_id).first()
    if d is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if d.status == "revoked":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot link student to a revoked diploma",
        )
    try:
        sid = uuid.UUID(body.student_account_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid UUID")
    if d.student_account_id is not None and d.student_account_id != sid:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Diploma already linked to another student",
        )
    d.student_account_id = sid
    db.commit()
    db.refresh(d)
    return _diploma_to_internal(d)
