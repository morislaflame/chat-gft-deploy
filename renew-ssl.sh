#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔄 Обновляем SSL сертификат...${NC}"

# Обновляем сертификат
docker-compose run --rm certbot renew

# Перезапускаем nginx
docker-compose restart nginx

echo -e "${GREEN}✅ SSL сертификат обновлен!${NC}"