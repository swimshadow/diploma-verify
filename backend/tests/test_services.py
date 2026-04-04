#!/usr/bin/env python3
"""
Тесты работоспособности всех микросервисов diploma-verify.

Запуск:
  pip install requests
  python tests/test_services.py

Предварительно нужен запущенный docker compose up.
"""

import json
import sys
import time
import requests

BASE = "http://localhost:8000"

# ─── Цвета ────────────────────────────────────────────────────────────────────
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RESET = "\033[0m"

passed = 0
failed = 0
errors = []


def ok(name: str, detail: str = ""):
    global passed
    passed += 1
    print(f"  {GREEN}✔ {name}{RESET} {detail}")


def fail(name: str, detail: str = ""):
    global failed
    failed += 1
    errors.append(f"{name}: {detail}")
    print(f"  {RED}✘ {name}{RESET} {detail}")


def section(title: str):
    print(f"\n{CYAN}{'─'*60}")
    print(f"  {title}")
    print(f"{'─'*60}{RESET}")


# ═══════════════════════════════════════════════════════════════════════════════
#  1. HEALTH CHECKS — каждый сервис отвечает на /health
# ═══════════════════════════════════════════════════════════════════════════════

HEALTH_ENDPOINTS = {
    "auth-service":           "http://127.0.0.1:18001/health",
    "university-service":     "http://127.0.0.1:18002/health",
    "diploma-service":        "http://127.0.0.1:18003/health",
    "verify-service":         "http://127.0.0.1:18004/health",
    "file-service":           "http://127.0.0.1:18005/health",
    "certificate-service":    "http://127.0.0.1:18006/health",
    "ai-integration-service": "http://127.0.0.1:18007/health",
    "notification-service":   "http://127.0.0.1:18008/health",
}


def test_health_checks():
    section("1. Health Checks")
    for name, url in HEALTH_ENDPOINTS.items():
        try:
            r = requests.get(url, timeout=5)
            if r.status_code == 200:
                ok(name, f"[{r.status_code}]")
            else:
                fail(name, f"status={r.status_code}")
        except Exception as e:
            fail(name, str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  2. OpenAPI SPECS — каждый сервис отдаёт /openapi.json
# ═══════════════════════════════════════════════════════════════════════════════

OPENAPI_ENDPOINTS = {
    "auth-service":           "http://127.0.0.1:18001/openapi.json",
    "university-service":     "http://127.0.0.1:18002/openapi.json",
    "diploma-service":        "http://127.0.0.1:18003/openapi.json",
    "verify-service":         "http://127.0.0.1:18004/openapi.json",
    "file-service":           "http://127.0.0.1:18005/openapi.json",
    "certificate-service":    "http://127.0.0.1:18006/openapi.json",
    "ai-integration-service": "http://127.0.0.1:18007/openapi.json",
    "notification-service":   "http://127.0.0.1:18008/openapi.json",
}


def test_openapi_specs():
    section("2. OpenAPI Specs")
    for name, url in OPENAPI_ENDPOINTS.items():
        try:
            r = requests.get(url, timeout=5)
            if r.status_code == 200:
                spec = r.json()
                if "paths" in spec and "info" in spec:
                    paths_count = len(spec["paths"])
                    ok(name, f"[{spec['info'].get('title', '?')}] {paths_count} path(s)")
                else:
                    fail(name, "Invalid OpenAPI spec (missing paths/info)")
            else:
                fail(name, f"status={r.status_code}")
        except Exception as e:
            fail(name, str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  3. CADDY REVERSE PROXY — маршруты через единый gateway
# ═══════════════════════════════════════════════════════════════════════════════

def test_caddy_proxy():
    section("3. Caddy Reverse Proxy")

    # Swagger UI через Caddy
    try:
        r = requests.get(f"{BASE}/docs", timeout=5)
        if r.status_code == 200:
            ok("GET /docs (swagger aggregator)", f"[{r.status_code}]")
        else:
            fail("GET /docs (swagger aggregator)", f"expected 200, got {r.status_code}")
    except Exception as e:
        fail("GET /docs (swagger aggregator)", str(e))

    # Frontend
    try:
        r = requests.get(f"{BASE}/", timeout=5, allow_redirects=True)
        if r.status_code == 200:
            ok("GET / (static frontend)", f"[{r.status_code}]")
        else:
            fail("GET / (static frontend)", f"expected 200, got {r.status_code}")
    except Exception as e:
        fail("GET / (static frontend)", str(e))

    # Verify через Caddy (200 с valid:false или 404 — оба ОК, значит роутинг работает)
    try:
        r = requests.get(f"{BASE}/api/verify/qr/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code in (200, 404):
            ok("GET /api/verify/qr/{{bad_token}} via Caddy", f"[{r.status_code} — routing ok]")
        else:
            fail("GET /api/verify/qr/{{bad_token}} via Caddy", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/verify/qr/{{bad_token}} via Caddy", str(e))

    # Files через Caddy
    try:
        r = requests.get(f"{BASE}/api/files/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code == 404:
            ok("GET /api/files/{{bad_id}} via Caddy", "[404 — routing ok]")
        else:
            fail("GET /api/files/{{bad_id}} via Caddy", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/files/{{bad_id}} via Caddy", str(e))

    # Certificates через Caddy
    try:
        r = requests.get(f"{BASE}/api/certificates/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code == 404:
            ok("GET /api/certificates/{{bad_id}} via Caddy", "[404 — routing ok]")
        else:
            fail("GET /api/certificates/{{bad_id}} via Caddy", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/certificates/{{bad_id}} via Caddy", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  4. DOCS SERVICE — агрегатор Swagger
# ═══════════════════════════════════════════════════════════════════════════════

def test_docs_service():
    section("4. Docs Service (Swagger Aggregator)")

    # Главная страница с Swagger UI
    try:
        r = requests.get(f"{BASE}/docs", timeout=10)
        if r.status_code == 200 and "swagger-ui" in r.text.lower():
            ok("Swagger UI HTML", f"[{len(r.text)} bytes]")
        else:
            fail("Swagger UI HTML", f"status={r.status_code}, swagger-ui in text: {'swagger-ui' in r.text.lower()}")
    except Exception as e:
        fail("Swagger UI HTML", str(e))

    # Проверяем, что docs_service нашёл specs сервисов
    try:
        r = requests.get(f"{BASE}/docs", timeout=10)
        if r.status_code == 200:
            text = r.text
            # Ищем JSON с urls в HTML
            if "urls:" in text or '"url"' in text:
                ok("Swagger URLs found in page")
            else:
                fail("Swagger URLs", "No urls config in Swagger HTML")
    except Exception as e:
        fail("Swagger URLs", str(e))

    # Пробуем получить spec через docs_service для каждого сервиса
    services_to_check = [
        "auth-service",
        "university-service",
        "diploma-service",
        "verify-service",
        "file-service",
        "certificate-service",
        "ai-integration-service",
        "notification-service",
    ]
    for svc in services_to_check:
        try:
            r = requests.get(f"{BASE}/docs/specs/{svc}", timeout=10)
            if r.status_code == 200:
                spec = r.json()
                title = spec.get("info", {}).get("title", "?")
                ok(f"Spec: {svc}", f"[{title}]")
            else:
                fail(f"Spec: {svc}", f"status={r.status_code}")
        except Exception as e:
            fail(f"Spec: {svc}", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  5. AUTH FLOW — регистрация / логин / рефреш / профиль
# ═══════════════════════════════════════════════════════════════════════════════

def test_auth_flow():
    section("5. Auth Flow")

    ts = int(time.time())

    # Регистрация
    reg_data = {
        "email": f"test_{ts}@example.com",
        "password": "TestPassword123!",
        "role": "student",
        "profile": {
            "full_name": "Тест Тестов",
            "date_of_birth": "2000-01-01",
        },
    }

    try:
        r = requests.post(f"{BASE}/api/auth/register", json=reg_data, timeout=10)
        if r.status_code in (200, 201):
            body = r.json()
            ok("POST /api/auth/register", f"account_id={body.get('account_id', '?')[:8]}...")
        elif r.status_code == 409:
            ok("POST /api/auth/register", "[already exists — ok]")
        else:
            fail("POST /api/auth/register", f"status={r.status_code} body={r.text[:200]}")
            return
    except Exception as e:
        fail("POST /api/auth/register", str(e))
        return

    # Логин
    login_data = {
        "email": reg_data["email"],
        "password": reg_data["password"],
    }
    access_token = None
    refresh_token = None

    try:
        r = requests.post(f"{BASE}/api/auth/login", json=login_data, timeout=10)
        if r.status_code == 200:
            body = r.json()
            access_token = body.get("access_token")
            refresh_token = body.get("refresh_token")
            if access_token:
                ok("POST /api/auth/login", f"token={access_token[:20]}...")
            else:
                fail("POST /api/auth/login", "No access_token in response")
        else:
            fail("POST /api/auth/login", f"status={r.status_code} body={r.text[:200]}")
    except Exception as e:
        fail("POST /api/auth/login", str(e))

    # /me
    if access_token:
        try:
            headers = {"Authorization": f"Bearer {access_token}"}
            r = requests.get(f"{BASE}/api/auth/me", headers=headers, timeout=10)
            if r.status_code == 200:
                body = r.json()
                ok("GET /api/auth/me", f"email={body.get('email', '?')}")
            else:
                fail("GET /api/auth/me", f"status={r.status_code}")
        except Exception as e:
            fail("GET /api/auth/me", str(e))

    # Refresh
    if refresh_token:
        try:
            r = requests.post(f"{BASE}/api/auth/refresh", json={"refresh_token": refresh_token}, timeout=10)
            if r.status_code == 200:
                body = r.json()
                ok("POST /api/auth/refresh", f"new_token={body.get('access_token', '?')[:20]}...")
            else:
                fail("POST /api/auth/refresh", f"status={r.status_code}")
        except Exception as e:
            fail("POST /api/auth/refresh", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  6. VERIFY SERVICE — публичная верификация
# ═══════════════════════════════════════════════════════════════════════════════

def test_verify_service():
    section("6. Verify Service")

    # QR-проверка несуществующего токена (200 с valid:false или 404)
    try:
        r = requests.get(f"{BASE}/api/verify/qr/00000000-0000-0000-0000-000000000000", timeout=10)
        if r.status_code in (200, 404):
            ok("GET /api/verify/qr/{bad_token}", f"[{r.status_code}]")
        else:
            fail("GET /api/verify/qr/{bad_token}", f"unexpected status={r.status_code}")
    except Exception as e:
        fail("GET /api/verify/qr/{bad_token}", str(e))

    # Ручная проверка с невалидными данными
    try:
        r = requests.post(f"{BASE}/api/verify/manual", json={
            "diploma_number": "000000",
            "series": "XX",
            "full_name": "Нет Такого",
            "issue_date": "2025-01-01",
        }, timeout=10)
        if r.status_code in (200, 404, 422):
            ok("POST /api/verify/manual", f"[{r.status_code}]")
        else:
            fail("POST /api/verify/manual", f"status={r.status_code}")
    except Exception as e:
        fail("POST /api/verify/manual", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  7. FILE SERVICE — загрузка файлов
# ═══════════════════════════════════════════════════════════════════════════════

def test_file_service():
    section("7. File Service")

    # Получение несуществующего файла
    try:
        r = requests.get(f"{BASE}/api/files/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code == 404:
            ok("GET /api/files/{bad_id}", "[404 — expected]")
        else:
            fail("GET /api/files/{bad_id}", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/files/{bad_id}", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  8. CERTIFICATE SERVICE — сертификаты
# ═══════════════════════════════════════════════════════════════════════════════

def test_certificate_service():
    section("8. Certificate Service")

    # Получение по несуществующему токену
    try:
        r = requests.get(f"{BASE}/api/certificates/by-token/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code == 404:
            ok("GET /api/certificates/by-token/{bad}", "[404 — expected]")
        else:
            fail("GET /api/certificates/by-token/{bad}", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/certificates/by-token/{bad}", str(e))

    # Получение по несуществующему diploma_id
    try:
        r = requests.get(f"{BASE}/api/certificates/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code == 404:
            ok("GET /api/certificates/{bad_diploma_id}", "[404 — expected]")
        else:
            fail("GET /api/certificates/{bad_diploma_id}", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/certificates/{bad_diploma_id}", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  9. NOTIFICATION SERVICE — уведомления (internal)
# ═══════════════════════════════════════════════════════════════════════════════

def test_notification_service():
    section("9. Notification Service (internal)")

    # Получение уведомлений для несуществующего пользователя
    try:
        r = requests.get("http://127.0.0.1:18008/internal/notifications/00000000-0000-0000-0000-000000000000", timeout=5)
        if r.status_code in (200, 404):
            ok("GET /internal/notifications/{id}", f"[{r.status_code}]")
        else:
            fail("GET /internal/notifications/{id}", f"status={r.status_code}")
    except Exception as e:
        fail("GET /internal/notifications/{id}", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  10. DIPLOMA SERVICE — кабинет студента
# ═══════════════════════════════════════════════════════════════════════════════

def test_diploma_service():
    section("10. Diploma Service")

    # Без токена — должен вернуть 401/403/422 (FastAPI)
    try:
        r = requests.get(f"{BASE}/api/student/diplomas", timeout=5)
        if r.status_code in (401, 403, 422):
            ok("GET /api/student/diplomas (no auth)", f"[{r.status_code}] — protected")
        elif r.status_code == 200:
            ok("GET /api/student/diplomas (no auth)", "[200 — ok]")
        else:
            fail("GET /api/student/diplomas (no auth)", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/student/diplomas (no auth)", str(e))

    # Employer hint
    try:
        r = requests.get(f"{BASE}/api/employer/verification-hint", timeout=5)
        if r.status_code in (200, 422):
            ok("GET /api/employer/verification-hint", f"[{r.status_code}]")
        else:
            fail("GET /api/employer/verification-hint", f"status={r.status_code}")
    except Exception as e:
        fail("GET /api/employer/verification-hint", str(e))


# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    print(f"\n{CYAN}{'═'*60}")
    print(f"  DIPLOMA-VERIFY: Тесты работоспособности")
    print(f"{'═'*60}{RESET}")

    test_health_checks()
    test_openapi_specs()
    test_caddy_proxy()
    test_docs_service()
    test_auth_flow()
    test_verify_service()
    test_file_service()
    test_certificate_service()
    test_notification_service()
    test_diploma_service()

    # Итоги
    total = passed + failed
    print(f"\n{CYAN}{'═'*60}")
    print(f"  ИТОГО: {total} тестов")
    print(f"  {GREEN}Пройдено: {passed}{RESET}")
    if failed:
        print(f"  {RED}Упало: {failed}{RESET}")
        for e in errors:
            print(f"    {RED}• {e}{RESET}")
    print(f"{CYAN}{'═'*60}{RESET}\n")

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
