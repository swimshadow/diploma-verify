# Запуск демо стенда

1. cp .env.example .env
2. docker compose up -d
3. docker compose --profile demo run demo-seeder
4. Открыть http://localhost:8000

## Тестовые аккаунты:

| Роль        | Email              | Пароль   |
|-------------|-------------------|----------|
| ВУЗ (МГУ)  | mgu@demo.ru       | Demo123! |
| ВУЗ (СПбГУ)| spbgu@demo.ru     | Demo123! |
| Студент     | ivanov@demo.ru    | Demo123! |
| Работодатель| diasoft@demo.ru   | Demo123! |
| Админ       | admin@demo.ru     | Demo123! |

## Готовые QR токены для демо:

(генерируются при запуске seeder, смотри вывод консоли)

## Endpoints для демонстрации:

- Swagger auth: http://localhost:8001/docs
- Swagger university: http://localhost:8002/docs
- Swagger verify: http://localhost:8004/docs
- Swagger admin: http://localhost:8010/docs
- Blockchain audit: http://localhost:8000/api/blockchain/validate

Примечание: Swagger по портам 8001–8010 доступен при пробросе `127.0.0.1:18001` и т.д. в `docker-compose.yml`; через Caddy — агрегатор http://localhost:8000/docs
