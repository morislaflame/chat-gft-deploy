FROM python:3.11-slim

WORKDIR /app

# Копируем из подпапки raketa_llm
COPY llm-service/raketa_llm/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY llm-service/raketa_llm/ .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]