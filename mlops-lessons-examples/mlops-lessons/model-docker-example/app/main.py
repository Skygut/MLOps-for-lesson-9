# app/main.py

from fastapi import FastAPI, UploadFile, File, HTTPException
from typing import Optional
import uvicorn
import io

# Імпортуємо наш імітований класифікатор
from .model import classifier

app = FastAPI(
    title="Класифікатор Зображень",
    description="Простий API для класифікації зображень: Рослина чи Тварина.",
    version="1.0.0"
)

@app.get("/")
async def root():
    return {"message": "API класифікатора зображень працює! Спробуйте /predict/image"}

@app.post("/predict/image")
async def predict_image(file: UploadFile = File(...)):
    """
    Класифікує завантажене зображення на 'рослина' або 'тварина'.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Завантажте файл зображення.")

    try:
        # Читаємо байти зображення
        image_bytes = await file.read()
        
        # Передаємо байти моделі для передбачення
        # В реальному сценарії тут би було більше логіки обробки зображення
        prediction = classifier.predict(image_bytes)

        return {"filename": file.filename, "prediction": prediction}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Помилка під час передбачення: {e}")

if __name__ == "__main__":
    # Цей блок не буде виконуватися, коли контейнер запускається через uvicorn у Dockerfile,
    # але корисний для локального тестування без Docker.
    uvicorn.run(app, host="0.0.0.0", port=8000)