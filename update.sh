#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN} Обновляем приложение...${NC}"

# Останавливаем контейнеры
echo -e "${YELLOW} Останавливаем контейнеры...${NC}"
docker-compose down

# Удаляем старые образы
echo -e "${YELLOW} Удаляем старые образы...${NC}"
docker-compose down --rmi all

# Пересобираем и запускаем
echo -e "${YELLOW} Пересобираем и запускаем...${NC}"
docker-compose up --build -d

# Ждем запуска
sleep 15

# Показываем статус
docker-compose ps

echo -e "${GREEN} Обновление завершено!${NC}"