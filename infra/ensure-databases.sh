#!/usr/bin/env bash
# Однократно создаёт недостающие БД в уже существующем томе Postgres (compose уже запущен).
# Использование: из корня репозитория: ./infra/ensure-databases.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

USER="${POSTGRES_USER:-hack}"
DB="${POSTGRES_DB:-diplomadb}"

create_if_missing() {
  local name="$1"
  if docker compose exec -T postgres psql -U "$USER" -d "$DB" -tc "SELECT 1 FROM pg_database WHERE datname = '$name'" | grep -q 1; then
    echo "OK: $name"
  else
    echo "Creating $name..."
    docker compose exec -T postgres psql -U "$USER" -d "$DB" -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$name\";"
  fi
}

for name in authdb universitydb verifydb filedb certdb notificationdb; do
  create_if_missing "$name"
done
echo "Done. Перезапустите сервисы: docker compose up -d"
