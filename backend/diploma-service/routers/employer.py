from fastapi import APIRouter, Depends, HTTPException, status

from deps import get_current_user

router = APIRouter(prefix="/employer", tags=["employer"])


async def require_employer(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "employer":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return user


@router.get("/verification-hint")
async def employer_verification_hint(user: dict = Depends(require_employer)):
    """Работодатель не управляет дипломами — только публичная проверка."""
    return {
        "role": "employer",
        "public_qr": "GET /api/verify/qr/{token} или /api/verify/{token}",
        "public_manual": "POST /api/verify/manual (body: diploma_number, series, full_name, issue_date)",
        "note": "Проверка без авторизации; загрузка файлов и выпуск сертификатов — только внутри сети сервисов",
    }
