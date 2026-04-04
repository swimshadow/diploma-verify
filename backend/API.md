# API Documentation — DiplomaVerify

Все сервисы работают за **Caddy** reverse proxy (`http://localhost:8000`).  
Внутренние (`/internal/...`) эндпоинты **не доступны** снаружи через Caddy.

---

## Аутентификация

| Тип | Описание |
|-----|----------|
| **Public** | Без авторизации |
| **JWT** | Header `Authorization: Bearer <access_token>` |
| **Internal** | Межсервисная коммуникация, закрыта от внешнего доступа |
| **API-key** | Передаётся в теле запроса (только `/admin/setup`) |

Все JWT-токены проверяются через `auth-service /internal/verify-token`.

---

## Сводка портов

| Сервис | Внутренний порт | Внешний (localhost) | Caddy route |
|--------|----------------|---------------------|-------------|
| auth-service | 8001 | 18001 | `/api/auth/*` |
| university-service | 8002 | 18002 | `/api/university/*` |
| diploma-service | 8003 | 18003 | `/api/student/*`, `/api/employer/*` |
| verify-service | 8004 | 18004 | `/api/verify/*` |
| file-service | 8005 | 18005 | `/api/files/*` |
| certificate-service | 8006 | 18006 | `/api/certificates/*` |
| ai-integration-service | 8007 | 18007 | `/api/ai/*` |
| notification-service | 8008 | 18008 | `/api/notifications/*` |
| blockchain-service | 8009 | 18009 | `/api/blockchain/*` |
| admin-service | 8010 | 8010 | `/api/admin/*` |
| mail-service | 8000 | 8011 | `/api/mail/*` |

---

## 1. Auth Service (порт 8001)

Регистрация, JWT-аутентификация, профили, refresh-токены, ЭЦП.

### Публичные эндпоинты

#### `POST /auth/register` — Регистрация
- **Auth:** Public
- **Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "string (6-128 символов)",
    "role": "university | employer",
    "profile": {
      // university: { "name", "inn", "ogrn" }
      // employer: { "company_name", "inn" }
    }
  }
  ```
  > Студенты регистрируются только через ВУЗ при загрузке диплома.
- **Response:** `{ account_id, access_token, refresh_token, role }`

#### `POST /auth/login` — Вход
- **Auth:** Public
- **Body:** `{ "email", "password" }`
- **Response:** `{ access_token, refresh_token, role, profile }`

#### `POST /auth/refresh` — Обновление access-токена
- **Auth:** Public
- **Body:** `{ "refresh_token" }`
- **Response:** `{ access_token }`

#### `POST /auth/logout` — Выход
- **Auth:** Public
- **Body:** `{ "refresh_token" }`
- **Response:** `204 No Content`

#### `GET /auth/me` — Текущий пользователь
- **Auth:** JWT
- **Response:** `{ account_id, email, role, profile }`

#### `POST /auth/setup-demo` — Демо-аккаунты
- **Auth:** Public (только при `DEMO_MODE=true`)
- **Response:** `{ created: [...], skipped: [...] }`

### ЭЦП (Электронная цифровая подпись)

#### `POST /auth/ecp/challenge` — Получение challenge
- **Auth:** Public
- **Body:** `{ "email" }`
- **Response:** `{ challenge, expires_in: 300 }`

#### `POST /auth/ecp/verify` — Верификация подписи
- **Auth:** Public
- **Body:** `{ "email", "challenge", "signature", "key_fingerprint?" }`
- **Response:** `{ access_token, refresh_token, role }`

#### `POST /auth/ecp/keys` — Регистрация ключа ЭЦП
- **Auth:** Internal
- **Body:** `{ "public_key_pem", "key_name", "algorithm?" }`
- **Response:** `{ key_id, fingerprint, algorithm, created_at }`

#### `GET /auth/ecp/keys` — Список ключей
- **Auth:** Internal
- **Response:** `[{ key_id, key_name, fingerprint, algorithm, is_active, created_at, last_used_at }]`

#### `DELETE /auth/ecp/keys/{key_id}` — Деактивация ключа
- **Auth:** Internal
- **Response:** `{ status: "deactivated" }`

### Внутренние эндпоинты

#### `GET /internal/verify-token` — Проверка JWT
- **Query:** `token`
- **Response:** `{ account_id, role, profile_id }`

#### `GET /internal/profile/{account_id}` — Профиль
- **Response:** `{ account_id, role, email, profile }`

#### `POST /internal/create-admin` — Создание админа
- **Body:** `{ "email", "password" }`
- **Response:** `{ account_id, email }`

#### `POST /internal/register-student` — Регистрация студента (от ВУЗа)
- **Body:** `{ "email", "password", "full_name", "date_of_birth?" }`
- **Response:** `{ account_id, email }`

---

## 2. University Service (порт 8002)

Управление дипломами ВУЗа — загрузка, верификация, отзыв, цифровая подпись.

### Публичные эндпоинты

#### `POST /university/diplomas/upload` — Загрузка диплома
- **Auth:** JWT (role=university)
- **Body:** `multipart/form-data`
  - `file` — PDF-файл диплома
  - `metadata` — JSON:
    ```json
    {
      "full_name": "Иванов Иван Иванович",
      "diploma_number": "123456",
      "series": "ВСГ",
      "degree": "Бакалавр",
      "specialization": "Информатика",
      "issue_date": "2024-06-30",
      "date_of_birth": "2000-01-15",
      "student_email": "student@mail.ru",
      "student_password": "password123"
    }
    ```
  > При указании `student_email` + `student_password` автоматически создаётся аккаунт студента.
- **Response:** `{ diploma_id, status }`

#### `GET /university/diplomas` — Список дипломов
- **Auth:** JWT (role=university)
- **Query:** `status?` (pending | verified | revoked)
- **Response:** `{ diplomas: [{ id, full_name, diploma_number, series, degree, specialization, issue_date, status, file_id, student_account_id }] }`

#### `GET /university/diplomas/{diploma_id}` — Детали диплома
- **Auth:** JWT (role=university)
- **Response:** `DiplomaListItem`

#### `POST /university/diplomas/{diploma_id}/verify` — Верификация
- **Auth:** JWT (role=university)
- **Что делает:** подписывает RSA-2048, добавляет в blockchain, генерирует QR-сертификат
- **Response:** `{ diploma_id, status: "verified" }`

#### `POST /university/diplomas/{diploma_id}/revoke` — Отзыв
- **Auth:** JWT (role=university)
- **Response:** `{ diploma_id, status: "revoked" }`

#### `GET /university/public-key` — Публичный RSA-ключ
- **Auth:** Public
- **Response:** `text/plain` (PEM формат)

### Внутренние эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/internal/diplomas/search?full_name=&date_of_birth=` | Поиск дипломов по ФИО и ДР |
| GET | `/internal/diplomas/by-hash/{data_hash}` | Диплом по data_hash |
| GET | `/internal/diplomas/{diploma_id}` | Детали диплома |
| PATCH | `/internal/diplomas/{diploma_id}/status` | Изменение статуса (body: `{ status, moderator_note? }`) |
| PATCH | `/internal/diplomas/{diploma_id}/ai-data` | Обновление AI-данных (body: `{ ai_extracted_data, confidence }`) |
| PATCH | `/internal/diplomas/{diploma_id}/link-student` | Привязка студента (body: `{ student_account_id }`) |

---

## 3. Diploma Service (порт 8003)

Студенческий кабинет и подсказки для работодателя.

#### `GET /student/diplomas` — Дипломы студента
- **Auth:** JWT (role=student)
- **Response:** `{ diplomas: [{ ..., trust_score, certificate_id, antifraud_score, antifraud_verdict, antifraud_warnings }] }`

#### `GET /student/diplomas/{diploma_id}/certificate` — Сертификат
- **Auth:** JWT (role=student)
- **Response:** Сертификат (JSON)

#### `GET /employer/verification-hint` — Подсказка для работодателя
- **Auth:** JWT (role=employer)
- **Response:** `{ role, public_qr, public_manual, note }`

---

## 4. Verify Service (порт 8004)

Публичная проверка дипломов по QR и вручную.

#### `GET /verify/qr/{qr_token}` — Проверка по QR
- **Auth:** Public (rate-limit: 20/мин по IP)
- **Response:**
  ```json
  {
    "valid": true,
    "full_name": "Иванов И.И.",
    "degree": "Бакалавр",
    "specialization": "Информатика",
    "issue_date": "2024-06-30",
    "university_name": "МГУ",
    "signature_verified": true,
    "blockchain_verified": true,
    "blockchain_block": 42,
    "chain_intact": true,
    "timestamp_proof": "..."
  }
  ```

#### `GET /verify/{qr_token}` — Legacy проверка по UUID
- **Auth:** Public
- **Response:** То же, что `/verify/qr/{qr_token}`

#### `POST /verify/manual` — Ручная проверка
- **Auth:** Public (rate-limit: 20/мин по IP)
- **Body:** `{ "diploma_number", "series", "full_name", "issue_date" }`
- **Response:** `VerifyPublicResponse`

#### `GET /verify/history` — История проверок
- **Auth:** JWT
- **Response:** `{ items: [{ id, diploma_id, check_method, result, checked_at }] }`

---

## 5. File Service (порт 8005)

Загрузка и скачивание файлов дипломов.

#### `POST /files/upload` — Загрузка файла
- **Auth:** Internal
- **Body:** `multipart/form-data` — `file`, `uploader_account_id?`
- **Response:** `{ file_id, original_name, size_bytes }`

#### `GET /files/{file_id}` — Скачивание файла
- **Auth:** Public
- **Response:** Файл (binary)

#### `DELETE /files/{file_id}` — Удаление файла
- **Auth:** Internal (`X-Internal-Token` header)
- **Response:** `204 No Content`

---

## 6. Certificate Service (порт 8006)

QR-сертификаты для верифицированных дипломов.

#### `POST /certificates/generate` — Генерация сертификата
- **Auth:** Internal
- **Body:**
  ```json
  {
    "diploma_id": "uuid",
    "diploma_data": {
      "full_name": "...",
      "degree": "...",
      "specialization": "...",
      "issue_date": "...",
      "university_name": "..."
    }
  }
  ```
- **Response:** `{ certificate_id, qr_token, qr_code_base64 }`

#### `GET /certificates/by-token/{qr_token}` — По QR-токену
- **Auth:** Public
- **Response:** `{ certificate_id, certificate_number, diploma_id, qr_token, qr_code_base64, issued_at, is_active }`

#### `GET /certificates/{diploma_id}` — По diploma_id
- **Auth:** Public/Internal
- **Response:** `CertificateOut`

#### `POST /certificates/{diploma_id}/deactivate` — Деактивация
- **Auth:** Internal
- **Response:** `204 No Content`

---

## 7. AI Integration Service (порт 8007)

Извлечение данных из сканов дипломов (ML/OCR).

#### `POST /ai/extract` — Запуск извлечения
- **Auth:** Internal
- **Body:** `{ "file_id", "diploma_id" }`
- **Что делает:** скачивает файл → отправляет на ML-сервер → сохраняет результат в `diplomas.ai_extracted_data`
- **Response:** `{ status: "processing", diploma_id }`

#### `POST /ai/result` — Результат обработки
- **Auth:** Internal
- **Body:**
  ```json
  {
    "diploma_id": "uuid",
    "extracted_data": {
      "full_name": "...",
      "diploma_number": "...",
      "series": "...",
      "degree": "...",
      "specialization": "...",
      "issue_date": "..."
    },
    "confidence": 0.95,
    "raw_text": "...",
    "processing_time_ms": 1200
  }
  ```
- **Авто-верификация:** если `confidence > 0.85` и `status == "pending"` → статус автоматически меняется на `"verified"`
- **Response:** `{ received: true, diploma_id, next_status }`

---

## 8. Notification Service (порт 8008)

Уведомления и аудит-лог.

### Публичные эндпоинты

#### `GET /notifications` — Мои уведомления
- **Auth:** JWT
- **Response:** `{ notifications: [{ id, account_id, type, subject, body, is_read, route?, sent, sent_at?, created_at }] }`

#### `PATCH /notifications/{notification_id}/read` — Прочитать
- **Auth:** JWT
- **Response:** `{ ok: true }`

#### `PATCH /notifications/read-all` — Прочитать все
- **Auth:** JWT
- **Response:** `{ ok: true }`

### Внутренние эндпоинты

#### `POST /internal/send` — Отправка уведомления
- **Body:**
  ```json
  {
    "account_id": "uuid",
    "type": "diploma_uploaded | diploma_verified | diploma_revoked | diploma_checked | welcome",
    "subject": "Заголовок",
    "body": "Текст",
    "route": "/student/diplomas"
  }
  ```
- **Response:** `{ id }`

#### `POST /internal/audit` — Запись в аудит-лог
- **Body:**
  ```json
  {
    "actor_id": "uuid",
    "actor_role": "admin",
    "actor_ip": "192.168.1.1",
    "action": "create | verify | block | ...",
    "resource_type": "diploma | account",
    "resource_id": "uuid",
    "old_value": {},
    "new_value": {},
    "success": true,
    "error_message": null
  }
  ```
- **Response:** `{ id }`

#### `GET /internal/audit` — Список аудит-логов
- **Query:** `actor_id?`, `action?`, `date_from?`, `date_to?`, `page`, `limit`
- **Response:** `{ items, total, page, limit }`

---

## 9. Blockchain Service (порт 8009)

Append-only blockchain для верификации дипломов.

#### `POST /blockchain/add` — Добавить блок
- **Auth:** Internal
- **Body:** `{ "diploma_id": "uuid", "data_hash": "sha256..." }`
- **Response:** `{ block_index, block_hash, nonce }`

#### `GET /blockchain/verify/{diploma_id}` — Проверить блок
- **Auth:** Public
- **Response:** `{ valid, block_index?, block_hash?, timestamp?, chain_intact }`

#### `GET /blockchain/chain` — Цепочка блоков (последние 50)
- **Auth:** Public
- **Response:** `{ blocks: [{ block_index, timestamp, diploma_id, data_hash, previous_hash, block_hash, nonce }] }`

#### `GET /blockchain/validate` — Валидация всей цепочки
- **Auth:** Public
- **Response:** `{ valid, total_blocks, broken_at_index? }`

---

## 10. Admin Service (порт 8010)

Панель администратора. Все эндпоинты (кроме `/admin/setup`) требуют JWT с ролью `admin`.

### Setup

#### `POST /admin/setup` — Создание первого админа
- **Auth:** API-key в теле
- **Body:** `{ "secret_key": "ENV:ADMIN_SECRET", "email", "password" }`
- **Response:** `{ message, account_id }`

### Аккаунты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/admin/accounts?role=&is_blocked=&page=&limit=` | Список аккаунтов |
| GET | `/admin/accounts/stats` | Статистика (`total`, `by_role`, `blocked`, `registered_today/week`) |
| GET | `/admin/accounts/{account_id}` | Детали аккаунта (+ `diplomas[]`) |
| POST | `/admin/accounts/{account_id}/block` | Блокировка |
| POST | `/admin/accounts/{account_id}/unblock` | Разблокировка |

### Дипломы

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/admin/diplomas?status=&university_id=&date_from=&date_to=&page=&limit=` | Список дипломов |
| GET | `/admin/diplomas/stats` | Статистика (`total`, `by_status`, `verified_today/week/month`) |
| GET | `/admin/diplomas/{diploma_id}` | Детали диплома (+ `ai_extracted_data`) |
| POST | `/admin/diplomas/{diploma_id}/force-verify` | Принудительная верификация (body: `{ reason }`) |
| POST | `/admin/diplomas/{diploma_id}/force-revoke` | Принудительный отзыв (body: `{ reason }`) |

### Логи и аудит

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/admin/logs/verifications?diploma_id=&check_method=&result=&date_from=&date_to=&page=&limit=` | Логи проверок |
| GET | `/admin/logs/stats` | Статистика проверок (`total_checks`, `by_method`, `most_checked`) |
| GET | `/admin/audit?actor_id=&action=&date_from=&date_to=&page=&limit=` | Аудит-лог |

---

## 11. Mail Service (порт 8011, внутренний 8000)

SMTP-сервис для отправки email-уведомлений.

#### `GET /ping` — Health check
- **Auth:** Public
- **Response:** `{ status: "ok" }`

#### `POST /send` — Отправка email
- **Auth:** Internal
- **Body:**
  ```json
  {
    "recipients": ["user@example.com"],
    "subject": "Тема",
    "body": "Текст (plain text)",
    "html": "<p>HTML-версия</p>",
    "sender": "noreply@diploma.kz"
  }
  ```
- **Response:** `{ status, message }`

---

## Потоки данных

### Загрузка и верификация диплома

```
1. University → POST /university/diplomas/upload
   ├── file-service: сохранение PDF
   ├── auth-service: регистрация студента (если указан email)
   └── ai-service: запуск OCR-анализа (фоном)

2. University → POST /university/diplomas/{id}/verify
   ├── RSA-2048 подпись data_hash
   ├── blockchain-service: добавление блока
   ├── certificate-service: генерация QR
   └── notification-service: уведомление студенту
```

### Проверка диплома

```
1. Сканирование QR → GET /verify/qr/{token}
   ├── certificate-service: поиск сертификата
   ├── university-service: данные диплома
   ├── Проверка RSA-подписи
   ├── blockchain-service: проверка блока
   └── verification_log: запись результата

2. Ручная проверка → POST /verify/manual
   ├── university-service: поиск по номеру/ФИО
   └── те же проверки подписи и blockchain
```

### AI-обработка

```
1. POST /ai/extract (от university-service)
   ├── Скачивание PDF из file-service
   ├── Отправка на ML-сервер (ML_SERVICE_URL)
   └── Результат → diplomas.ai_extracted_data (прямой доступ к БД)

2. Авто-верификация: confidence > 0.85 → status = "verified"
```

---

## Шифрование трафика

Все HTTP-запросы между фронтендом и бэкендом проходят через **AES-256-GCM payload encryption**:

1. Frontend шифрует JSON-тело → `{ "payload": "<base64>" }`
2. Caddy проксирует зашифрованный запрос
3. Middleware на каждом сервисе расшифровывает `payload`
4. Ответ шифруется обратно тем же ключом

**Ключ:** `PAYLOAD_ENCRYPTION_KEY` (env, общий для всех сервисов)

---

## Health checks

Каждый сервис имеет `GET /health` → `{ status: "ok", service: "<name>" }`
