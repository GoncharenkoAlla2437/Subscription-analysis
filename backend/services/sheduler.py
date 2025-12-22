# tasks/scheduler.py
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from backend.database import SessionLocal
from not_generator import generate_payment_reminders

scheduler = BackgroundScheduler()

def daily_notification_check():
    """Ежедневная проверка подписок"""
    print(f"[{datetime.now()}] Запуск проверки уведомлений...")
    db = SessionLocal()
    try:
        count = generate_payment_reminders(db)
        print(f"Создано уведомлений: {count}")
    finally:
        db.close()

# Запускать каждый день в 09:00
scheduler.add_job(daily_notification_check, 'cron', hour=9, minute=0)
scheduler.start()