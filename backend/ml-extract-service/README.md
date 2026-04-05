# ML Extract Service

Node.js микросервис для извлечения данных из дипломов (PDF и изображения) с использованием OCR.

## API

### Health Check
```bash
GET /health
```

### Extract Diploma Data
```bash
POST /ml/extract-diploma
Content-Type: multipart/form-data

- file: файл диплома (PDF, JPG, PNG, TIFF)
```

**Response:**
```json
{
  "success": true,
  "data": {
    "student_name": "Иван Иванович Иванов",
    "degree": "Бакалавр",
    "specialty": "Информатика",
    "university": "МГУ",
    "graduation_year": "2024",
    "diploma_number": "АА123456",
    "raw_text": "полный текст диплома"
  }
}
```

## Зависимости

- Express.js
- Multer (для обработки файлов)
- pdf-parse (парсинг PDF)
- Tesseract.js (OCR для изображений)

## Сборка и запуск

### Docker
```bash
docker build -t ml-extract-service .
docker run -p 3000:3000 ml-extract-service
```

### Локально
```bash
npm install
npm start
```

## Переменные окружения

- `PORT` - порт сервиса (по умолчанию 3000)

## Поддерживаемые форматы файлов

- PDF
- JPG/JPEG
- PNG
- TIFF
