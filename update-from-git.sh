#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Конфигурация
REPO_DIR="${1:-.}"
SERVICE_NAME="${2:-all}"

echo -e "${GREEN}🔄 Обновление из Git: ${SERVICE_NAME}${NC}"

# Определяем путь к репозиторию
case $SERVICE_NAME in
    backend)
        REPO_PATH="backend-source/chat-gft-back"
        ;;
    frontend)
        REPO_PATH="frontend-source/chat-gft-client"
        ;;
    llm-service)
        REPO_PATH="llm-service/raketa_llm"
        ;;
    *)
        echo -e "${YELLOW}📦 Обновляем все репозитории...${NC}"
        cd backend-source/chat-gft-back && git pull origin main && cd ../..
        cd frontend-source/chat-gft-client && git pull origin main && cd ../..
        cd llm-service/raketa_llm && git pull origin main && cd ../..
        ;;
esac

if [ "$SERVICE_NAME" != "all" ]; then
    if [ ! -d "$REPO_PATH" ]; then
        echo -e "${RED}❌ Директория ${REPO_PATH} не найдена!${NC}"
        exit 1
    fi
    
    cd "$REPO_PATH"
    echo -e "${YELLOW}📥 Обновляем ${SERVICE_NAME} из Git...${NC}"
    git pull origin main
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка при обновлении из Git!${NC}"
        exit 1
    fi
    
    cd "$REPO_DIR"
fi

# Запускаем безопасный деплой
echo -e "${GREEN}🚀 Запускаем деплой...${NC}"
./deploy-safe.sh "$SERVICE_NAME"