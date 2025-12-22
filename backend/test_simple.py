# backend/test_simple.py
import sys
import os

# Добавляем текущую директорию в путь
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("🎯 ПОЛНЫЙ ТЕСТ СОЗДАНИЯ УВЕДОМЛЕНИЙ")
print("=" * 70)

import sqlite3
from datetime import datetime, timedelta
import uuid

db_path = "subscriptions.db"
if not os.path.exists(db_path):
    print(f"❌ База данных не найдена: {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 1. Проверяем текущую дату
cursor.execute("SELECT date('now')")
today_db = cursor.fetchone()[0]
print(f"📅 Дата в системе: {today_db}")

# 2. Создаем тестовую подписку если нужно
print(f"\n🔄 ПОДГОТОВКА ТЕСТОВЫХ ДАННЫХ...")

# Находим пользователя
cursor.execute("SELECT id FROM users LIMIT 1")
user_result = cursor.fetchone()
if not user_result:
    print("❌ Нет пользователей в базе!")
    conn.close()
    exit(1)

user_id = user_result[0]
print(f"👤 Используем пользователя ID: {user_id}")

# Создаем подписку с уведомлением СЕГОДНЯ
today = datetime.strptime(today_db, "%Y-%m-%d").date()
payment_date = today + timedelta(days=3)  # Платеж через 3 дня
notification_date = payment_date - timedelta(days=3)  # Сегодня!

# Удаляем старые тестовые подписки
cursor.execute("DELETE FROM subscriptions WHERE name LIKE '%ТЕСТ УВЕД%'")

# Создаем новую тестовую подписку
cursor.execute("""
    INSERT INTO subscriptions 
    (userId, name, currentAmount, nextPaymentDate, connectedDate, 
     category, notifyDays, billingCycle, autoRenewal, notificationsEnabled,
     createdAt, updatedAt)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (
    user_id,
    "ТЕСТ УВЕДОМЛЕНИЕ - " + today.strftime("%d.%m"),
    777,
    payment_date.isoformat(),
    today.isoformat(),
    "other",
    3,
    "monthly",
    1,
    1,
    datetime.now().isoformat(),
    datetime.now().isoformat()
))

subscription_id = cursor.lastrowid
conn.commit()

print(f"✅ Создана тестовая подписка #{subscription_id}")
print(f"   Платеж: {payment_date}")
print(f"   Уведомлять за: 3 дня")
print(f"   Уведомление должно быть: {notification_date}")
print(f"   Совпадает с сегодня? {notification_date == today}")

# 3. ПРОВЕРКА 1: Должна ли система создать уведомление?
print(f"\n" + "=" * 70)
print("🧠 ПРОВЕРКА ЛОГИКИ СИСТЕМЫ")
print("=" * 70)

cursor.execute("""
    SELECT 
        s.id,
        s.name,
        date(s.nextPaymentDate) as payment,
        s.notifyDays,
        date(s.nextPaymentDate, '-' || s.notifyDays || ' days') as should_notify
    FROM subscriptions s
    WHERE s.id = ?
""", (subscription_id,))

sub_data = cursor.fetchone()
if sub_data:
    sub_id, name, payment, notify_days, should_notify = sub_data

    print(f"📊 Подписка #{sub_id}: {name}")
    print(f"   Платеж: {payment}")
    print(f"   Уведомлять за: {notify_days} дней")
    print(f"   Должна уведомить: {should_notify}")
    print(f"   Сегодня: {today_db}")

    if should_notify == today_db:
        print(f"   🔔 РЕЗУЛЬТАТ: СИСТЕМА ДОЛЖНА СОЗДАТЬ УВЕДОМЛЕНИЕ!")

        # 4. Проверяем есть ли уже уведомление
        cursor.execute("""
            SELECT COUNT(*) 
            FROM notifications 
            WHERE subscription_id = ? 
            AND date(created_at) = date('now')
        """, (subscription_id,))

        existing_count = cursor.fetchone()[0]

        if existing_count > 0:
            print(f"   ⚠️  Но уведомление УЖЕ создано ({existing_count} шт.)")
        else:
            print(f"   ✅ Уведомление еще НЕ создано - можно тестировать!")
    else:
        print(f"   ❌ РЕЗУЛЬТАТ: Не сегодня создавать уведомление")
else:
    print(f"❌ Подписка не найдена!")

# 5. ПРОВЕРКА 2: Создаем уведомление вручную (симуляция работы системы)
print(f"\n" + "=" * 70)
print("🤖 СИМУЛЯЦИЯ РАБОТЫ СИСТЕМЫ")
print("=" * 70)

if should_notify == today_db:
    print("🔄 Система проверяет подписки...")

    # Ищем подписки для уведомления сегодня
    cursor.execute("""
        SELECT 
            s.id,
            s.name,
            s.currentAmount,
            s.notifyDays,
            s.userId
        FROM subscriptions s
        WHERE date(s.nextPaymentDate, '-' || s.notifyDays || ' days') = date('now')
        AND s.archivedDate IS NULL
        AND s.notificationsEnabled = 1
    """)

    subs_to_notify = cursor.fetchall()
    print(f"📋 Найдено подписок для уведомления: {len(subs_to_notify)}")

    created_count = 0
    for sub in subs_to_notify:
        sub_id, name, amount, notify_days, user_id = sub

        print(f"\n  🔍 Проверяем подписку #{sub_id}: {name}")

        # Проверяем не создано ли уже
        cursor.execute("""
            SELECT id 
            FROM notifications 
            WHERE subscription_id = ? 
            AND date(created_at) = date('now')
            LIMIT 1
        """, (sub_id,))

        if cursor.fetchone():
            print(f"    ⚠️  Уведомление уже создано сегодня")
        else:
            # СОЗДАЕМ УВЕДОМЛЕНИЕ!
            notification_id = str(uuid.uuid4())
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            cursor.execute("""
                INSERT INTO notifications 
                (id, user_id, subscription_id, type, title, message, scheduled_date, read, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                notification_id,
                str(user_id),
                sub_id,
                "payment_reminder",
                "Скоро списание",
                f"Через {notify_days} дня списание {amount} руб. за {name}",
                now,
                0,
                now
            ))

            created_count += 1
            print(f"    ✅ СОЗДАНО уведомление!")
            print(f"       ID: {notification_id[:8]}...")
            print(f"       Сообщение: 'Через {notify_days} дня списание {amount} руб. за {name}'")

    if created_count > 0:
        conn.commit()
        print(f"\n🎉 ИТОГ: Создано {created_count} уведомлений!")
    else:
        print(f"\nℹ️ Новых уведомлений не создано (все уже существуют)")
else:
    print("ℹ️ Сегодня не день для создания уведомлений")

# 6. ПРОВЕРКА 3: Что теперь в базе
print(f"\n" + "=" * 70)
print("📊 ФИНАЛЬНАЯ ПРОВЕРКА БАЗЫ ДАННЫХ")
print("=" * 70)

# Всего уведомлений
cursor.execute("SELECT COUNT(*) FROM notifications")
total_notifications = cursor.fetchone()[0]
print(f"📨 Всего уведомлений в базе: {total_notifications}")

# Последние уведомления
cursor.execute("""
    SELECT 
        n.id,
        substr(n.user_id, 1, 8) || '...' as user,
        n.subscription_id,
        s.name as sub_name,
        n.title,
        substr(n.message, 1, 50) as message_short,
        CASE n.read WHEN 1 THEN '✓' ELSE '✗' END as read,
        datetime(n.created_at) as created
    FROM notifications n
    LEFT JOIN subscriptions s ON n.subscription_id = s.id
    ORDER BY n.created_at DESC
    LIMIT 5
""")

print(f"\n📝 ПОСЛЕДНИЕ УВЕДОМЛЕНИЯ:")
notifications = cursor.fetchall()
if notifications:
    for i, notif in enumerate(notifications, 1):
        n_id, user, sub_id, sub_name, title, message, n_read, created = notif
        print(f"\n  {i}. 🔔 {title}")
        print(f"     Для: {sub_name or f'подписка #{sub_id}'}")
        print(f"     Пользователь: {user}")
        print(f"     Сообщение: {message}...")
        print(f"     Прочитано: {n_read}")
        print(f"     Создано: {created}")
else:
    print("  ❌ Нет уведомлений в базе")

# 7. ПРОВЕРКА 4: Готовность API
print(f"\n" + "=" * 70)
print("🚀 ПРОВЕРКА ГОТОВНОСТИ API")
print("=" * 70)

print("""
✅ База данных готова
✅ Таблица notifications существует
✅ Тестовая подписка создана
✅ Уведомление создано (если сегодня день уведомления)

📌 ЧТО ПРОВЕРИТЬ ЧЕРЕЗ API:

1. 🚀 Запусти сервер:
   python main.py

2. 🔑 Получи токен:
   curl -X POST "http://localhost:8000/api/login" \\
        -H "Content-Type: application/json" \\
        -d '{"email":"ваш_email","password":"ваш_пароль"}'

3. 📨 Получи уведомления:
   curl -X GET "http://localhost:8000/notifications" \\
        -H "Authorization: Bearer ВАШ_ТОКЕН" \\
        -H "Content-Type: application/json"

4. ✅ Отметь как прочитанное:
   curl -X PATCH "http://localhost:8000/notifications/ID_УВЕДОМЛЕНИЯ/read" \\
        -H "Authorization: Bearer ВАШ_ТОКЕН" \\
        -H "Content-Type: application/json"

5. 📊 Отметь все как прочитанные:
   curl -X POST "http://localhost:8000/notifications/read-all" \\
        -H "Authorization: Bearer ВАШ_ТОКЕН" \\
        -H "Content-Type: application/json"
""")

# 8. Информация для тестирования
print(f"\n" + "=" * 70)
print("📋 ИНФОРМАЦИЯ ДЛЯ ТЕСТА")
print("=" * 70)

cursor.execute("SELECT id, name FROM subscriptions WHERE name LIKE '%ТЕСТ%' ORDER BY id DESC LIMIT 1")
test_sub = cursor.fetchone()

if test_sub:
    print(f"🆔 ID тестовой подписки: {test_sub[0]}")
    print(f"📛 Название: {test_sub[1]}")

cursor.execute("SELECT id FROM notifications ORDER BY created_at DESC LIMIT 1")
last_notif = cursor.fetchone()

if last_notif:
    print(f"🆔 ID последнего уведомления: {last_notif[0]}")

    # Проверяем можно ли получить это уведомление через API
    cursor.execute("SELECT user_id FROM notifications WHERE id = ?", (last_notif[0],))
    notif_user = cursor.fetchone()
    if notif_user:
        cursor.execute("SELECT email FROM users WHERE id = ?", (int(notif_user[0]),))
        user_email = cursor.fetchone()
        if user_email:
            print(f"👤 Пользователь уведомления: {user_email[0]}")
            print(f"🔑 Используй этот email для логина в API")

conn.close()

print(f"\n" + "=" * 70)
print("🎯 ТЕСТ ЗАВЕРШЕН!")
print(f"=" * 70)