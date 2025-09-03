# api/main.py

from fastapi import FastAPI, UploadFile, File, HTTPException
from typing import Optional
import uvicorn
import io
import datetime
import os
import psycopg2 # Для взаємодії з PostgreSQL

# Імпортуємо наш імітований класифікатор
from model import classifier

app = FastAPI(
    title="Класифікатор Зображень з Логуванням",
    description="API для класифікації зображень, що логує передбачення в базу даних.",
    version="1.0.0"
)

# Налаштування підключення до бази даних
DB_HOST = os.getenv("DB_HOST", "db") # 'db' - це ім'я сервісу бази даних в docker-compose
DB_NAME = os.getenv("DB_NAME", "predictions_db")
DB_USER = os.getenv("DB_USER", "user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except Exception as e:
        print(f"Помилка підключення до БД: {e}")
        raise HTTPException(status_code=500, detail="Не вдалося підключитися до бази даних.")

@app.get("/")
async def root():
    return {"message": "API класифікатора зображень працює! Спробуйте /predict/image"}

@app.get("/files")
async def list_files():
    """
    Повертає список всіх файлів, що були залоговані в базі даних.
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, timestamp, filename, prediction FROM predictions ORDER BY timestamp DESC")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        files = [
            {
                "id": row[0],
                "timestamp": row[1].isoformat(),
                "filename": row[2],
                "prediction": row[3]
            }
            for row in rows
        ]
        return {"files": files}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Помилка отримання файлів з бази даних: {e}")

@app.post("/predict/image")
async def predict_image(file: UploadFile = File(...)):
    """
    Класифікує завантажене зображення та логує результат у базу даних.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Завантажте файл зображення.")

    try:
        image_bytes = await file.read()
        prediction = classifier.predict(image_bytes)
        
        # Логування передбачення в базу даних
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Переконайтеся, що файл зображення може бути збережений, якщо це необхідно
        # Для простоти, ми зберігаємо лише метадані
        log_time = datetime.datetime.now()
        image_filename = file.filename
        
        cur.execute(
            "INSERT INTO predictions (timestamp, filename, prediction) VALUES (%s, %s, %s)",
            (log_time, image_filename, prediction)
        )
        conn.commit()
        cur.close()
        conn.close()

        print(f"Лог передбачення збережено в БД: {image_filename} -> {prediction}")
        return {"filename": image_filename, "prediction": prediction, "logged": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Помилка під час передбачення або логування: {e}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)