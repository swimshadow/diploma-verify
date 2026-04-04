from fastapi import APIRouter, Depends

from deps import require_role

router = APIRouter(prefix="/employer", tags=["employer"])


@router.get("/verification-hint")
async def employer_verification_hint(user: dict = Depends(require_role("employer"))):
    """Работодатель не управляет дипломами — только публичная проверка."""
    return {
        "role": "employer",
        "public_qr": "GET /api/verify/qr/{token} или /api/verify/{token}",
        "public_manual": "POST /api/verify/manual (body: diploma_number, series, full_name, issue_date)",
        "note": "Проверка без авторизации; загрузка файлов и выпуск сертификатов — только внутри сети сервисов",
    }
