#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🌐 Настраиваем домен и SSL...${NC}"

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
sudo mkdir -p /var/www/certbot
sudo chmod 755 /var/www/certbot

# Обновляем nginx.conf с доменом (если нужно)
if grep -q "chatGFT.pro" nginx.conf; then
    echo -e "${YELLOW}📝 Обновляем nginx.conf...${NC}"
    sed -i "s/chatGFT.pro/${DOMAIN}/g" nginx.conf
fi

# Обновляем docker-compose.yml с доменом и email (если нужно)
if grep -q "chatGFT.pro" docker-compose.yml; then
    echo -e "${YELLOW}📝 Обновляем docker-compose.yml...${NC}"
    sed -i "s/chatGFT.pro/${DOMAIN}/g" docker-compose.yml
fi

if grep -q "chatGFT@mail.ru" docker-compose.yml; then
    sed -i "s/chatGFT@mail.ru/${EMAIL}/g" docker-compose.yml
fi

# Обновляем .env с доменом (если файл существует)
if [ -f .env ] && grep -q "chatGFT.pro" .env; then
    echo -e "${YELLOW}📝 Обновляем .env...${NC}"
    sed -i "s/chatGFT.pro/${DOMAIN}/g" .env
fi

# Убедимся, что frontend и backend запущены
echo -e "${YELLOW}🔨 Запускаем зависимости...${NC}"
docker compose up -d frontend backend

# Ждем запуска
sleep 5

# Запускаем nginx БЕЗ SSL (для получения сертификата)
echo -e "${YELLOW}🔨 Запускаем nginx...${NC}"
docker compose up -d nginx

# Ждем запуска nginx
echo -e "${YELLOW}⏳ Ждем запуска nginx...${NC}"
sleep 10

# Проверяем, что nginx запущен
if ! docker ps | grep -q gft_nginx; then
    echo -e "${RED}❌ Ошибка запуска nginx!${NC}"
    docker compose logs nginx
    exit 1
fi

# Проверяем конфигурацию nginx
echo -e "${YELLOW}🔍 Проверяем конфигурацию nginx...${NC}"
docker exec gft_nginx nginx -t

# Получаем SSL сертификат
echo -e "${YELLOW}🔐 Получаем SSL сертификат...${NC}"
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email "${EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${DOMAIN}" \
  -d "www.${DOMAIN}"

# Проверяем результат
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL сертификат получен!${NC}"
    
    # Перезапускаем nginx с SSL
    echo -e "${YELLOW}🔄 Перезапускаем nginx с SSL...${NC}"
    docker compose restart nginx
    
    # Проверяем SSL
    sleep 5
    echo -e "${YELLOW}🔍 Проверяем SSL...${NC}"
    curl -I "https://${DOMAIN}/api/health" 2>&1 | head -5
    
    echo -e "${GREEN}✅ Домен и SSL настроены!${NC}"
    echo -e "${GREEN}🌐 Ваш сайт: https://${DOMAIN}${NC}"
else
    echo -e "${RED}❌ Ошибка получения SSL сертификата!${NC}"
    echo -e "${YELLOW}💡 Убедитесь, что:${NC}"
    echo -e "  1. Домен ${DOMAIN} указывает на IP сервера"
    echo -e "  2. Порты 80 и 443 открыты в firewall"
    echo -e "  3. Nginx доступен извне"
    exit 1
fi