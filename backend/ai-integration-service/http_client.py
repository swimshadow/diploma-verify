import os

HTTP_TIMEOUT = float(os.getenv("HTTP_CLIENT_TIMEOUT", "10.0"))
# Скачивание файла диплома может быть долгим
AI_FILE_FETCH_TIMEOUT = float(os.getenv("AI_FILE_FETCH_TIMEOUT", "120.0"))
