# backend/test_login_only.py
import requests
import json

# ========== 1. НАСТРОЙКИ ==========
YOUR_EMAIL = "333@gmail.com"  # ← ВВЕДИ СВОЙ EMAIL
YOUR_PASSWORD = "2345678"  # ← ВВЕДИ СВОЙ ПАРОЛЬ

# ========== 2. ЛОГИН ==========
print("🔐 Логинюсь...")
login_data = {
    "email": YOUR_EMAIL,  # ← фронтенд отправляет email
    "password": YOUR_PASSWORD
}

try:
    login_response = requests.post(
        "http://localhost:8000/api/login",
        json=login_data,
        timeout=5
    )

    print(f"Login status: {login_response.status_code}")
    print(f"Login response: {login_response.text}")

    if login_response.status_code == 200:
        token = login_response.json()["access_token"]
        print(f"✅ Токен получен: {token[:30]}...")

        # ========== 3. СОЗДАНИЕ ПОДПИСКИ ==========
        print("\n📤 Создаю подписку...")

        # Тестовые данные
        subscription_data = {
            "name": "YouTube Premium",
            "currentAmount": 699,
            "category": "video",
            "billingCycle": "monthly",  # ← должно быть "monthly"!
            "notifyDays": 3,
            "autoRenewal": True,
            "notificationsEnabled": True
        }

        response = requests.post(
            "http://localhost:8000/api/subscriptions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            },
            json=subscription_data,
            timeout=5
        )

        print(f"Subscription status: {response.status_code}")
        print(f"Subscription response: {response.text}")

        # Если 422 - покажем детали
        if response.status_code == 422:
            print("\n🔍 Детали ошибки 422:")
            try:
                error_data = response.json()
                if isinstance(error_data.get("detail"), list):
                    for error in error_data["detail"]:
                        print(f"  - {error.get('msg')} (field: {error.get('loc')})")
                else:
                    print(f"  {error_data}")
            except:
                print(f"  Не могу распарсить ошибку: {response.text}")

    else:
        print("❌ Не удалось залогиниться")

except requests.exceptions.ConnectionError:
    print("❌ Не могу подключиться к серверу. Запущен ли сервер?")
    print("   Запусти: python main.py")
except Exception as e:
    print(f"❌ Ошибка: {e}")