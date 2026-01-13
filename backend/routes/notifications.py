# backend/routes/notification.py
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, desc

from backend.database import get_db
from backend.routes.auth import get_current_user
from backend.schemas.notification import NotificationResponse
from backend.models.notification import Notification
from backend.models.subscription import Subscription

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/grouped")
async def get_notifications_grouped_by_subscription(
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    Главный endpoint: получить уведомления, сгруппированные как чаты
    Используется для главного экрана со списком подписок
    """
    # Получаем все уведомления пользователя
    notifications = db.query(Notification).filter(
        Notification.user_id == str(current_user.id)
    ).order_by(desc(Notification.created_at)).all()

    # Получаем все подписки пользователя
    subscriptions = db.query(Subscription).filter(
        Subscription.userId == str(current_user.id)
    ).all()

    # Создаем словарь для быстрого доступа к подпискам
    sub_dict = {sub.id: sub for sub in subscriptions}

    # Группируем уведомления по subscription_id
    grouped = {}
    for notification in notifications:
        sub_id = notification.subscription_id

        # Если подписка не найдена (архивированная), пропускаем
        if sub_id not in sub_dict:
            continue

        subscription = sub_dict[sub_id]

        # Создаем группу если ее еще нет
        if sub_id not in grouped:
            grouped[sub_id] = {
                "subscription_id": sub_id,
                "subscription_name": subscription.name,
                "subscription_amount": float(subscription.currentAmount),
                "subscription_category": subscription.category,
                "notifications": [],
                "unread_count": 0,
                "last_notification_date": None
            }

        # Добавляем уведомление в группу
        notification_data = {
            "id": notification.id,
            "type": notification.type,
            "title": notification.title,
            "message": notification.message,
            "read": notification.read,
            "created_at": notification.created_at.isoformat() if notification.created_at else None
        }

        grouped[sub_id]["notifications"].append(notification_data)

        # Считаем непрочитанные
        if not notification.read:
            grouped[sub_id]["unread_count"] += 1

        # Обновляем дату последнего уведомления
        if (not grouped[sub_id]["last_notification_date"] or
                notification.created_at > grouped[sub_id]["last_notification_date"]):
            grouped[sub_id]["last_notification_date"] = notification.created_at

    # Преобразуем словарь в список
    result = []
    for sub_id, data in grouped.items():
        # Сортируем уведомления внутри группы (новые сверху)
        data["notifications"].sort(key=lambda x: x["created_at"], reverse=True)

        # Преобразуем datetime в строку
        if data["last_notification_date"]:
            data["last_notification_date"] = data["last_notification_date"].isoformat()

        result.append(data)

    # Сортируем группы по дате последнего уведомления (новые сверху)
    result.sort(key=lambda x: x["last_notification_date"] or "", reverse=True)

    return result


@router.get("/subscription/{subscription_id}")
async def get_subscription_notifications(
        subscription_id: int,
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    Получить все уведомления конкретной подписки
    Используется при открытии "чата" с подпиской
    """
    # Проверяем, существует ли подписка у пользователя
    subscription = db.query(Subscription).filter(
        and_(
            Subscription.id == subscription_id,
            Subscription.userId == str(current_user.id)
        )
    ).first()

    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Подписка не найдена"
        )

    # Получаем все уведомления для этой подписки
    notifications = db.query(Notification).filter(
        and_(
            Notification.user_id == str(current_user.id),
            Notification.subscription_id == subscription_id
        )
    ).order_by(desc(Notification.created_at)).all()

    # Используем существующую схему
    notification_responses = [NotificationResponse.from_orm(n) for n in notifications]

    return {
        "subscription": {
            "id": subscription.id,
            "name": subscription.name,
            "amount": float(subscription.currentAmount),
            "category": subscription.category
        },
        "notifications": notification_responses,
        "total_count": len(notifications),
        "unread_count": len([n for n in notifications if not n.read])
    }


@router.post("/subscription/{subscription_id}/read-all")
async def mark_subscription_notifications_read(
        subscription_id: int,
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    Пометить ВСЕ уведомления конкретной подписки как прочитанные
    Вызывается при открытии окна переписки с подпиской
    """
    # Проверяем, существует ли подписка у пользователя
    subscription = db.query(Subscription).filter(
        and_(
            Subscription.id == subscription_id,
            Subscription.userId == str(current_user.id)
        )
    ).first()

    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Подписка не найдена"
        )

    # Помечаем все уведомления этой подписки как прочитанные
    result = db.query(Notification).filter(
        and_(
            Notification.user_id == str(current_user.id),
            Notification.subscription_id == subscription_id,
            Notification.read == False
        )
    ).update({"read": True})

    db.commit()

    return {
        "message": f"Все уведомления по подписке '{subscription.name}' помечены как прочитанные",
        "subscription_id": subscription_id,
        "subscription_name": subscription.name,
        "count": result
    }


@router.get("/subscription/{subscription_id}/unread-count")
async def get_subscription_unread_count(
        subscription_id: int,
        current_user=Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    Получить количество непрочитанных уведомлений для конкретной подписки
    Используется для обновления бейджей в фоне
    """
    # Проверяем, что подписка принадлежит пользователю
    subscription = db.query(Subscription).filter(
        and_(
            Subscription.id == subscription_id,
            Subscription.userId == str(current_user.id)
        )
    ).first()

    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Подписка не найдена"
        )

    count = db.query(Notification).filter(
        and_(
            Notification.user_id == str(current_user.id),
            Notification.subscription_id == subscription_id,
            Notification.read == False
        )
    ).count()

    return {
        "subscription_id": subscription_id,
        "subscription_name": subscription.name,
        "unread_count": count
    }