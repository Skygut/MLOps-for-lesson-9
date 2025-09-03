# Dockerfile

# Використовуємо офіційний базовий образ Python
# python:3.9-slim-buster є легшим за повний образ Python
FROM python:3.9-slim-buster

# Встановлюємо робочу директорію в контейнері
WORKDIR /app

# Копіюємо файл залежностей (requirements.txt) у робочу директорію
COPY requirements.txt .

# Встановлюємо Python-залежності
# --no-cache-dir: не зберігати кеш пакетів pip для зменшення розміру образу
# -r requirements.txt: встановити пакети зі списку
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код нашого застосунку (папку app) у робочу директорію
COPY app/ ./app/

# Відкриваємо порт 8000, який буде слухати наш FastAPI-сервер
EXPOSE 8000

# Визначаємо команду, яка буде запускатися при старті контейнера
# uvicorn: веб-сервер для ASGI застосунків (FastAPI є ASGI)
# app.main:app: вказує, що наш додаток FastAPI знаходиться в файлі app/main.py, змінна 'app'
# --host 0.0.0.0: дозволяє доступ до API з будь-якого IP (не тільки localhost)
# --port 8000: запускаємо на порті 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]