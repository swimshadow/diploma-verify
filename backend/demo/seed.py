#!/usr/bin/env python3
"""
Запуск: docker compose --profile demo run demo-seeder
Создаёт демо-аккаунты и дипломы через публичный API (Caddy).
"""
import asyncio
import io
import json
import os
from datetime import date

import httpx
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000").rstrip("/")

DEMO_ACCOUNTS = [
    {
        "email": "mgu@demo.ru",
        "password": "Demo123!",
        "role": "university",
        "profile": {"name": "МГУ им. Ломоносова", "inn": "7701234567", "ogrn": "1027700132195"},
    },
    {
        "email": "spbgu@demo.ru",
        "password": "Demo123!",
        "role": "university",
        "profile": {"name": "СПбГУ", "inn": "7801234567", "ogrn": "1027801234567"},
    },
    {
        "email": "ivanov@demo.ru",
        "password": "Demo123!",
        "role": "student",
        "profile": {"full_name": "Иванов Иван Иванович", "date_of_birth": "2000-06-15"},
    },
    {
        "email": "petrova@demo.ru",
        "password": "Demo123!",
        "role": "student",
        "profile": {"full_name": "Петрова Анна Сергеевна", "date_of_birth": "2001-03-22"},
    },
    {
        "email": "diasoft@demo.ru",
        "password": "Demo123!",
        "role": "employer",
        "profile": {"company_name": "Diasoft", "inn": "7702123456"},
    },
    {
        "email": "sber@demo.ru",
        "password": "Demo123!",
        "role": "employer",
        "profile": {"company_name": "Сбербанк", "inn": "7707083893"},
    },
    {
        "email": "admin@demo.ru",
        "password": "Demo123!",
        "role": "admin",
        "profile": {},
    },
]

DEMO_DIPLOMAS = [
    {
        "university_email": "mgu@demo.ru",
        "full_name": "Иванов Иван Иванович",
        "diploma_number": "МГУ-2024-001",
        "series": "АА",
        "degree": "Бакалавр",
        "specialization": "Информационная безопасность",
        "issue_date": "2024-06-25",
        "date_of_birth": "2000-06-15",
        "auto_verify": True,
    },
    {
        "university_email": "mgu@demo.ru",
        "full_name": "Петрова Анна Сергеевна",
        "diploma_number": "МГУ-2024-002",
        "series": "АА",
        "degree": "Магистр",
        "specialization": "Финансовые технологии",
        "issue_date": "2024-06-25",
        "date_of_birth": "2001-03-22",
        "auto_verify": True,
    },
    {
        "university_email": "spbgu@demo.ru",
        "full_name": "Сидоров Пётр Алексеевич",
        "diploma_number": "СПБ-2024-001",
        "series": "ББ",
        "degree": "Бакалавр",
        "specialization": "Программная инженерия",
        "issue_date": "2024-07-01",
        "date_of_birth": "1999-11-10",
        "auto_verify": False,
    },
]


def _make_pdf_bytes(title: str) -> bytes:
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=letter)
    c.drawString(100, 750, title)
    c.showPage()
    c.save()
    buf.seek(0)
    return buf.read()


async def main() -> None:
    tokens: dict[str, str] = {}
    diploma_ids: dict[str, str] = {}
    qr_tokens: list[str] = []

    async with httpx.AsyncClient(timeout=120.0, base_url=API_BASE_URL) as client:
        setup_key = os.getenv("ADMIN_SETUP_KEY", "change_me_admin_setup_secret")
        sr = await client.post(
            "/api/admin/setup",
            json={
                "secret_key": setup_key,
                "email": "admin@demo.ru",
                "password": "Demo123!",
            },
        )
        if sr.status_code not in (200, 201, 409, 403):
            print(f"Admin setup: {sr.status_code} {sr.text}")

        for acc in DEMO_ACCOUNTS:
            if acc["role"] == "admin":
                continue
            r = await client.post(
                "/api/auth/register",
                json={
                    "email": acc["email"],
                    "password": acc["password"],
                    "role": acc["role"],
                    "profile": acc["profile"],
                },
            )
            if r.status_code not in (200, 201):
                lr = await client.post(
                    "/api/auth/login",
                    json={"email": acc["email"], "password": acc["password"]},
                )
                if lr.status_code != 200:
                    print(f"Skip register/login {acc['email']}: {r.status_code} {r.text}")
                    continue
                tokens[acc["email"]] = lr.json()["access_token"]
            else:
                tokens[acc["email"]] = r.json()["access_token"]

        if "admin@demo.ru" not in tokens:
            ar = await client.post(
                "/api/auth/login",
                json={"email": "admin@demo.ru", "password": "Demo123!"},
            )
            if ar.status_code == 200:
                tokens["admin@demo.ru"] = ar.json()["access_token"]

        for dip in DEMO_DIPLOMAS:
            uni_email = dip["university_email"]
            tok = tokens.get(uni_email)
            if not tok:
                print(f"No token for {uni_email}")
                continue
            meta = {
                "full_name": dip["full_name"],
                "diploma_number": dip["diploma_number"],
                "series": dip["series"],
                "degree": dip["degree"],
                "specialization": dip["specialization"],
                "issue_date": dip["issue_date"],
                "date_of_birth": dip["date_of_birth"],
            }
            pdf = _make_pdf_bytes(f"Diploma {dip['diploma_number']}")
            files = {"file": ("demo.pdf", pdf, "application/pdf")}
            data = {"metadata": json.dumps(meta)}
            ur = await client.post(
                "/api/university/diplomas/upload",
                headers={"Authorization": f"Bearer {tok}"},
                files=files,
                data=data,
            )
            if ur.status_code not in (200, 201):
                print(f"Upload failed {dip['diploma_number']}: {ur.status_code} {ur.text}")
                continue
            did = ur.json()["diploma_id"]
            diploma_ids[dip["diploma_number"]] = did
            if dip["auto_verify"]:
                vr = await client.post(
                    f"/api/university/diplomas/{did}/verify",
                    headers={"Authorization": f"Bearer {tok}"},
                )
                if vr.status_code not in (200, 201):
                    print(f"Verify failed {did}: {vr.status_code} {vr.text}")
                    continue
                cr = await client.get(f"/api/certificates/{did}")
                if cr.status_code == 200:
                    qr_tokens.append(cr.json().get("qr_token", ""))

    print("\n=== Demo accounts (email / password) ===")
    for a in DEMO_ACCOUNTS:
        print(f"  {a['email']:24}  {a['password']}")
    print("\n=== Diploma IDs ===")
    for k, v in diploma_ids.items():
        print(f"  {k}: {v}")
    print("\n=== QR tokens (verified) ===")
    for q in qr_tokens:
        print(f"  {q}")
        print(f"  Check: {API_BASE_URL}/api/verify/qr/{q}")
    print("\nDone.")


if __name__ == "__main__":
    asyncio.run(main())
