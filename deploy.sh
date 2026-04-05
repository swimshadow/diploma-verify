#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "══════════════════════════════════════════"
echo "  DiplomaVerify — полный деплой"
echo "══════════════════════════════════════════"

# 1. Сборка фронтенда
echo ""
echo "▶ [1/3] Сборка Flutter web (release)..."
cd frontend
flutter build web --release --no-tree-shake-icons
cd ..

# 2. Копируем .env если нет
if [ ! -f backend/.env ]; then
  echo ""
  echo "▶ [!] backend/.env не найден — копирую .env.example"
  cp backend/.env.example backend/.env
  echo "  ⚠ Не забудь подставить секреты в backend/.env"
fi

# 3. Сборка и запуск docker compose
echo ""
echo "▶ [2/3] Сборка Docker-образов..."
cd backend
docker compose build

echo ""
echo "▶ [3/3] Запуск всех сервисов..."
docker compose up -d

echo ""
echo "══════════════════════════════════════════"
echo "  ✓ Готово! Сайт: http://localhost:8000"
echo "  ✓ Swagger:      http://localhost:8000/docs"
echo "══════════════════════════════════════════"
