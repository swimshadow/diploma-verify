FROM node:18-alpine

WORKDIR /app

# Установка зависимостей для Tesseract
RUN apk add --no-cache \
    tesseract-ocr \
    tesseract-ocr-data-rus \
    build-base \
    python3 \
    make \
    g++

COPY package.json .
RUN npm install

COPY server.js .

EXPOSE 3000

CMD ["npm", "start"]
