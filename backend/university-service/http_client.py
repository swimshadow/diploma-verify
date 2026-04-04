import os

# Межсервисные вызовы (кроме загрузки крупных файлов)
HTTP_TIMEOUT = float(os.getenv("HTTP_CLIENT_TIMEOUT", "10.0"))
# Multipart upload на file-service
UPLOAD_HTTP_TIMEOUT = float(os.getenv("UPLOAD_HTTP_TIMEOUT", "120.0"))
