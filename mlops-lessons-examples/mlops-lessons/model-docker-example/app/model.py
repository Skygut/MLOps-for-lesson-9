# app/model.py

import random

class ImageClassifier:
    def __init__(self):
        # В реальному сценарії тут би завантажувалася ваша модель
        # наприклад: self.model = load_model("path/to/your/model.h5")
        print("Імітація завантаження моделі класифікації зображень...")
        self.categories = ["рослина", "тварина"]
        print("Модель готова.")

    def predict(self, image_data: bytes) -> str:
        # В реальному сценарії тут би відбувалася попередня обробка зображення
        # та передача його в модель для передбачення
        # наприклад: processed_image = preprocess(image_data)
        #            prediction = self.model.predict(processed_image)
        #            return self.categories[prediction.argmax()]

        # Для нашого прикладу, просто випадково повертаємо "рослина" або "тварина"
        print("Отримано зображення, виконую імітацію передбачення...")
        prediction = random.choice(self.categories)
        return prediction

# Створюємо глобальний екземпляр класифікатора
# Щоб модель завантажувалася один раз при старті сервера
classifier = ImageClassifier()