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
    local max_attempts=15
    local attempt=1
    
    echo -e "${YELLOW}🔍 Проверяем здоровье сервиса ${service}...${NC}"
    
    # Определяем имя контейнера в зависимости от сервиса
    local container_name=""
    case $service in
        backend)
            container_name="gft_backend"
            health_url="http://localhost:5000/api/health"
            ;;
        frontend)
            container_name="gft_frontend"
            health_url="http://localhost/"
            ;;
        llm_service)
            container_name="gft_llm_service"
            # Для LLM проверяем через логи, так как нет wget/curl в slim образе
            ;;
        *)
            container_name="gft_backend"
            health_url="http://localhost:5000/api/health"
            ;;
    esac
    
    while [ $attempt -le $max_attempts ]; do
        # Проверяем, что контейнер запущен
        if ! docker ps | grep -q "${container_name}"; then
            echo -e "${RED}❌ Контейнер ${container_name} остановлен!${NC}"
            docker logs "${container_name}" --tail 30 2>/dev/null || true
            return 1
        fi
        
        # Для LLM service проверяем через логи (нет wget/curl в slim образе)
        if [ "$service" = "llm_service" ]; then
            if docker logs "${container_name}" 2>&1 | grep -q "Uvicorn running\|Application startup complete\|started server process"; then
                # Проверяем, что нет критических ошибок
                if ! docker logs "${container_name}" --tail 20 2>&1 | grep -qi "error\|fatal\|failed\|exception"; then
                    echo -e "${GREEN}✅ Сервис ${service} здоров!${NC}"
                    return 0
                fi
            fi
        else
            # Для других сервисов проверяем через wget/curl
            if docker exec "${container_name}" sh -c "command -v wget >/dev/null 2>&1 && wget -q --spider ${health_url} 2>/dev/null || command -v curl >/dev/null 2>&1 && curl -f -s ${health_url} >/dev/null 2>&1" 2>/dev/null; then
                echo -e "${GREEN}✅ Сервис ${service} здоров!${NC}"
                return 0
            fi
            
            # Альтернатива: проверка через логи для backend/frontend
            if docker logs "${container_name}" 2>&1 | grep -q "Server started\|started on port\|listening\|nginx"; then
                if ! docker logs "${container_name}" --tail 20 2>&1 | grep -qi "error\|fatal\|failed"; then
                    echo -e "${GREEN}✅ Сервис ${service} здоров!${NC}"
                    return 0
                fi
            fi
        fi
        
        echo -e "${YELLOW}⏳ Попытка ${attempt}/${max_attempts}...${NC}"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    # Показываем логи при неудаче
    echo -e "${RED}❌ Сервис ${service} не отвечает! Логи:${NC}"
    docker logs "${container_name}" --tail 50 2>/dev/null || true
    
    echo -e "${RED}❌ Сервис ${service} не отвечает!${NC}"
    return 1
}

# Функция отката (исправлена - останавливает только конкретный сервис)
rollback() {
    local service=$1
    
    echo -e "${RED}🔄 Выполняем откат сервиса ${service}...${NC}"
    
    # Определяем имя контейнера
    local container_name=""
    case $service in
        backend) container_name="gft_backend" ;;
        frontend) container_name="gft_frontend" ;;
        llm_service) container_name="gft_llm_service" ;;
    esac
    
    # Останавливаем только конкретный контейнер
    if [ -n "$container_name" ]; then
        echo -e "${YELLOW}🛑 Останавливаем контейнер ${container_name}...${NC}"
        docker compose stop ${service} 2>/dev/null || true
        docker compose rm -f ${service} 2>/dev/null || true
        
        # Восстанавливаем предыдущий образ (если есть)
        local image_name=$(docker images --format "{{.Repository}}" | grep -E "chat-gft-deploy-${service}|gft_${service}" | head -1)
        if [ -n "$image_name" ] && docker images | grep -q "${image_name}-previous"; then
            echo -e "${YELLOW}📦 Восстанавливаем предыдущий образ...${NC}"
            docker tag "${image_name}-previous" "${image_name}" 2>/dev/null || true
            docker compose up -d ${service}
        fi
    else
        # Если сервис не указан, останавливаем все (fallback)
        echo -e "${YELLOW}⚠️  Сервис не указан, останавливаем все...${NC}"
        docker compose down
    fi
    
    echo -e "${RED}❌ Откат выполнен для ${service}.${NC}"
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
        rollback "${service}"
        exit 1
    fi
    
    # Ждем запуска
    echo -e "${YELLOW}⏳ Ждем запуска сервисов...${NC}"
    sleep 15
    
    # Проверяем здоровье
    if ! check_health "${service}"; then
        echo -e "${RED}❌ Проверка здоровья не пройдена!${NC}"
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            rollback "${service}"
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