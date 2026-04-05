#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "══════════════════════════════════════════"
echo "  DiplomaVerify — полный деплой"
echo "══════════════════════════════════════════"

# 1. Сборка фронтенда
echo ""
echo "▶ [1/4] Сборка Flutter web (release)..."
cd frontend
flutter build web --release --no-tree-shake-icons
cd ..

# 2. Копирование сборки в release/
echo ""
echo "▶ [2/4] Копирование сборки в release/..."
rm -rf release
cp -r frontend/build/web release
echo "  ✓ Сборка скопирована в ./release/"

# 2. Копируем .env если нет
if [ ! -f backend/.env ]; then
  echo ""
  echo "▶ [!] backend/.env не найден — копирую .env.example"
  cp backend/.env.example backend/.env
  echo "  ⚠ Не забудь подставить секреты в backend/.env"
fi

# 3. Сборка и запуск docker compose
echo ""
echo "▶ [3/4] Сборка Docker-образов..."
cd backend
docker compose build

echo ""
echo "▶ [4/4] Запуск всех сервисов..."
docker compose up -d

LOCAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "══════════════════════════════════════════"
echo "  ✓ Готово!"
echo "  ✓ Локально:     http://localhost:8000"
echo "  ✓ По сети:      http://${LOCAL_IP}:8000"
echo "  ✓ Swagger:      http://localhost:8000/docs"
echo "  ✓ Release:      ./release/"
echo "══════════════════════════════════════════"
