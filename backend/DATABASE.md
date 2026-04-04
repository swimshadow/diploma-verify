# База данных — DiplomaVerify

Все таблицы хранятся в **единой PostgreSQL базе `diplomadb`**.  
Подключение: `postgresql://hack:hack@postgres:5432/diplomadb`

---

## Схема таблиц

### `accounts` — Аккаунты пользователей
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | Уникальный ID аккаунта |
| `email` | VARCHAR(320), UNIQUE | ✗ | Email (логин) |
| `password_hash` | TEXT | ✗ | bcrypt-хеш пароля |
| `role` | VARCHAR(32) | ✗ | Роль: `student`, `university`, `employer`, `admin` |
| `is_verified` | BOOLEAN | ✗ | Email подтверждён |
| `is_blocked` | BOOLEAN | ✗ | Аккаунт заблокирован |
| `created_at` | TIMESTAMPTZ | ✗ | Дата создания (default: NOW()) |

**Constraint:** `role IN ('university','student','employer','admin')`

---

### `university_profiles` — Профили ВУЗов
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID профиля |
| `account_id` | UUID (FK → accounts.id) | ✗ | Связь с аккаунтом |
| `name` | TEXT | ✗ | Название ВУЗа |
| `inn` | VARCHAR(32) | ✗ | ИНН |
| `ogrn` | VARCHAR(32) | ✗ | ОГРН |
| `api_key_hash` | TEXT | ✓ | Хеш API-ключа |

---

### `student_profiles` — Профили студентов
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID профиля |
| `account_id` | UUID (FK → accounts.id) | ✗ | Связь с аккаунтом |
| `full_name` | TEXT | ✗ | ФИО студента |
| `date_of_birth` | DATE | ✗ | Дата рождения |

---

### `employer_profiles` — Профили работодателей
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID профиля |
| `account_id` | UUID (FK → accounts.id) | ✗ | Связь с аккаунтом |
| `company_name` | TEXT | ✗ | Название компании |
| `inn` | VARCHAR(32) | ✗ | ИНН |

---

### `refresh_tokens` — Refresh-токены
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID токена |
| `account_id` | UUID (FK → accounts.id) | ✗ | Владелец токена |
| `token_hash` | VARCHAR(128) | ✗ | SHA-256 хеш токена |
| `expires_at` | TIMESTAMPTZ | ✗ | Срок истечения |
| `is_revoked` | BOOLEAN | ✗ | Отозван ли |

---

### `ecp_keys` — ЭЦП-ключи пользователей
> Владелец: **auth-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID ключа |
| `account_id` | UUID (FK → accounts.id) | ✗ | Владелец |
| `key_name` | VARCHAR(200) | ✗ | Название ключа |
| `public_key_pem` | TEXT | ✗ | Публичный ключ (PEM) |
| `algorithm` | VARCHAR(20) | ✗ | Алгоритм (default: RS256) |
| `fingerprint` | VARCHAR(100), UNIQUE | ✗ | Отпечаток ключа |
| `is_active` | BOOLEAN | ✗ | Активен ли |
| `created_at` | TIMESTAMPTZ | ✗ | Дата создания |
| `last_used_at` | TIMESTAMPTZ | ✓ | Последнее использование |
| `expires_at` | TIMESTAMPTZ | ✓ | Срок действия |

---

### `diplomas` — Дипломы
> Владелец: **university-service** · Читает: **ai-integration-service**, **admin-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID диплома |
| `university_account_id` | UUID | ✗ | Аккаунт ВУЗа-загрузчика |
| `file_id` | UUID | ✓ | Ссылка на файл в files |
| `status` | VARCHAR(32) | ✗ | `pending`, `verified`, `revoked` |
| `full_name` | TEXT | ✓ | ФИО (открытое, если шифрование выключено) |
| `full_name_encrypted` | TEXT | ✓ | ФИО зашифрованное (Fernet) |
| `full_name_hash` | VARCHAR(64) | ✓ | SHA-256 хеш ФИО для поиска |
| `diploma_number` | TEXT | ✗ | Номер диплома |
| `series` | TEXT | ✓ | Серия диплома |
| `degree` | TEXT | ✗ | Степень: Бакалавр / Магистр / и т.д. |
| `specialization` | TEXT | ✗ | Специальность |
| `issue_date` | DATE | ✗ | Дата выдачи |
| `date_of_birth` | DATE | ✓ | Дата рождения выпускника |
| `university_name` | TEXT | ✗ | Название ВУЗа |
| `data_hash` | VARCHAR(64) | ✗ | SHA-256 хеш всех полей |
| `digital_signature` | TEXT | ✓ | RSA-2048 подпись (Base64) |
| `signed_at` | TIMESTAMPTZ | ✓ | Дата подписания |
| `timestamp_hash` | TEXT | ✓ | Хеш временной метки |
| `student_account_id` | UUID | ✓ | Привязанный аккаунт студента |
| `ai_extracted_data` | JSONB | ✓ | Данные OCR/AI-анализа |
| `ai_confidence` | FLOAT | ✓ | Уверенность AI (0.0–1.0) |
| `blockchain_block_index` | INTEGER | ✓ | Индекс блока в блокчейне |
| `moderator_note` | TEXT | ✓ | Заметка модератора |
| `created_at` | TIMESTAMPTZ | ✗ | Дата создания записи |

---

### `files` — Загруженные файлы
> Владелец: **file-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID файла |
| `original_name` | TEXT | ✗ | Оригинальное имя файла |
| `stored_path` | TEXT | ✗ | Путь хранения на диске |
| `mime_type` | VARCHAR(255) | ✓ | MIME-тип (application/pdf и т.д.) |
| `size_bytes` | BIGINT | ✗ | Размер в байтах |
| `uploader_account_id` | UUID | ✓ | Кто загрузил |
| `created_at` | TIMESTAMPTZ | ✗ | Дата загрузки |

---

### `certificates` — QR-сертификаты
> Владелец: **certificate-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID сертификата |
| `certificate_number` | VARCHAR(20), UNIQUE | ✓ | Номер сертификата (CERT-...) |
| `diploma_id` | UUID, UNIQUE | ✗ | Привязка к диплому |
| `qr_token` | UUID, UNIQUE | ✗ | Токен для QR-кода |
| `qr_code_base64` | TEXT | ✗ | QR-код (Base64 PNG) |
| `issued_at` | TIMESTAMPTZ | ✗ | Дата выдачи |
| `is_active` | BOOLEAN | ✗ | Активен ли сертификат |

---

### `verification_log` — Логи верификаций
> Владелец: **verify-service** · Читает: **admin-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | INTEGER (PK, autoincrement) | ✗ | ID записи |
| `diploma_id` | UUID | ✓ | Проверяемый диплом |
| `checker_account_id` | UUID | ✓ | Кто проверял (NULL для анонимных) |
| `check_method` | VARCHAR(64) | ✗ | Метод: `qr`, `manual`, `ai` |
| `result` | BOOLEAN | ✗ | Результат проверки |
| `checked_at` | TIMESTAMPTZ | ✗ | Дата проверки |

---

### `notifications` — Уведомления
> Владелец: **notification-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID уведомления |
| `account_id` | UUID | ✗ | Получатель |
| `type` | VARCHAR(64) | ✗ | Тип: `diploma_uploaded`, `diploma_verified`, и т.д. |
| `subject` | VARCHAR(500) | ✗ | Заголовок |
| `body` | TEXT | ✗ | Текст уведомления |
| `is_read` | BOOLEAN | ✗ | Прочитано ли |
| `route` | VARCHAR(500) | ✓ | Путь навигации (GoRouter) |
| `sent` | BOOLEAN | ✗ | Отправлено ли по email |
| `sent_at` | TIMESTAMPTZ | ✓ | Дата отправки email |
| `created_at` | TIMESTAMPTZ | ✗ | Дата создания |

---

### `audit.audit_log` — Аудит-лог (schema: `audit`)
> Владелец: **notification-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID (PK) | ✗ | ID записи |
| `timestamp` | TIMESTAMPTZ | ✗ | Время события |
| `actor_id` | UUID | ✓ | Кто выполнил действие |
| `actor_role` | VARCHAR(64) | ✓ | Роль (admin/university/...) |
| `actor_ip` | VARCHAR(64) | ✓ | IP-адрес |
| `action` | VARCHAR(128) | ✗ | Действие (`create`, `verify`, `block`, ...) |
| `resource_type` | VARCHAR(64) | ✓ | Тип ресурса (`diploma`, `account`, ...) |
| `resource_id` | UUID | ✓ | ID ресурса |
| `old_value` | JSONB | ✓ | Предыдущее состояние |
| `new_value` | JSONB | ✓ | Новое состояние |
| `success` | BOOLEAN | ✗ | Успешно ли |
| `error_message` | TEXT | ✓ | Сообщение об ошибке |

---

### `ml_processing_log` — Логи AI-обработки
> Владелец: **ai-integration-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | INTEGER (PK, autoincrement) | ✗ | ID записи |
| `diploma_id` | UUID | ✗ | Обработанный диплом |
| `confidence` | FLOAT | ✓ | Уверенность AI (0.0–1.0) |
| `processing_time_ms` | INTEGER | ✓ | Время обработки (мс) |
| `auto_verified` | BOOLEAN | ✗ | Авто-верификация |
| `created_at` | TIMESTAMPTZ | ✗ | Дата обработки |

---

### `blockchain_records` — Блокчейн-реестр
> Владелец: **blockchain-service**

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | INTEGER (PK, autoincrement) | ✗ | ID записи |
| `block_index` | INTEGER, UNIQUE | ✗ | Индекс блока в цепочке |
| `timestamp` | VARCHAR(50) | ✗ | Временная метка блока |
| `diploma_id` | UUID | ✗ | ID диплома |
| `data_hash` | VARCHAR(255) | ✗ | Хеш данных диплома |
| `previous_hash` | VARCHAR(255) | ✗ | Хеш предыдущего блока |
| `block_hash` | VARCHAR(255), UNIQUE | ✗ | Хеш текущего блока |
| `nonce` | INTEGER | ✗ | Nonce (proof-of-work) |

---

## ER-диаграмма (связи)

```
accounts ─┬─── university_profiles  (1:1)
           ├─── student_profiles     (1:1)
           ├─── employer_profiles    (1:1)
           ├─── refresh_tokens       (1:N)
           └─── ecp_keys             (1:N)

diplomas ──┬─── files                (N:1 через file_id)
            ├─── certificates        (1:1 через diploma_id)
            ├─── blockchain_records  (1:1 через diploma_id)
            ├─── ml_processing_log   (1:N через diploma_id)
            ├─── verification_log    (1:N через diploma_id)
            └─── accounts            (N:1 через university_account_id, student_account_id)

notifications ──── accounts          (N:1 через account_id)
```

---

## Инфраструктура

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| PostgreSQL | 16-alpine | Единая БД `diplomadb` |
| Redis | 7-alpine | Сессии, rate-limiting, кэш |
| SQLAlchemy | 2.x | ORM для всех сервисов |

## Шифрование полей

| Поле | Метод | Ключ (ENV) |
|------|-------|-----------|
| `diplomas.full_name_encrypted` | Fernet (AES-128-CBC) | `ENCRYPTION_KEY` |
| `diplomas.full_name_hash` | SHA-256 + salt | `SECRET_SALT` |
| `diplomas.digital_signature` | RSA-2048 SHA-256 | `/keys/private.pem` (auto-gen) |
| `accounts.password_hash` | bcrypt (10 rounds) | — |
| HTTP payload | AES-256-GCM | `PAYLOAD_ENCRYPTION_KEY` |
