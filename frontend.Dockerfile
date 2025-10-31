# Build stage
FROM node:18-alpine as builder

WORKDIR /app

# Копируем package.json и pnpm-lock.yaml сначала (для кеширования слоев)
COPY frontend-source/chat-gft-client/package.json ./
COPY frontend-source/chat-gft-client/pnpm-lock.yaml ./

# Устанавливаем pnpm
RUN npm install -g pnpm

# Устанавливаем зависимости
RUN pnpm install --frozen-lockfile

# Копируем остальной исходный код
COPY frontend-source/chat-gft-client/ ./

# Собираем приложение
RUN pnpm build

# Production stage
FROM nginx:alpine

# Копируем собранное приложение
COPY --from=builder /app/dist /usr/share/nginx/html

# Копируем конфигурацию nginx
COPY frontend-nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]