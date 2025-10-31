FROM node:18-alpine

WORKDIR /app

# Копируем только package.json сначала (для кеширования слоев)
COPY backend-source/package.json ./

# Устанавливаем зависимости
RUN npm install --omit=dev --no-audit --no-fund

# Копируем остальной исходный код
COPY backend-source/ .

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 5000

CMD ["node", "src/index.js"]