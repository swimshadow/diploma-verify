"""
ML Classification Service — Port 3001
POST /ml/classify-diploma  →  принимает файл диплома, возвращает JSON с результатом подлинности
"""

import io
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

# ──────────────────────────────────────────────────────────────────────────────
# TODO: вставь сюда импорт своей готовой модели
# Пример:
# import torch
# from your_model_module import DiplomaClassifier
# model = DiplomaClassifier.load("path/to/model.pt")
# ──────────────────────────────────────────────────────────────────────────────

app = FastAPI(title="ML Diploma Classifier", version="1.0")


def run_model(file_bytes: bytes, filename: str) -> dict:
    """
    Вызов твоей готовой модели.
    Замени тело этой функции на вызов своей нейронки.

    Должна вернуть dict вида:
    {
        "is_authentic": bool,
        "confidence":   float (0.0 – 1.0),
        "details":      dict  (любые доп. поля по желанию)
    }
    """
    # ── ЗАГЛУШКА — замени на реальный вызов модели ──────────────────────────
    # image = preprocess(file_bytes)
    # prediction = model.predict(image)
    # return {"is_authentic": prediction > 0.5, "confidence": float(prediction), "details": {}}
    raise NotImplementedError("Подключи свою модель в функцию run_model()")
    # ────────────────────────────────────────────────────────────────────────


@app.get("/health")
def health():
    return {"status": "ok", "service": "ml-classifier"}


@app.post("/ml/classify-diploma")
async def classify_diploma(file: UploadFile = File(...)):
    allowed_types = {"application/pdf", "image/jpeg", "image/png", "image/tiff"}
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=415, detail="Поддерживаются только PDF и изображения (jpg, png, tiff)")

    file_bytes = await file.read()

    try:
        result = run_model(file_bytes, file.filename)
    except NotImplementedError as e:
        raise HTTPException(status_code=501, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка модели: {e}")

    return JSONResponse({
        "success":      True,
        "is_authentic": result["is_authentic"],
        "confidence":   result["confidence"],
        "details":      result.get("details", {}),
    })
