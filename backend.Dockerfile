FROM node:18-alpine

WORKDIR /app

# Копируем исходный код
COPY backend-source/ .

# Устанавливаем зависимости
RUN npm ci --only=production --no-audit --no-fund

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 5000

CMD ["node", "src/index.js"]