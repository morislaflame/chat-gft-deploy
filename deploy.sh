#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Начинаем развертывание Clothing...${NC}"

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker не установлен!${NC}"
    exit 1
fi

# Проверяем наличие Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose не установлен! Устанавливаем...${NC}"
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Проверяем наличие .env файла
if [ ! -f .env ]; then
    echo -e "${RED}❌ Файл .env не найден!${NC}"
    exit 1
fi

# Останавливаем существующие контейнеры
echo -e "${YELLOW}🛑 Останавливаем существующие контейнеры...${NC}"
docker-compose down

# Собираем и запускаем контейнеры
echo -e "${YELLOW}🔨 Собираем и запускаем контейнеры...${NC}"
docker-compose up --build -d

# Ждем запуска сервисов
echo -e "${YELLOW}⏳ Ждем запуска сервисов...${NC}"
sleep 15

# Настраиваем MinIO
echo -e "${YELLOW}🪣 Настраиваем MinIO...${NC}"
chmod +x setup-minio.sh
./setup-minio.sh

# Показываем статус
echo -e "${GREEN}📊 Статус контейнеров:${NC}"
docker-compose ps

echo -e "${GREEN}✅ Развертывание завершено!${NC}"
echo -e "${GREEN}🌐 Фронтенд: https://ghettoco.com${NC}"
echo -e "${GREEN}🔧 API: https://ghettoco.com/api${NC}"
echo -e "${GREEN}🪣 MinIO Console: https://ghettoco.com/minio-console${NC}"