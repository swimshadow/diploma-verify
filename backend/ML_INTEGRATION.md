# Интеграция ML-сервисов в diploma-verify

## Обзор

Нейросетевые сервисы из репозитория `/home/swimshadow/Hackathon/ai/fad/` успешно интегрированы в основной проект `diploma-verify`.

## Компоненты

### 1. ML Extract Service (Node.js)
**Расположение:** `backend/ml-extract-service/`
- **Порт:** 3000 (внутренне), 13000 (localhost для отладки)
- **Функция:** Извлечение текста из дипломов (PDF и изображения) через OCR
- **Зависимости:** Tesseract OCR, pdf-parse
- **Файлы:**
  - `server.js` - главный сервис
  - `package.json` - зависимости Node.js
  - `Dockerfile` - конфигурация контейнера
  - `README.md` - документация

**API Endpoints:**
- `GET /health` - проверка здоровья
- `POST /ml/extract-diploma` - извлечение данных из файла

### 2. ML Classifier Service (Python FastAPI)
**Расположение:** `backend/ml-classifier-service/`
- **Порт:** 3001 (внутренне), 13001 (localhost для отладки)
- **Функция:** Классификация подлинности дипломов
- **Статус:** Шаблон с заглушкой для интеграции вашей модели
- **Файлы:**
  - `main.py` - приложение FastAPI
  - `requirements.txt` - Python зависимости
  - `Dockerfile` - конфигурация контейнера
  - `README.md` - документация и инструкции интеграции

**API Endpoints:**
- `GET /health` - проверка здоровья
- `POST /ml/classify-diploma` - классификация файла

### 3. Обновленный AI Integration Service
**Расположение:** `backend/ai-integration-service/`
- **Порт:** 8007
- **Изменения:**
  - Добавлены переменные окружения для ML-сервисов:
    - `ML_EXTRACT_URL` - адрес ML Extract сервиса
    - `ML_CLASSIFIER_URL` - адрес ML Classifier сервиса
  - Обновлена функция `run_extract_pipeline()` для вызова реальных ML-сервисов
  - Добавлен новый эндпоинт `/ai/classify` для классификации

**API Endpoints:**
- `POST /ai/extract` - запуск процесса извлечения (асинхронно)
- `POST /ai/result` - сохранение результатов AI
- `POST /ai/classify` - классификация диплома (новый)

## Архитектура потока обработки

```
1. Пользователь загружает диплом → file-service
2. AI Service запрашивает файл из file-service
3. AI Service отправляет файл в ML Extract Service → извлекаются данные
4. AI Service отправляет файл в ML Classifier Service → определяется подлинность
5. AI Service сохраняет результаты в БД (diplomas, ml_processing_log)
6. Если confidence > 0.85 и is_authentic == true → stats = "verified"
7. Если is_authentic == false → status = "rejected"
```

## Docker Compose интеграция

Добавлены вызовы в `backend/docker-compose.yml`:

```yaml
ml-extract-service:
  build: ./ml-extract-service
  ports: ["127.0.0.1:13000:3000"]
  
ml-classifier-service:
  build: ./ml-classifier-service
  ports: ["127.0.0.1:13001:3001"]
  
ai-integration-service:
  # ... существующие параметры ...
  environment:
    ML_EXTRACT_URL: http://ml-extract-service:3000
    ML_CLASSIFIER_URL: http://ml-classifier-service:3001
  depends_on:
    ml-extract-service:
      condition: service_started
    ml-classifier-service:
      condition: service_started
```

## Запуск

### Полный стек
```bash
cd backend
docker-compose up -d
```

### Только ML-сервисы + AI-интеграция
```bash
docker-compose up ml-extract-service ml-classifier-service ai-integration-service -d
```

## Переменные окружения

Добавьте в `.env` файл:

```env
# ML Services URLs (для локальной разработки)
ML_EXTRACT_URL=http://localhost:13000
ML_CLASSIFIER_URL=http://localhost:13001

# Существующие параметры (при необходимости)
HTTP_CLIENT_TIMEOUT=10
AI_FILE_FETCH_TIMEOUT=120
```

## Локальная разработка

### ML Extract Service
```bash
cd backend/ml-extract-service
npm install
npm start
# Доступен на http://localhost:3000
```

### ML Classifier Service
```bash
cd backend/ml-classifier-service
pip install -r requirements.txt
uvicorn main:app --reload --port 3001
# Доступен на http://localhost:3001
```

### Тестирование
```bash
# Наполнить Extract сервис
curl -X POST -F "file=@diploma.pdf" http://localhost:3000/ml/extract-diploma

# Классифицировать диплом
curl -X POST -F "file=@diploma.pdf" http://localhost:3001/ml/classify-diploma
```

## Интеграция собственной ML-модели

### Для Classifier Service:

1. Подготовьте вашу обученную модель
2. Обновите функцию `run_model()` в `ml-classifier-service/main.py`
3. Пример:

```python
import torch
from your_model import DiplomaClassifier

model = DiplomaClassifier.load("path/to/model.pt")

def run_model(file_bytes: bytes, filename: str) -> dict:
    image = preprocess(file_bytes)
    prediction = model.predict(image)
    return {
        "is_authentic": prediction > 0.5,
        "confidence": float(prediction),
        "details": {"model_version": "1.0"}
    }
```

## Логирование

Логи доступны в:
- Контейнеры: `docker logs <service_name>`
- Файлы: `backend/logs/ai-integration-service.log`
- ML-сервисы логируют в stdout (видны в `docker logs`)

## Мониторинг

Health checks настроены для каждого сервиса:
- ML Extract: `GET http://ml-extract-service:3000/health`
- ML Classifier: `GET http://ml-classifier-service:3001/health`
- AI Integration: `GET http://ai-integration-service:8007/health`

## Известные ограничения

1. ML Classifier Service содержит только заглушку - требует интеграции вашей модели
2. ML Extract Service для изображений требует установки Tesseract OCR в контейнере
3. Текущие параметры для классификации (confidence > 0.85) могут быть отрегулированы

## Следующие шаги

1. Интегрировать вашу классификационную модель в `ml-classifier-service/main.py`
2. Протестировать сквозную обработку дипломов
3. Оптимизировать производительность (кеширование, батч-обработка)
4. Добавить метрики и мониторинг

## Процесс обновления модели

Когда получите готовую модель классификации:

```bash
# 1. Обновить main.py в ml-classifier-service
# 2. Добавить модель в контейнер (если нужно)
# 3. Пересобрать контейнер
docker-compose build ml-classifier-service
# 4. Перезапустить
docker-compose up -d ml-classifier-service
```
