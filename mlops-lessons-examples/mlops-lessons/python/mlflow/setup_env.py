#!/usr/bin/env python3
"""
Environment Setup Helper for MLflow
Допомагає налаштувати змінні середовища для роботи з MLflow
"""

import os
from pathlib import Path

def load_env_file(env_file=".env"):
    """Завантажує змінні з .env файлу"""
    # Шукаємо .env файл в директорії скрипта, а не в поточній директорії
    script_dir = Path(__file__).parent.resolve()
    env_path = script_dir / env_file
    
    if not env_path.exists():
        print(f"❌ Файл {env_file} не знайдено в {script_dir}")
        return False
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()
    
    print(f"✅ Завантажено змінні з {env_file}")
    return True

def check_env_vars():
    """Перевіряє наявність необхідних змінних"""
    required_vars = [
        "MLFLOW_TRACKING_USERNAME",
        "MLFLOW_TRACKING_PASSWORD", 
        "MLFLOW_TRACKING_URI"
    ]
    
    missing = []
    for var in required_vars:
        if var not in os.environ:
            missing.append(var)
    
    if missing:
        print("❌ Відсутні змінні:")
        for var in missing:
            print(f"   - {var}")
        return False
    
    print("✅ Всі змінні присутні:")
    for var in required_vars:
        if "PASSWORD" in var:
            print(f"   - {var}: {'*' * len(os.environ[var])}")
        else:
            print(f"   - {var}: {os.environ[var]}")
    return True

def create_env_template():
    """Створює шаблон .env файлу"""
    script_dir = Path(__file__).parent.resolve()
    template_path = script_dir / '.env.template'
    
    template = """# MLflow Configuration
MLFLOW_TRACKING_USERNAME=user
MLFLOW_TRACKING_PASSWORD=your_password_here
MLFLOW_TRACKING_URI=http://your-mlflow-server:80
"""
    
    with open(template_path, 'w') as f:
        f.write(template)
    
    print(f"✅ Створено {template_path}")
    print(f"💡 Скопіюйте його в {script_dir}/.env та заповніть своїми значеннями")

if __name__ == "__main__":
    print("🔧 MLflow Environment Setup Helper")
    print("=" * 40)
    
    # Спроба завантажити .env файл
    if not load_env_file():
        print("\n💡 Створюю шаблон .env файлу...")
        create_env_template()
        print("\n📋 Інструкції:")
        print("1. Скопіюйте .env.template в .env")
        print("2. Заповніть реальні значення в .env")
        print("3. Запустіть цей скрипт знову")
        exit(1)
    
    # Перевірка змінних
    print("\n🔍 Перевірка змінних середовища...")
    if check_env_vars():
        print("\n🎉 Все готово для роботи з MLflow!")
    else:
        print("\n❌ Потрібно виправити змінні середовища")
        exit(1)
