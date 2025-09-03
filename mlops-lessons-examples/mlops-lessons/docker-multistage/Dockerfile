# Dockerfile

# --- STAGE 1: Build (Тренування Моделі) ---
# Ця стадія містить усі залежності, необхідні для тренування моделі.
FROM python:3.9-slim-buster AS builder

WORKDIR /app

# Копіюємо залежності для тренування
COPY requirements_train.txt .

# Встановлюємо залежності для тренування
# --no-cache-dir для зменшення розміру проміжних шарів
RUN pip install --no-cache-dir -r requirements_train.txt

# Копіюємо скрипт тренування
COPY src/train.py .

# Запускаємо скрипт тренування, який збереже 'trained_model.pkl'
RUN python train.py

# --- STAGE 2: Runtime (Обслуговування Моделі) ---
# Ця стадія є кінцевим, легким образом.
# Вона містить лише те, що потрібно для запуску API інференсу.
FROM python:3.9-slim-buster AS runtime

WORKDIR /app

# Копіюємо лише навчену модель з попередньої стадії 'builder'
# 'builder' - це ім'я першої стадії
# /app/trained_model.pkl - це шлях до файлу моделі в першій стадії
# . - це цільова директорія в поточній стадії (/app)
COPY --from=builder /app/trained_model.pkl .

# Копіюємо залежності для інференсу
COPY requirements_inference.txt .

# Встановлюємо залежності для інференсу
RUN pip install --no-cache-dir -r requirements_inference.txt

# Копіюємо скрипт інференсу
COPY src/inference.py .

# Відкриваємо порт, на якому буде працювати API
EXPOSE 8000

# Команда для запуску FastAPI додатка
CMD ["uvicorn", "inference:app", "--host", "0.0.0.0", "--port", "8000"]