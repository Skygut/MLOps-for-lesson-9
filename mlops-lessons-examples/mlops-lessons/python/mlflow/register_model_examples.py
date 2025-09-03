#!/usr/bin/env python3
"""
MLflow Model Registration Examples
Показує різні способи реєстрації моделей в MLflow Model Registry
"""

import mlflow
from mlflow.tracking import MlflowClient
import os
from pathlib import Path

if not os.environ.get('MLFLOW_TRACKING_URI'):
    print("❌ Змінна MLFLOW_TRACKING_URI не встановлена")
    exit(1)
if not os.environ.get('MLFLOW_TRACKING_USERNAME'):
    print("❌ Змінна MLFLOW_TRACKING_USERNAME не встановлена")
    exit(1)
if not os.environ.get('MLFLOW_TRACKING_PASSWORD'):
    print("❌ Змінна MLFLOW_TRACKING_PASSWORD не встановлена")
    exit(1)

client = MlflowClient()

print("🚀 MLflow Model Registration Examples")
print("=" * 50)

# Метод 1: Реєстрація під час логування (як у train.py)
print("\n1️⃣ Автоматична реєстрація під час логування:")
print("""
mlflow.sklearn.log_model(
    model, 
    name="model",
    input_example=input_example,
    registered_model_name="iris_classifier"  # Автоматично реєструє
)
""")

# Метод 2: Реєстрація існуючої моделі за URI
print("\n2️⃣ Реєстрація існуючої моделі за URI:")
print("""
# Якщо у вас є model_uri з попереднього запуску
model_uri = "runs:/abc123/model"
model_version = mlflow.register_model(
    model_uri=model_uri,
    name="iris_classifier"
)
""")

# Метод 3: Використання клієнта для створення registered model
print("\n3️⃣ Створення registered model через клієнт:")
print("""
from mlflow.tracking import MlflowClient
client = MlflowClient()

# Створити новий registered model
try:
    client.create_registered_model("iris_classifier")
    print("✅ Registered model створено")
except mlflow.exceptions.RestException:
    print("ℹ️ Registered model вже існує")

# Додати версію до існуючого registered model
model_version = client.create_model_version(
    name="iris_classifier",
    source=model_uri,
    description="Iris classification model v1.0"
)
""")

# Метод 4: Керування версіями та стадіями
print("\n4️⃣ Керування версіями та стадіями:")
print("""
# Встановити стадію версії моделі
client.transition_model_version_stage(
    name="iris_classifier",
    version=1,
    stage="Staging"  # None, Staging, Production, Archived
)

# Додати опис до версії
client.update_model_version(
    name="iris_classifier",
    version=1,
    description="Initial iris classifier model with 95% accuracy"
)

# Додати теги
client.set_model_version_tag(
    name="iris_classifier",
    version=1,
    key="validation_status",
    value="passed"
)
""")

# Метод 5: Завантаження моделі з Registry
print("\n5️⃣ Завантаження моделі з Registry:")
print("""
# Завантажити останню версію
model = mlflow.sklearn.load_model("models:/iris_classifier/latest")

# Завантажити конкретну версію
model = mlflow.sklearn.load_model("models:/iris_classifier/1")

# Завантажити з конкретної стадії
model = mlflow.sklearn.load_model("models:/iris_classifier/Production")
""")

# Практичний приклад
print("\n🔧 Практичний приклад:")

try:
    # Спроба створити registered model
    try:
        registered_model = client.create_registered_model(
            name="iris_classifier",
            description="Класифікатор для датасету Iris"
        )
        print("✅ Registered model 'iris_classifier' створено")
    except Exception as e:
        print(f"ℹ️ Registered model вже існує: {e}")
    
    # Показати всі registered models
    models = client.search_registered_models()
    print(f"\n📋 Всього registered models: {len(models)}")
    for model in models:
        print(f"   - {model.name}")
        
except Exception as e:
    print(f"❌ Помилка: {e}")

print("\n" + "=" * 50)
print("💡 Корисні команди для роботи з Model Registry:")
print("   - Перегляд моделей: MLflow UI -> Models")
print("   - API документація: https://mlflow.org/docs/latest/model-registry.html")
print("   - REST API: GET /api/2.0/mlflow/registered-models/list")
