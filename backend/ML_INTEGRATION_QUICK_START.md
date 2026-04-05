# ✅ ML-сервисы интегрированы в diploma-verify

## Структура добавленных сервисов

```
diploma-verify/backend/
├── ml-extract-service/          # Новый - извлечение данных из дипломов
│   ├── server.js               # Node.js приложение с Express
│   ├── package.json            # Зависимости
│   ├── Dockerfile              # Docker конфигурация
│   └── README.md               # Документация
│
├── ml-classifier-service/       # Новый - классификация подлинности
│   ├── main.py                 # FastAPI приложение
│   ├── requirements.txt         # Python зависимости
│   ├── Dockerfile              # Docker конфигурация
│   └── README.md               # Документация + инструкции интеграции
│
└── ai-integration-service/      # Обновлен
    ├── routers/ai.py           # Обновлены функции для вызова ML-сервисов
    └── requirements.txt        # Без изменений
```

## Основные изменения

### 1. ML Extract Service (Node.js)
- Извлекает текст из PDF и изображений через OCR (Tesseract)
- Парсит поля диплома (ФИО, степень, специальность, номер, годище выпуска)
- Порт: 3000

### 2. ML Classifier Service (Python FastAPI)
- Шаблон для интеграции модели классификации подлинности
- На данный момент содержит заглушку
- Порт: 3001

### 3. AI Integration Service (обновлен)
- Теперь использует реальные ML-сервисы вместо заглушек
- Добавлены новые переменные окружения:
  - `ML_EXTRACT_URL` (по умолчанию: http://ml-extract-service:3000)
  - `ML_CLASSIFIER_URL` (по умолчанию: http://ml-classifier-service:3001)
- Новый эндпоинт: `POST /ai/classify` для классификации диплома

### 4. Docker Compose (обновлен)
- Добавлены сервисы ml-extract-service и ml-classifier-service
- Обновлены зависимости ai-integration-service
- Здоровье контейнеров проверяется регулярно

## Запуск

```bash
cd backend
docker-compose up -d
```

## Тестирование

```bash
# 1. Загрузить диплом
curl -X POST -F "file=@diploma.pdf" http://localhost:13000/ml/extract-diploma

# 2. Классифицировать (временно вернет ошибку - нужна модель)
curl -X POST -F "file=@diploma.pdf" http://localhost:13001/ml/classify-diploma

# 3. Через AI Integration Service
curl -X POST http://localhost:8007/ai/extract \
  -H "Content-Type: application/json" \
  -d '{"file_id":"uuid","diploma_id":"uuid"}'
```

## Для интеграции вашей модели

Смотрите: `backend/ml-classifier-service/README.md`

1. Обновите функцию `run_model()` в `main.py`
2. Добавьте зависимости в `requirements.txt` (pytorch, tensorflow и т.д.)
3. Пересоберите контейнер: `docker-compose build ml-classifier-service`
4. Перезапустите: `docker-compose up -d ml-classifier-service`

## Подробная документация

Смотрите: `backend/ML_INTEGRATION.md`

## Логирование

- ML Extract: `docker logs diploma-verify-backend-ml-extract-service-1`
- ML Classifier: `docker logs diploma-verify-backend-ml-classifier-service-1`
- AI Integration: `docker logs diploma-verify-backend-ai-integration-service-1`

## Готово! ✅

Все компоненты интегрированы и готовы к использованию. 
Осталось только подключить вашу ML-модель к классификатору.
