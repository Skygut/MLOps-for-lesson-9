# api/model.py

import random

class ImageClassifier:
    def __init__(self):
        print("Імітація завантаження моделі класифікації зображень...")
        self.categories = ["рослина", "тварина"]
        print("Модель готова.")

    def predict(self, image_data: bytes) -> str:
        print("Отримано зображення, виконую імітацію передбачення...")
        prediction = random.choice(self.categories)
        return prediction

classifier = ImageClassifier()