# FastAPI Mail Microservice

Простой микросервис на FastAPI для отправки писем через SMTP.

## API

- `GET /ping` - проверка работоспособности
- `POST /send` - отправка письма
  - body:
    - `sender` (optional)
    - `recipients` (array of emails)
    - `subject` (string)
    - `body` (string)
    - `html` (optional string)

## Сборка и запуск в Docker

```bash
docker build -t mail-service .
docker run -p 8000:8000 \
  -e SMTP_HOST=smtp.example.com \
  -e SMTP_PORT=587 \
  -e SMTP_USER=your_user \
  -e SMTP_PASSWORD=your_password \
  -e SMTP_USE_TLS=true \
  -e DEFAULT_SENDER=noreply@example.com \
  mail-service
```

или через `docker-compose`:

```bash
docker compose up --build
```

## Пример запроса

```bash
curl -X POST http://localhost:8000/send \
  -H "Content-Type: application/json" \
  -d '{
    "recipients": ["user@example.com"],
    "subject": "Hello",
    "body": "Hello world"
  }'
```
