# ML Classifier Service

Python FastAPI микросервис для классификации подлинности дипломов.

## API

### Health Check
```bash
GET /health
```

### Classify Diploma
```bash
POST /ml/classify-diploma
Content-Type: multipart/form-data

- file: файл диплома (PDF, JPG, PNG, TIFF)
```

**Response:**
```json
{
  "success": true,
  "is_authentic": true,
  "confidence": 0.95,
  "details": {}
}
```

## Реализация

На данный момент сервис содержит заглушку. Для интеграции вашей собственной модели:

1. Подготовьте обученную модель
2. Замените функцию `run_model()` в `main.py` на вызов вашей модели
3. Функция должна возвращать dict с полями:
   - `is_authentic` (bool): подлинный ли диплом
   - `confidence` (float): уверенность (0.0 - 1.0)
   - `details` (dict): дополнительные детали

Пример реализации:
```python
import torch
from your_model import DiplomaClassifier

model = DiplomaClassifier.load("path/to/model.pt")

def run_model(file_bytes: bytes, filename: str) -> dict:
    image = preprocess_image(file_bytes)
    prediction = model.predict(image)
    return {
        "is_authentic": prediction > 0.5,
        "confidence": float(prediction),
        "details": {}
    }
```

## Сборка и запуск

### Docker
```bash
docker build -t ml-classifier-service .
docker run -p 3001:3001 ml-classifier-service
```

### Локально
```bash
pip install -r requirements.txt
uvicorn main:app --reload --port 3001
```

## Переменные окружения

- `PORT` - порт сервиса (по умолчанию 3001)

## Требования к модели

Модель должна:
- Принимать файлы в формате PDF или изображения
- Возвращать вероятность подлинности (0.0 - 1.0)
- Работать быстро (желательно < 5 секунд на файл)

## Будущие улучшения

- Интеграция с TensorFlow/PyTorch моделями
- Поддержка батч-обработки
- Кеширование результатов
- Логирование и метрики
