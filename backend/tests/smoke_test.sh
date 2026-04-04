#!/usr/bin/env bash
# Быстрый smoke-тест всех сервисов. Без зависимостей — только curl.
# Запуск: bash tests/smoke_test.sh

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
ERRORS=()

check() {
    local name="$1" url="$2" expected="${3:-200}"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
    if [[ "$code" == "$expected" ]]; then
        echo -e "  ${GREEN}✔${NC} $name [${code}]"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✘${NC} $name [expected ${expected}, got ${code}]"
        FAIL=$((FAIL + 1))
        ERRORS+=("$name: expected $expected, got $code")
    fi
}

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════"
echo -e "  DIPLOMA-VERIFY SMOKE TEST"
echo -e "══════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}── Health Checks (direct) ──${NC}"
check "auth-service"           "http://127.0.0.1:18001/health"
check "university-service"     "http://127.0.0.1:18002/health"
check "diploma-service"        "http://127.0.0.1:18003/health"
check "verify-service"         "http://127.0.0.1:18004/health"
check "file-service"           "http://127.0.0.1:18005/health"
check "certificate-service"    "http://127.0.0.1:18006/health"
check "ai-integration-service" "http://127.0.0.1:18007/health"
check "notification-service"   "http://127.0.0.1:18008/health"

echo -e "\n${CYAN}── OpenAPI Specs ──${NC}"
check "auth-service openapi"           "http://127.0.0.1:18001/openapi.json"
check "university-service openapi"     "http://127.0.0.1:18002/openapi.json"
check "diploma-service openapi"        "http://127.0.0.1:18003/openapi.json"
check "verify-service openapi"         "http://127.0.0.1:18004/openapi.json"
check "file-service openapi"           "http://127.0.0.1:18005/openapi.json"
check "certificate-service openapi"    "http://127.0.0.1:18006/openapi.json"
check "ai-integration-service openapi" "http://127.0.0.1:18007/openapi.json"
check "notification-service openapi"   "http://127.0.0.1:18008/openapi.json"

echo -e "\n${CYAN}── Caddy Proxy Routes ──${NC}"
check "Swagger UI (/docs)"       "http://localhost:8000/docs"
check "Frontend (/)"             "http://localhost:8000/"
# Verify-service имеет роуты /verify/* (совпадает с путём Caddy)
check "verify via caddy"         "http://localhost:8000/api/verify/qr/00000000-0000-0000-0000-000000000000"
check "verify shortcut"          "http://localhost:8000/verify/qr/00000000-0000-0000-0000-000000000000"
# Files/Certificates через Caddy (ожидаем 404 для несуществующих ID)
check "files via caddy"          "http://localhost:8000/api/files/00000000-0000-0000-0000-000000000000"      "404"
check "certificates via caddy"   "http://localhost:8000/api/certificates/00000000-0000-0000-0000-000000000000" "404"

echo -e "\n${CYAN}── Docs Aggregator Specs ──${NC}"
check "docs/specs/auth-service"           "http://localhost:8000/docs/specs/auth-service"
check "docs/specs/university-service"     "http://localhost:8000/docs/specs/university-service"
check "docs/specs/diploma-service"        "http://localhost:8000/docs/specs/diploma-service"
check "docs/specs/verify-service"         "http://localhost:8000/docs/specs/verify-service"
check "docs/specs/file-service"           "http://localhost:8000/docs/specs/file-service"
check "docs/specs/certificate-service"    "http://localhost:8000/docs/specs/certificate-service"
check "docs/specs/ai-integration-service" "http://localhost:8000/docs/specs/ai-integration-service"
check "docs/specs/notification-service"   "http://localhost:8000/docs/specs/notification-service"

TOTAL=$((PASS + FAIL))
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════"
echo -e "  ИТОГО: ${TOTAL} тестов"
echo -e "  ${GREEN}Пройдено: ${PASS}${NC}"
if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${RED}Упало: ${FAIL}${NC}"
    for err in "${ERRORS[@]}"; do
        echo -e "    ${RED}• ${err}${NC}"
    done
fi
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

exit $FAIL
