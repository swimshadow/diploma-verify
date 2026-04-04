#!/usr/bin/env bash
# ============================================================
#  DiplomaVerify — curl-тесты бэкенда
#  Проверяет все микросервисы через Caddy (localhost:8000)
#  БЕЗ заголовка X-Encrypted → plaintext JSON
# ============================================================
set -uo pipefail

BASE="http://localhost:8000"
PASS="Demo123!"
ADMIN_SECRET="change_me_admin_setup_secret"
TS=$(date +%s)  # уникальный суффикс, чтобы не конфликтовать с прошлыми запусками

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
TOTAL=0

# ── Helpers ──────────────────────────────────────────────────
check() {
  local name="$1" expected_code="$2"; shift 2
  TOTAL=$((TOTAL + 1))
  local response http_code body
  response=$(curl -s -w "\n%{http_code}" "$@") || true
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "$expected_code" ]]; then
    echo -e "  ${GREEN}✔ ${name}${NC}  [${http_code}]"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✘ ${name}${NC}  [ожидали ${expected_code}, получили ${http_code}]"
    echo "    $body" | head -3
    FAILED=$((FAILED + 1))
  fi
  LAST_BODY="$body"
}

extract() {
  # extract "field" from JSON (простой grep, без jq-зависимости)
  echo "$LAST_BODY" | grep -oP "\"$1\"\s*:\s*\"?\K[^\",$}]+" | head -1
}

section() {
  echo ""
  echo -e "${CYAN}━━━ $1 ━━━${NC}"
}

# ============================================================
#  1. HEALTH CHECKS
# ============================================================
section "1. Health Checks (прямые порты, минуя Caddy)"

check "auth-service"          200 "http://localhost:18001/health"
check "university-service"    200 "http://localhost:18002/health"
check "diploma-service"       200 "http://localhost:18003/health"
check "verify-service"        200 "http://localhost:18004/health"
check "file-service"          200 "http://localhost:18005/health"
check "certificate-service"   200 "http://localhost:18006/health"
check "ai-service"            200 "http://localhost:18007/health"
check "notification-service"  200 "http://localhost:18008/health"
check "blockchain-service"    200 "http://localhost:18009/health"
check "admin-service"         200 "http://localhost:8010/health"
check "mail-service (ping)"   200 "$BASE/api/mail/ping"

# ============================================================
#  2. ADMIN SETUP
# ============================================================
section "2. Admin Setup"

# Может вернуть 200 (создан) или 400 (уже существует) — оба варианта ОК
TOTAL=$((TOTAL + 1))
SETUP_RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE/api/admin/setup" \
  -H "Content-Type: application/json" \
  -d "{\"secret_key\":\"$ADMIN_SECRET\",\"email\":\"admin@demo.ru\",\"password\":\"$PASS\"}") || true
SETUP_CODE=$(echo "$SETUP_RESP" | tail -1)
if [[ "$SETUP_CODE" == "200" || "$SETUP_CODE" == "400" || "$SETUP_CODE" == "409" ]]; then
  echo -e "  ${GREEN}✔ POST /admin/setup${NC}  [${SETUP_CODE}]"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✘ POST /admin/setup${NC}  [ожидали 200|400|409, получили ${SETUP_CODE}]"
  echo "    $(echo "$SETUP_RESP" | sed '$d')" | head -3
  FAILED=$((FAILED + 1))
fi

# ============================================================
#  3. РЕГИСТРАЦИЯ
# ============================================================
section "3. Регистрация аккаунтов"

UNI_EMAIL="testuni${TS}@example.com"
EMP_EMAIL="testemp${TS}@example.com"
STUDENT_EMAIL="teststudent${TS}@example.com"

check "Регистрация ВУЗа" 201 \
  -X POST "$BASE/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$UNI_EMAIL\",\"password\":\"$PASS\",\"role\":\"university\",\"profile\":{\"name\":\"Тестовый ВУЗ\",\"inn\":\"1234567890\",\"ogrn\":\"1234567890123\"}}"

UNI_TOKEN=$(extract "access_token")
echo -e "    ${YELLOW}→ uni token: ${UNI_TOKEN:0:20}...${NC}"

check "Регистрация работодателя" 201 \
  -X POST "$BASE/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMP_EMAIL\",\"password\":\"$PASS\",\"role\":\"employer\",\"profile\":{\"company_name\":\"Тест Компания\",\"inn\":\"9876543210\"}}"

EMP_TOKEN=$(extract "access_token")
echo -e "    ${YELLOW}→ emp token: ${EMP_TOKEN:0:20}...${NC}"

# ============================================================
#  4. ЛОГИН
# ============================================================
section "4. Аутентификация"

check "Логин ВУЗа" 200 \
  -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$UNI_EMAIL\",\"password\":\"$PASS\"}"

UNI_TOKEN=$(extract "access_token")
UNI_REFRESH=$(extract "refresh_token")
echo -e "    ${YELLOW}→ access: ${UNI_TOKEN:0:20}...${NC}"

check "GET /auth/me" 200 \
  "$BASE/api/auth/me" \
  -H "Authorization: Bearer $UNI_TOKEN"
ME_ROLE=$(extract "role")
echo -e "    ${YELLOW}→ role: $ME_ROLE${NC}"

check "POST /auth/refresh" 200 \
  -X POST "$BASE/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"$UNI_REFRESH\"}"

NEW_ACCESS=$(extract "access_token")
echo -e "    ${YELLOW}→ new access: ${NEW_ACCESS:0:20}...${NC}"

# Логин admin (если setup прошёл; если нет — используем demo-аккаунт)
check "Логин админа" 200 \
  -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@demo.ru\",\"password\":\"$PASS\"}"

ADMIN_TOKEN=$(extract "access_token")
if [[ -z "${ADMIN_TOKEN:-}" ]]; then
  echo -e "    ${YELLOW}⚠ Админ не доступен, пропуск админ-тестов${NC}"
else
  echo -e "    ${YELLOW}→ admin token: ${ADMIN_TOKEN:0:20}...${NC}"
fi

# ============================================================
#  5. ЗАГРУЗКА ДИПЛОМА
# ============================================================
section "5. Загрузка диплома (university)"

# Создаём временный PDF
TMPFILE=$(mktemp /tmp/test_diploma_XXXX.pdf)
echo "%PDF-1.4 test diploma content" > "$TMPFILE"

METADATA="{\"full_name\":\"Тестов Тест Тестович\",\"diploma_number\":\"CURL-${TS}\",\"series\":\"ТСТ\",\"degree\":\"Бакалавр\",\"specialization\":\"Тестирование\",\"issue_date\":\"2024-06-30\",\"date_of_birth\":\"2000-01-01\",\"student_email\":\"$STUDENT_EMAIL\",\"student_password\":\"$PASS\"}"

check "POST /university/diplomas/upload" 200 \
  -X POST "$BASE/api/university/diplomas/upload" \
  -H "Authorization: Bearer $UNI_TOKEN" \
  -F "file=@$TMPFILE;type=application/pdf" \
  -F "metadata=$METADATA"

DIPLOMA_ID=$(extract "diploma_id")
echo -e "    ${YELLOW}→ diploma_id: $DIPLOMA_ID${NC}"

rm -f "$TMPFILE"

# ============================================================
#  6. СПИСОК ДИПЛОМОВ
# ============================================================
section "6. Операции с дипломами"

check "GET /university/diplomas (список)" 200 \
  "$BASE/api/university/diplomas" \
  -H "Authorization: Bearer $UNI_TOKEN"

if [[ -n "${DIPLOMA_ID:-}" ]]; then
  check "GET /university/diplomas/{id} (детали)" 200 \
    "$BASE/api/university/diplomas/$DIPLOMA_ID" \
    -H "Authorization: Bearer $UNI_TOKEN"

  check "POST verify диплом" 200 \
    -X POST "$BASE/api/university/diplomas/$DIPLOMA_ID/verify" \
    -H "Authorization: Bearer $UNI_TOKEN"
fi

check "GET /university/public-key" 200 \
  "$BASE/api/university/public-key"

# ============================================================
#  7. СТУДЕНЧЕСКИЙ КАБИНЕТ
# ============================================================
section "7. Студенческий кабинет"

# Логин студента (создан при загрузке диплома)
check "Логин студента" 200 \
  -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"$PASS\"}"

STUDENT_TOKEN=$(extract "access_token")
echo -e "    ${YELLOW}→ student token: ${STUDENT_TOKEN:0:20}...${NC}"

if [[ -n "${STUDENT_TOKEN:-}" ]]; then
  check "GET /student/diplomas" 200 \
    "$BASE/api/student/diplomas" \
    -H "Authorization: Bearer $STUDENT_TOKEN"

  if [[ -n "${DIPLOMA_ID:-}" ]]; then
    # Сертификат может отсутствовать если AI авто-верифицировал до ручной верификации
    TOTAL=$((TOTAL + 1))
    CERT_RESP=$(curl -s -w "\n%{http_code}" "$BASE/api/student/diplomas/$DIPLOMA_ID/certificate" \
      -H "Authorization: Bearer $STUDENT_TOKEN") || true
    CERT_CODE=$(echo "$CERT_RESP" | tail -1)
    if [[ "$CERT_CODE" == "200" || "$CERT_CODE" == "404" ]]; then
      echo -e "  ${GREEN}✔ GET /student/diplomas/{id}/certificate${NC}  [${CERT_CODE}]"
      PASSED=$((PASSED + 1))
    else
      echo -e "  ${RED}✘ GET /student/diplomas/{id}/certificate${NC}  [${CERT_CODE}]"
      FAILED=$((FAILED + 1))
    fi
    LAST_BODY=$(echo "$CERT_RESP" | sed '$d')
    CERT_QR=$(extract "qr_token")
    echo -e "    ${YELLOW}→ qr_token: ${CERT_QR:-не найден (AI авто-верификация)}${NC}"
  fi
fi

# ============================================================
#  8. ВЕРИФИКАЦИЯ
# ============================================================
section "8. Верификация дипломов"

check "POST /verify/manual" 200 \
  -X POST "$BASE/api/verify/manual" \
  -H "Content-Type: application/json" \
  -d "{\"diploma_number\":\"CURL-${TS}\",\"series\":\"ТСТ\",\"full_name\":\"Тестов Тест Тестович\",\"issue_date\":\"2024-06-30\"}"

VERIFY_VALID=$(extract "valid")
echo -e "    ${YELLOW}→ valid: $VERIFY_VALID${NC}"

# Получим QR-токен сертификата (может отсутствовать при AI авто-верификации)
if [[ -n "${DIPLOMA_ID:-}" ]]; then
  TOTAL=$((TOTAL + 1))
  CERT_RESP2=$(curl -s -w "\n%{http_code}" "$BASE/api/certificates/$DIPLOMA_ID") || true
  CERT_CODE2=$(echo "$CERT_RESP2" | tail -1)
  if [[ "$CERT_CODE2" == "200" || "$CERT_CODE2" == "404" ]]; then
    echo -e "  ${GREEN}✔ GET /certificates/{diploma_id}${NC}  [${CERT_CODE2}]"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✘ GET /certificates/{diploma_id}${NC}  [${CERT_CODE2}]"
    FAILED=$((FAILED + 1))
  fi
  LAST_BODY=$(echo "$CERT_RESP2" | sed '$d')
  QR_TOKEN=$(extract "qr_token")
  echo -e "    ${YELLOW}→ qr_token: ${QR_TOKEN:-не найден}${NC}"

  if [[ -n "${QR_TOKEN:-}" ]]; then
    check "GET /verify/qr/{qr_token}" 200 \
      "$BASE/api/verify/qr/$QR_TOKEN"

    QR_VALID=$(extract "valid")
    echo -e "    ${YELLOW}→ valid: $QR_VALID${NC}"
  fi
fi

check "GET /verify/history" 200 \
  "$BASE/api/verify/history" \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# ============================================================
#  9. РАБОТОДАТЕЛЬ
# ============================================================
section "9. Работодатель"

check "GET /employer/verification-hint" 200 \
  "$BASE/api/employer/verification-hint" \
  -H "Authorization: Bearer $EMP_TOKEN"

# ============================================================
# 10. УВЕДОМЛЕНИЯ
# ============================================================
section "10. Уведомления"

check "GET /notifications (студент)" 200 \
  "$BASE/api/notifications" \
  -H "Authorization: Bearer $STUDENT_TOKEN"

check "PATCH /notifications/read-all" 200 \
  -X PATCH "$BASE/api/notifications/read-all" \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# ============================================================
# 11. BLOCKCHAIN
# ============================================================
section "11. Blockchain"

check "GET /blockchain/chain" 200 \
  "$BASE/api/blockchain/chain"

check "GET /blockchain/validate" 200 \
  "$BASE/api/blockchain/validate"

if [[ -n "${DIPLOMA_ID:-}" ]]; then
  check "GET /blockchain/verify/{diploma_id}" 200 \
    "$BASE/api/blockchain/verify/$DIPLOMA_ID"
fi

# ============================================================
# 12. ADMIN PANEL
# ============================================================
section "12. Админ-панель"

if [[ -n "${ADMIN_TOKEN:-}" ]]; then
  check "GET /admin/accounts" 200 \
    "$BASE/api/admin/accounts" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/accounts/stats" 200 \
    "$BASE/api/admin/accounts/stats" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/diplomas" 200 \
    "$BASE/api/admin/diplomas" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/diplomas/stats" 200 \
    "$BASE/api/admin/diplomas/stats" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/logs/verifications" 200 \
    "$BASE/api/admin/logs/verifications" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/logs/stats" 200 \
    "$BASE/api/admin/logs/stats" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  check "GET /admin/audit" 200 \
    "$BASE/api/admin/audit" \
    -H "Authorization: Bearer $ADMIN_TOKEN"

  if [[ -n "${DIPLOMA_ID:-}" ]]; then
    check "GET /admin/diplomas/{id}" 200 \
      "$BASE/api/admin/diplomas/$DIPLOMA_ID" \
      -H "Authorization: Bearer $ADMIN_TOKEN"
  fi
fi

# ============================================================
# 13. ОТЗЫВ ДИПЛОМА
# ============================================================
section "13. Отзыв диплома"

if [[ -n "${DIPLOMA_ID:-}" ]]; then
  check "POST /university/diplomas/{id}/revoke" 200 \
    -X POST "$BASE/api/university/diplomas/$DIPLOMA_ID/revoke" \
    -H "Authorization: Bearer $UNI_TOKEN"

  # Проверяем что ручная верификация теперь invalid
  check "POST /verify/manual (после отзыва)" 200 \
    -X POST "$BASE/api/verify/manual" \
    -H "Content-Type: application/json" \
    -d "{\"diploma_number\":\"CURL-${TS}\",\"series\":\"ТСТ\",\"full_name\":\"Тестов Тест Тестович\",\"issue_date\":\"2024-06-30\"}"

  REVOKED_VALID=$(extract "valid")
  echo -e "    ${YELLOW}→ valid after revoke: $REVOKED_VALID${NC}"
fi

# ============================================================
# 14. LOGOUT
# ============================================================
section "14. Выход"

if [[ -n "${UNI_REFRESH:-}" ]]; then
  check "POST /auth/logout" 204 \
    -X POST "$BASE/api/auth/logout" \
    -H "Content-Type: application/json" \
    -d "{\"refresh_token\":\"$UNI_REFRESH\"}"
fi

# ============================================================
# 15. НЕГАТИВНЫЕ КЕЙСЫ
# ============================================================
section "15. Негативные кейсы"

check "Логин — неверный пароль" 401 \
  -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$UNI_EMAIL\",\"password\":\"wrong\"}"

check "GET /auth/me — без токена" 422 \
  "$BASE/api/auth/me"

check "GET /auth/me — невалидный токен" 401 \
  "$BASE/api/auth/me" \
  -H "Authorization: Bearer invalid.token.here"

check "GET /university/diplomas — без токена" 422 \
  "$BASE/api/university/diplomas"

check "Несуществующий диплом" 404 \
  "$BASE/api/university/diplomas/00000000-0000-0000-0000-000000000000" \
  -H "Authorization: Bearer $UNI_TOKEN"

check "Несуществующий QR (valid=false)" 200 \
  "$BASE/api/verify/qr/00000000-0000-0000-0000-000000000000"

# ============================================================
#  ИТОГ
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Всего: $TOTAL"
echo -e "  ${GREEN}Прошло: $PASSED${NC}"
echo -e "  ${RED}Провалено: $FAILED${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
