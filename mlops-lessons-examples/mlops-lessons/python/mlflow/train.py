import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, log_loss
import os
from pathlib import Path


# Параметри, які хочемо варіювати
learning_rate = 0.01
epochs = 100

# if not os.environ.get('MLFLOW_TRACKING_URI'):
#     print("❌ Змінна MLFLOW_TRACKING_URI не встановлена")
#     exit(1)
# if not os.environ.get('MLFLOW_TRACKING_USERNAME'):
#     print("❌ Змінна MLFLOW_TRACKING_USERNAME не встановлена")
#     exit(1)
# if not os.environ.get('MLFLOW_TRACKING_PASSWORD'):
#     print("❌ Змінна MLFLOW_TRACKING_PASSWORD не встановлена")
#     exit(1)

# Старт логування
mlflow.set_experiment("MLOps Classification")

# Створення унікального імені для запуску
import datetime
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
run_name = f"iris_lr_{learning_rate}_epochs_{epochs}_{timestamp}"

print(f"🚀 Запускаю тренування: {run_name}")

with mlflow.start_run(run_name=run_name):

    # Логування параметрів
    mlflow.log_param("learning_rate", learning_rate)
    mlflow.log_param("epochs", epochs)
    mlflow.log_param("model_version", "1.0.0")
    mlflow.log_param("model_name", "iris_model")

    # Завантаження даних
    X, y = load_iris(return_X_y=True)
    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=42)

    # Тренування моделі
    model = LogisticRegression(max_iter=epochs)
    model.fit(X_train, y_train)

    # Прогнозування
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)

    # Обчислення метрик
    acc = accuracy_score(y_test, y_pred)
    loss = log_loss(y_test, y_proba)

    

    # Логування метрик
    mlflow.log_metric("accuracy", acc)
    mlflow.log_metric("loss", loss)
    mlflow.log_metric("data", 10000)
    

    # Логування моделі з підписом та прикладом вводу
    input_example = X_test[:1]  # Приклад вводу (перший рядок тестових даних)
    mlflow.sklearn.log_model(
        model, 
        name="mlops_model",
        input_example=input_example,
        registered_model_name="mlops_classifier"
    )

    # print(f"✅ Експеримент завершено. Модель зареєстрована: {model_info.model_uri}")
    # print("🔗 Перевірте результати в MLflow UI та Model Registry.")