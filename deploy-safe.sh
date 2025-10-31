#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Конфигурация
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-https://chatGFT.pro/api/health}"
HEALTH_CHECK_TIMEOUT=30
ROLLBACK_ON_FAILURE=true

# Функция проверки здоровья
check_health() {
    local service=$1
    local max_attempts=10
    local attempt=1
    
    echo -e "${YELLOW}🔍 Проверяем здоровье сервиса ${service}...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s --max-time 5 "${HEALTH_CHECK_URL}" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Сервис ${service} здоров!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Попытка ${attempt}/${max_attempts}...${NC}"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Сервис ${service} не отвечает!${NC}"
    return 1
}

# Функция отката
rollback() {
    echo -e "${RED}🔄 Выполняем откат...${NC}"
    
    # Останавливаем новые контейнеры
    docker compose down
    
    # Запускаем предыдущие образы (если есть)
    if docker images | grep -q "gft_backend.*previous"; then
        echo -e "${YELLOW}📦 Восстанавливаем предыдущие образы...${NC}"
        docker compose up -d
    fi
    
    echo -e "${RED}❌ Откат выполнен. Старая версия запущена.${NC}"
}

# Функция сохранения текущих образов
save_current_images() {
    echo -e "${YELLOW}💾 Сохраняем текущие образы...${NC}"
    
    # Тегируем текущие образы как previous
    docker images --format "{{.Repository}}:{{.Tag}}" | grep "gft_" | while read image; do
        if [[ ! "$image" == *"previous"* ]]; then
            docker tag "$image" "${image}-previous" 2>/dev/null || true
        fi
    done
}

# Основная функция деплоя
deploy() {
    local service=$1
    
    echo -e "${GREEN}🚀 Начинаем безопасное развертывание ${service}...${NC}"
    
    # Сохраняем текущие образы
    save_current_images
    
    # Проверяем наличие .env файла
    if [ ! -f .env ]; then
        echo -e "${RED}❌ Файл .env не найден!${NC}"
        exit 1
    fi
    
    # Останавливаем и собираем новые контейнеры
    echo -e "${YELLOW}🔨 Собираем образы...${NC}"
    if ! docker compose build --no-cache ${service}; then
        echo -e "${RED}❌ Ошибка сборки!${NC}"
        exit 1
    fi
    
    # Запускаем новые контейнеры
    echo -e "${YELLOW}🚀 Запускаем контейнеры...${NC}"
    if ! docker compose up -d ${service}; then
        echo -e "${RED}❌ Ошибка запуска!${NC}"
        rollback
        exit 1
    fi
    
    # Ждем запуска
    echo -e "${YELLOW}⏳ Ждем запуска сервисов...${NC}"
    sleep 15
    
    # Проверяем здоровье
    if ! check_health "${service}"; then
        echo -e "${RED}❌ Проверка здоровья не пройдена!${NC}"
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            rollback
        fi
        exit 1
    fi
    
    # Очищаем старые образы (опционально)
    echo -e "${YELLOW}🧹 Очищаем старые образы...${NC}"
    docker image prune -f
    
    echo -e "${GREEN}✅ Безопасное развертывание завершено!${NC}"
    
    # Показываем статус
    docker compose ps
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    # Деплой всех сервисов
    deploy ""
else
    # Деплой конкретного сервиса
    deploy "$1"
fi