# backend/services/notification_service.py
from datetime import datetime, date
from sqlalchemy.orm import Session
import uuid
from backend.models.notification import Notification


class NotificationService:
    """Сервис для создания уведомлений по событиям"""

    @staticmethod
    def create_notification(
            db: Session,
            user_id: str,
            subscription_id: int,
            notification_type: str,
            title: str,
            message: str
    ) -> dict:
        """Базовая функция создания уведомления"""

        notification = Notification(
            id=str(uuid.uuid4()),
            user_id=user_id,
            subscription_id=subscription_id,
            type=notification_type,
            title=title,
            message=message,
            read=False,
            scheduled_date=datetime.now()
        )

        db.add(notification)
        db.commit()
        db.refresh(notification)

        return {
            "id": notification.id,
            "type": notification.type,
            "title": notification.title,
            "message": notification.message
        }

    # ===== СПЕЦИФИЧНЫЕ УВЕДОМЛЕНИЯ =====

    @staticmethod
    def for_subscription_created(
            db: Session,
            user_id: str,
            subscription_id: int,
            subscription_name: str,
            amount: float,
            next_payment_date: date = None
    ):
        """Уведомление о создании новой подписки"""
        message = f"Вы добавили подписку '{subscription_name}'"
        if amount > 0:
            message += f" на сумму {amount} руб."
        if next_payment_date:
            message += f" Следующий платеж {next_payment_date.strftime('%d.%m.%Y')}"

        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            subscription_id=subscription_id,
            notification_type="subscription_created",
            title="Подписка добавлена",
            message=message
        )

    @staticmethod
    def for_price_changed(
            db: Session,
            user_id: str,
            subscription_id: int,
            subscription_name: str,
            old_amount: float,
            new_amount: float
    ):
        """Уведомление об изменении цены"""
        diff = new_amount - old_amount
        diff_abs = abs(diff)

        if diff > 0:
            change = f"увеличилась на {diff_abs} руб."
        elif diff < 0:
            change = f"уменьшилась на {diff_abs} руб."
        else:
            return None  # Цена не изменилась

        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            subscription_id=subscription_id,
            notification_type="price_changed",
            title="Изменение цены",
            message=f"Цена подписки '{subscription_name}' {change}. Новая цена: {new_amount} руб."
        )

    @staticmethod
    def for_payment_date_changed(
            db: Session,
            user_id: str,
            subscription_id: int,
            subscription_name: str,
            old_date: date,
            new_date: date
    ):
        """Уведомление об изменении даты платежа"""
        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            subscription_id=subscription_id,
            notification_type="payment_date_changed",
            title="Перенос платежа",
            message=f"Дата платежа для '{subscription_name}' изменена с "
                    f"{old_date.strftime('%d.%m.%Y')} на {new_date.strftime('%d.%m.%Y')}"
        )

    @staticmethod
    def for_payment_soon(
            db: Session,
            user_id: str,
            subscription_id: int,
            subscription_name: str,
            payment_date: date,
            amount: float,
            days_left: int
    ):
        """Уведомление о скором платеже (заранее)"""
        days_text = "день" if days_left == 1 else "дня" if 2 <= days_left <= 4 else "дней"

        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            subscription_id=subscription_id,
            notification_type="payment_reminder",
            title="Скоро списание",
            message=f"Через {days_left} {days_text} ({payment_date.strftime('%d.%m.%Y')}) "
                    f"спишется {amount} руб. за '{subscription_name}'"
        )

    @staticmethod
    def for_auto_renewal_changed(
            db: Session,
            user_id: str,
            subscription_id: int,
            subscription_name: str,
            auto_renewal: bool
    ):
        """Уведомление об изменении авто-продления"""
        status = "включено" if auto_renewal else "отключено"

        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            subscription_id=subscription_id,
            notification_type="auto_renewal_changed",
            title="Автопродление изменено",
            message=f"Автоматическое продление подписки '{subscription_name}' {status}"
        )