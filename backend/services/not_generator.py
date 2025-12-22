# services/notification_generator.py
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
import uuid


def generate_payment_reminders(db: Session):
    """Создает уведомления без дублирования"""
    from backend.models.subscription import Subscription
    from backend.models.notification import Notification

    today = datetime.now().date()
    created_count = 0

    # Подписки, у которых сегодня день уведомления
    subscriptions = db.query(Subscription).filter(
        Subscription.archivedDate.is_(None),
        Subscription.nextPaymentDate.isnot(None),
        Subscription.notificationsEnabled == True,
        # ТОЧНО сегодня = nextPaymentDate - notifyDays
        Subscription.nextPaymentDate == today + timedelta(days=Subscription.notifyDays)
    ).all()

    for sub in subscriptions:
        # КРИТИЧНО: проверяем не создавали ли уже сегодня
        existing = db.query(Notification).filter(
            Notification.subscription_id == sub.id,
            Notification.type == "payment_reminder",
            # Сегодняшнее уведомление
            Notification.created_at >= datetime(today.year, today.month, today.day),
            Notification.created_at < datetime(today.year, today.month, today.day) + timedelta(days=1)
        ).first()

        if not existing:  # Только если еще не создавали
            notification = Notification(
                id=str(uuid.uuid4()),
                user_id=str(sub.userId),
                subscription_id=sub.id,
                type="payment_reminder",
                title="Скоро списание",
                message=f"Через {sub.notifyDays} дня списание {sub.currentAmount} руб. за {sub.name}",
                scheduled_date=datetime.now(),
                action_url=f"/subscriptions/{sub.id}",
                read=False
            )
            db.add(notification)
            created_count += 1
            print(f"✅ Создано уведомление для подписки: {sub.name}")
        else:
            print(f"⚠️ Уведомление для {sub.name} уже создано сегодня")

    if created_count > 0:
        db.commit()

    return created_count