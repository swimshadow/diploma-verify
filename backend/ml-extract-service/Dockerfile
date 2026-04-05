FROM node:18-alpine

WORKDIR /app

# Установка зависимостей для Tesseract (retry при сетевых сбоях)
RUN for i in 1 2 3 4 5; do \
      apk add --no-cache \
        tesseract-ocr \
        tesseract-ocr-data-rus \
        build-base \
        python3 \
        make \
        g++ \
      && break || sleep 5; \
    done

COPY package.json .
RUN npm install

COPY server.js .

EXPOSE 3000

CMD ["npm", "start"]
