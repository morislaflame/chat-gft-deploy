FROM python:3.11-slim

WORKDIR /app

# Копируем requirements.txt сначала (для кеширования слоев)
COPY llm-service/raketa_llm/requirements.txt ./

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем остальной исходный код
COPY llm-service/raketa_llm/ ./

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]