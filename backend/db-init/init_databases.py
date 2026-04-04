#!/usr/bin/env python3
"""
Автоматическое создание всех баз данных для микросервисов.
Запускается как init-контейнер перед стартом сервисов.
"""

import os
import sys
import time

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
POSTGRES_USER = os.getenv("POSTGRES_USER", "hack")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "hack")
POSTGRES_DB = os.getenv("POSTGRES_DB", "diplomadb")

DATABASES = [
    "authdb",
    "universitydb",
    "verifydb",
    "filedb",
    "certdb",
    "notificationdb",
    "aidb",
]

MAX_RETRIES = 30
RETRY_INTERVAL = 2


def wait_for_postgres():
    """Ждём пока PostgreSQL станет доступен."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            conn = psycopg2.connect(
                host=POSTGRES_HOST,
                port=POSTGRES_PORT,
                user=POSTGRES_USER,
                password=POSTGRES_PASSWORD,
                dbname=POSTGRES_DB,
            )
            conn.close()
            print(f"[db-init] PostgreSQL доступен (попытка {attempt})")
            return
        except psycopg2.OperationalError:
            print(f"[db-init] Ожидание PostgreSQL... ({attempt}/{MAX_RETRIES})")
            time.sleep(RETRY_INTERVAL)

    print("[db-init] ОШИБКА: PostgreSQL не доступен", file=sys.stderr)
    sys.exit(1)


def create_databases():
    """Создаём базы данных, если они ещё не существуют."""
    conn = psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
        dbname=POSTGRES_DB,
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()

    for db_name in DATABASES:
        cur.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s", (db_name,)
        )
        if cur.fetchone() is None:
            cur.execute(f'CREATE DATABASE "{db_name}"')
            print(f"[db-init] Создана БД: {db_name}")
        else:
            print(f"[db-init] БД уже существует: {db_name}")

    cur.close()
    conn.close()
    print("[db-init] Все базы данных готовы")


if __name__ == "__main__":
    wait_for_postgres()
    create_databases()
