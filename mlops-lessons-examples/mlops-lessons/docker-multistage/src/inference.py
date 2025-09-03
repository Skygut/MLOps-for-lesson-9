# src/inference.py
from fastapi import FastAPI
import uvicorn
import pickle
import os # Для перевірки наявності файлу моделі
import random

app = FastAPI(
    title="ML Inference API",
    description="API для передбачень з навченої ML-моделі.",
    version="1.0.0"
)

# Шлях до збереженої моделі (буде скопійована з першої стадії)
MODEL_PATH = "/app/trained_model.pkl"

# Завантажуємо модель при старті застосунку
try:
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, 'rb') as f:
            # Імітуємо завантаження моделі
            global loaded_model
            loaded_model = pickle.load(f)
        print(f"Модель успішно завантажена з {MODEL_PATH}")
    else:
        raise FileNotFoundError(f"Файл моделі не знайдено за шляхом: {MODEL_PATH}")
except Exception as e:
    print(f"Помилка завантаження моделі: {e}")
    loaded_model = None # Позначаємо, що модель не завантажена

@app.get("/")
async def root():
    return {"message": "ML Inference API працює!"}

@app.post("/predict")
async def predict_data():
    """
    Виконує передбачення за допомогою завантаженої моделі.
    """
    if loaded_model is None:
        raise HTTPException(status_code=500, detail="Модель не завантажена або виникла помилка.")
    
    # Імітація вхідних даних для передбачення
    sample_data = [[random.random() for _ in range(10)]] # 10 ознак
    
    # Імітація передбачення
    prediction = loaded_model.predict(sample_data)[0] # Уявимо, що модель передбачає 0 або 1
    
    return {"status": "success", "prediction_result": int(prediction)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)