FROM node:18-alpine

WORKDIR /app

# Копируем package.json и package-lock.json сначала (для кеширования слоев)
COPY backend-source/chat-gft-back/package.json ./
COPY backend-source/chat-gft-back/package-lock.json ./

# Устанавливаем зависимости
RUN npm ci --omit=dev --no-audit --no-fund

# Копируем остальной исходный код
COPY backend-source/chat-gft-back/ .

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 5000

CMD ["node", "src/index.js"]