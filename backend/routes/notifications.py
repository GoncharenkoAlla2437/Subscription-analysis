from backend.routes.auth import get_current_user
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import and_, desc

from backend.database import get_db
from backend.schemas.notification import NotificationResponse, ReadAllResponse


router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/", response_model=List[NotificationResponse])
async def get_user_notifications(
        unread_only: bool = Query(False, description="Только непрочитанные уведомления"),
        limit: int = Query(50, ge=1, le=100, description="Лимит записей"),
        offset: int = Query(0, ge=0, description="Смещение для пагинации"),
        current_user=Depends(get_current_user),  # ← УБЕРИ : User
        db: Session = Depends(get_db)
):
    """
    Получить уведомления пользователя
    """
    from backend.models.notification import Notification

    query = db.query(Notification).filter(
        Notification.user_id == str(current_user.id)
    )

    if unread_only:
        query = query.filter(Notification.read == False)

    notifications = query.order_by(
        desc(Notification.created_at)
    ).offset(offset).limit(limit).all()

    return notifications


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_as_read(
        notification_id: str,
        current_user=Depends(get_current_user),  # ← УБЕРИ : User
        db: Session = Depends(get_db)
):
    """
    Пометить уведомление как прочитанное
    """
    from backend.models.notification import Notification

    notification = db.query(Notification).filter(
        and_(
            Notification.id == notification_id,
            Notification.user_id == str(current_user.id)
        )
    ).first()

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Уведомление не найдено"
        )

    notification.read = True
    db.commit()
    db.refresh(notification)

    return notification


@router.post("/read-all", response_model=ReadAllResponse)
async def mark_all_notifications_as_read(
        current_user=Depends(get_current_user),  # ← УБЕРИ : User
        db: Session = Depends(get_db)
):
    """
    Пометить все уведомления как прочитанные
    """
    from backend.models.notification import Notification

    result = db.query(Notification).filter(
        and_(
            Notification.user_id == str(current_user.id),
            Notification.read == False
        )
    ).update(
        {"read": True},
        synchronize_session=False
    )

    db.commit()

    return ReadAllResponse(
        message="Все уведомления помечены как прочитанные",
        count=result
    )


@router.get("/unread-count")
async def get_unread_count(
        current_user=Depends(get_current_user),  # ← УБЕРИ : User
        db: Session = Depends(get_db)
):
    """
    Получить количество непрочитанных уведомлений
    """
    from backend.models.notification import Notification

    count = db.query(Notification).filter(
        and_(
            Notification.user_id == str(current_user.id),
            Notification.read == False
        )
    ).count()

    return {"unread_count": count}


# routes/notifications.py (добавить для тестов)
@router.post("/generate-reminders")
async def generate_reminders(
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """Вручную запустить генерацию уведомлений (для теста)"""
    from backend.services.not_generator import generate_payment_reminders

    count = generate_payment_reminders(db)

    return {
        "message": f"Создано {count} уведомлений",
        "count": count
    }


# routes/notifications.py (добавь)
@router.get("/debug/all")
async def get_all_notifications_debug(
        db: Session = Depends(get_db)
):
    """Получить ВСЕ уведомления из БД (для отладки)"""
    from backend.models.notification import Notification
    from sqlalchemy import text

    # 1. Просто все записи
    notifications = db.query(Notification).all()

    # 2. Сырой SQL для полной информации
    result = db.execute(text("""
        SELECT 
            n.*,
            s.name as subscription_name,
            s.nextPaymentDate as sub_next_payment,
            s.notifyDays as sub_notify_days
        FROM notifications n
        LEFT JOIN subscriptions s ON n.subscription_id = s.id
        ORDER BY n.created_at DESC
    """))

    raw_data = result.fetchall()

    return {
        "orm_count": len(notifications),
        "raw_count": len(raw_data),
        "notifications": [
            {
                "id": n.id[:8] + "...",  # сокращенный ID
                "user_id": n.user_id,
                "subscription_id": n.subscription_id,
                "title": n.title,
                "message": n.message,
                "scheduled_date": n.scheduled_date.isoformat() if n.scheduled_date else None,
                "read": n.read,
                "created_at": n.created_at.isoformat() if n.created_at else None
            }
            for n in notifications
        ],
        "raw_data": [
            dict(row._mapping) for row in raw_data
        ]
    }