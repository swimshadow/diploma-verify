/**
 * ML Extract Service — Port 3000
 * POST /ml/extract-diploma  →  принимает файл диплома (PDF / image)
 *                               возвращает JSON с извлечёнными полями
 */

const express = require('express');
const multer  = require('multer');
const pdfParse = require('pdf-parse');
const Tesseract = require('tesseract.js');

const app  = express();
const PORT = process.env.PORT || 3000;

// Хранить файл только в памяти (не на диске)
const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 20 * 1024 * 1024 }, // 20 MB
});

// ─── Парсер полей диплома ────────────────────────────────────────────────────
function extractDiplomaFields(rawText) {
  const text = rawText.replace(/\s+/g, ' ').trim();

  const result = {
    student_name:    null,
    degree:          null,
    specialty:       null,
    university:      null,
    graduation_year: null,
    diploma_number:  null,
    raw_text:        text,
  };

  // Год выпуска
  const yearMatch = text.match(/\b(19|20)\d{2}\b/);
  if (yearMatch) result.graduation_year = yearMatch[0];

  // Номер диплома  (ДВС 123456 / АВС 0001234 / № 12345)
  const numMatch = text.match(/(?:№|диплом\s*№?|diploma\s*no\.?)\s*([A-ZА-ЯЁ0-9\-]+)/i);
  if (numMatch) result.diploma_number = numMatch[1].trim();

  // Степень
  if (/бакалавр|bachelor/i.test(text))        result.degree = 'Бакалавр';
  else if (/магистр|master/i.test(text))      result.degree = 'Магистр';
  else if (/доктор|doctor|phd/i.test(text))   result.degree = 'Доктор';
  else if (/специалист|specialist/i.test(text)) result.degree = 'Специалист';

  // ФИО: ищем строку после ключевых слов
  const nameMatch = text.match(
    /(?:выдан[аo]?\s+|awarded\s+to\s+|студент[у]?\s*)([А-ЯЁA-Z][а-яёa-z]+ [А-ЯЁA-Z][а-яёa-z]+(?: [А-ЯЁA-Z][а-яёa-z]+)?)/i
  );
  if (nameMatch) result.student_name = nameMatch[1].trim();

  // Специальность
  const specMatch = text.match(/(?:специальност[ьи]|направлени[ею]|specialty|major)[:\s]+([А-ЯЁA-Za-zёа-я\s]+?)(?:\.|,|$)/i);
  if (specMatch) result.specialty = specMatch[1].trim();

  // Университет
  const uniMatch = text.match(/(?:университет|институт|академия|university|college|college)[:\s]*([А-ЯЁA-Za-zёа-я\s\-«»"]+?)(?:\.|,|$)/i);
  if (uniMatch) result.university = uniMatch[1].trim();

  return result;
}

// ─── Маршруты ────────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'ml-extract', port: PORT });
});

app.post('/ml/extract-diploma', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Файл не передан. Используй multipart/form-data, поле "file".' });
  }

  try {
    let rawText = '';
    const mime = req.file.mimetype;

    if (mime === 'application/pdf') {
      // ── PDF → текст ──────────────────────────────────────────────────────
      const parsed = await pdfParse(req.file.buffer);
      rawText = parsed.text;

    } else if (mime.startsWith('image/')) {
      // ── Изображение → OCR (Tesseract, рус + eng) ─────────────────────────
      const { data: { text } } = await Tesseract.recognize(
        req.file.buffer,
        'rus+eng',
        { logger: () => {} }          // убираем лог-спам
      );
      rawText = text;

    } else {
      return res.status(415).json({
        error: 'Неподдерживаемый тип файла. Используй PDF или изображение (jpg, png, tiff).',
      });
    }

    const data = extractDiplomaFields(rawText);

    res.json({ success: true, data });

  } catch (err) {
    console.error('[ML] Ошибка обработки:', err.message);
    res.status(500).json({ error: 'Не удалось обработать файл', details: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`✅  ML Extract Service запущен на порту ${PORT}`);
  console.log(`    POST http://localhost:${PORT}/ml/extract-diploma`);
});
