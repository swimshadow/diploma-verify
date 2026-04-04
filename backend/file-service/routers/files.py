import os
import uuid
from pathlib import Path

import aiofiles
from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile, status
from fastapi.responses import FileResponse, Response
from loguru import logger
from sqlalchemy.orm import Session

from database import get_db
from models import FileRecord
from schemas import UploadResponse

router = APIRouter(prefix="/files", tags=["files"])

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "/uploads"))
# Если задан — DELETE /files/{id} требует заголовок X-Internal-Token
FILE_INTERNAL_DELETE_TOKEN = os.getenv("FILE_INTERNAL_DELETE_TOKEN", "").strip()


@router.post(
    "/upload",
    response_model=UploadResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_file(
    file: UploadFile = File(...),
    uploader_account_id: str | None = Form(default=None),
    db: Session = Depends(get_db),
):
    logger.info(f"[UPLOAD] Начало загрузки файла: name={file.filename}, content_type={file.content_type}, uploader={uploader_account_id}")
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    fid = uuid.uuid4()
    suffix = Path(file.filename or "bin").suffix or ".bin"
    if len(suffix) > 32:
        suffix = ".bin"
    stored_name = f"{fid}{suffix}"
    dest = UPLOAD_DIR / stored_name
    size = 0
    try:
        async with aiofiles.open(dest, "wb") as out:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)
                await out.write(chunk)
    except Exception as e:
        logger.exception(f"Upload failed: {e}")
        if dest.exists():
            dest.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Upload failed",
        )

    uid = None
    if uploader_account_id:
        try:
            uid = uuid.UUID(uploader_account_id)
        except ValueError:
            uid = None

    rec = FileRecord(
        id=fid,
        original_name=file.filename or stored_name,
        stored_path=str(dest),
        mime_type=file.content_type,
        size_bytes=size,
        uploader_account_id=uid,
    )
    db.add(rec)
    db.commit()
    logger.info(f"[UPLOAD] Файл сохранён: file_id={fid}, name={rec.original_name}, size={size}, path={dest}")
    return UploadResponse(
        file_id=str(fid),
        original_name=rec.original_name,
        size_bytes=size,
    )


@router.get("/{file_id}")
async def download_file(file_id: uuid.UUID, db: Session = Depends(get_db)):
    logger.info(f"[DOWNLOAD] Запрос файла: file_id={file_id}")
    rec = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    if rec is None or not Path(rec.stored_path).is_file():
        logger.warning(f"[DOWNLOAD] Файл не найден: file_id={file_id}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    logger.info(f"[DOWNLOAD] Отдаём файл: file_id={file_id}, name={rec.original_name}")
    return FileResponse(
        rec.stored_path,
        filename=rec.original_name,
        media_type=rec.mime_type or "application/octet-stream",
    )


@router.delete("/{file_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_file(
    file_id: uuid.UUID,
    db: Session = Depends(get_db),
    x_internal_token: str | None = Header(default=None, alias="X-Internal-Token"),
):
    logger.info(f"[DELETE] Запрос удаления файла: file_id={file_id}")
    if FILE_INTERNAL_DELETE_TOKEN and x_internal_token != FILE_INTERNAL_DELETE_TOKEN:
        logger.warning(f"[DELETE] Неверный internal token для file_id={file_id}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing internal token",
        )
    rec = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    if rec is None:
        logger.warning(f"[DELETE] Файл не найден: file_id={file_id}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    p = Path(rec.stored_path)
    if p.is_file():
        p.unlink(missing_ok=True)
    db.delete(rec)
    db.commit()
    logger.info(f"[DELETE] Файл удалён: file_id={file_id}, name={rec.original_name}")
    return Response(status_code=status.HTTP_204_NO_CONTENT)
