#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🪣 Настраиваем MinIO...${NC}"

# Ждем запуска MinIO
echo -e "${YELLOW}⏳ Ждем запуска MinIO...${NC}"
sleep 15

# Устанавливаем mc (MinIO Client)
echo -e "${YELLOW}📦 Устанавливаем MinIO Client...${NC}"
docker exec gft_minio sh -c "wget -O /usr/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x /usr/bin/mc"

# Настраиваем алиас для MinIO
echo -e "${YELLOW}🔧 Настраиваем подключение к MinIO...${NC}"
docker exec gft_minio mc alias set local http://localhost:9000 gftuser Bobr_Dobriy

# Создаем bucket для файлов
echo -e "${YELLOW}📁 Создаем bucket для файлов...${NC}"
docker exec gft_minio mc mb local/chat-gft

# Настраиваем политику доступа
echo -e "${YELLOW}🔐 Настраиваем политику доступа...${NC}"
docker exec gft_minio mc anonymous set public local/chat-gft

# Показываем статус MinIO
echo -e "${GREEN}📊 Статус MinIO:${NC}"
docker-compose ps | grep minio

echo -e "${GREEN}✅ MinIO настроен!${NC}"
echo -e "${GREEN}🌐 MinIO Console: https://chatGFT.pro/minio-console${NC}"
echo -e "${GREEN}🔑 Логин: gftuser / Bobr_Dobriy${NC}"
echo -e "${GREEN}📁 Bucket: chat-gft${NC}"