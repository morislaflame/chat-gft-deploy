#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}�� Настраиваем домен и SSL...${NC}"

# Проверяем параметры
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Использование: ./setup-domain.sh chatGFT.pro chatGFT@mail.ru${NC}"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

if [ -z "$EMAIL" ]; then
    echo -e "${RED}❌ Использование: ./setup-domain.sh chatGFT.pro chatGFT@mail.ru${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Настраиваем домен: ${DOMAIN}${NC}"
echo -e "${YELLOW}📧 Email: ${EMAIL}${NC}"

# Создаем папку для certbot
mkdir -p /var/www/certbot

# Обновляем nginx.conf с доменом
sed -i "s/chatGFT.pro/${DOMAIN}/g" nginx.conf

# Обновляем docker-compose.yml с доменом и email
sed -i "s/chatGFT.pro/${DOMAIN}/g" docker-compose.yml
sed -i "s/chatGFT@mail.ru/${EMAIL}/g" docker-compose.yml

# Обновляем .env с доменом
sed -i "s/chatGFT.pro/${DOMAIN}/g" .env

echo -e "${YELLOW}🔨 Запускаем контейнеры...${NC}"
docker-compose up -d nginx

# Ждем запуска nginx
sleep 5

echo -e "${YELLOW}🔐 Получаем SSL сертификат...${NC}"
docker-compose run --rm certbot

# Перезапускаем nginx с SSL
echo -e "${YELLOW}🔄 Перезапускаем nginx с SSL...${NC}"
docker-compose restart nginx

echo -e "${GREEN}✅ Домен и SSL настроены!${NC}"
echo -e "${GREEN}🌐 Ваш сайт: https://${DOMAIN}${NC}"