#!/usr/bin/env bash
# Создаёт отдельные БД для сервисов. Идемпотентно (без ошибки, если БД уже есть).
# Вызывается образом postgres только при первом создании тома данных.
set -euo pipefail

create_if_missing() {
  local db="$1"
  if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1; then
    echo "postgres init: database \"$db\" already exists, skip"
  else
    echo "postgres init: creating database \"$db\""
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$db\";"
  fi
}

for db in authdb universitydb verifydb filedb certdb notificationdb; do
  create_if_missing "$db"
done
