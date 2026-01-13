from datetime import datetime, date
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from dateutil.relativedelta import relativedelta

from backend.database import get_db
from backend.models.user import User
from backend.models.subscription import Subscription, PriceHistory, Sub_category
from backend.schemas.analytics import (
    OverallAnalyticsResponse,
    CategoryDetailResponse,
    PeriodInfo,
    PeriodType,
    CategoryAnalytics,
    SubscriptionAnalytics
)
from backend.routes.auth import get_current_user

router = APIRouter(prefix="/api", tags=["analytics"])

def calculate_period_dates(period_type: PeriodType, year: int, month: Optional[int] = None, quarter: Optional[int] = None) -> tuple[date, date]:
    """Рассчитывает даты начала и конца периода для аналитики"""
    today = date.today()
    
    if period_type == PeriodType.month:
        if not month or month < 1 or month > 12:
            raise HTTPException(status_code=400, detail="Invalid month")
        period_start = date(year, month, 1)
        period_end = date(year, month, 1) + relativedelta(months=1) - relativedelta(days=1)
    
    elif period_type == PeriodType.quarter:
        if not quarter or quarter < 1 or quarter > 4:
            raise HTTPException(status_code=400, detail="Invalid quarter")
        
        # Определяем месяц начала квартала
        start_month = (quarter - 1) * 3 + 1
        period_start = date(year, start_month, 1)
        period_end = date(year, start_month, 1) + relativedelta(months=3) - relativedelta(days=1)
    
    elif period_type == PeriodType.year:
        period_start = date(year, 1, 1)
        period_end = date(year, 12, 31)
    
    else:
        raise HTTPException(status_code=400, detail="Invalid period type")
    
    return period_start, period_end

def get_category_name(category_value: str) -> str:
    """Получает отображаемое имя категории"""
    try:
        category_enum = Sub_category(category_value)
        return category_enum.value
    except:
        return category_value

@router.get("/analytics", response_model=OverallAnalyticsResponse)
def get_overall_analytics(
    period: PeriodType = Query(..., description="Тип периода: month, quarter, year"),
    year: int = Query(..., description="Год для анализа"),
    month: Optional[int] = Query(None, description="Месяц (только для period=month)"),
    quarter: Optional[int] = Query(None, description="Квартал (только для period=quarter)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получить общую аналитику по всем категориям за указанный период.
    
    Логика расчета: 
    1. Берем активные (неархивированные) подписки пользователя
    2. Для каждой подписки берем записи из истории цен, где startDate >= начала периода
    3. Суммируем amount по категориям
    """
    
    # Валидация параметров
    if period == PeriodType.month and month is None:
        raise HTTPException(status_code=400, detail="Month is required for monthly period")
    if period == PeriodType.quarter and quarter is None:
        raise HTTPException(status_code=400, detail="Quarter is required for quarterly period")
    
    # Рассчитываем даты периода
    try:
        period_start, period_end = calculate_period_dates(period, year, month, quarter)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date parameters: {str(e)}")
    
    print(f"📊 Рассчет аналитики за период: {period_start} - {period_end}")
    
    # Получаем активные подписки пользователя
    active_subscriptions = db.query(Subscription).filter(
        Subscription.userId == current_user.id,
        Subscription.archivedDate.is_(None)  # Только неархивированные
    ).all()
    
    if not active_subscriptions:
        # Возвращаем пустой ответ, если нет активных подписок
        period_info = PeriodInfo(
            type=period,
            month=month,
            quarter=quarter,
            year=year
        )
        return OverallAnalyticsResponse(
            total=0,
            period=period_info,
            categories=[]
        )
    
    subscription_ids = [sub.id for sub in active_subscriptions]
    
    # Получаем записи истории цен для активных подписок за период
    # Берем записи, где startDate >= начала периода (не ограничиваем сверху текущей датой)
    price_history_records = db.query(PriceHistory).filter(
        PriceHistory.subscriptionId.in_(subscription_ids),
        PriceHistory.startDate >= period_start
    ).all()
    
    # Группируем по категориям
    category_totals = {}
    subscription_category_map = {sub.id: sub.category for sub in active_subscriptions}
    
    for record in price_history_records:
        category = subscription_category_map.get(record.subscriptionId)
        if category:
            category_totals[category] = category_totals.get(category, 0) + record.amount
    
    # Вычисляем общую сумму
    total_amount = sum(category_totals.values())
    
    # Формируем список категорий с процентами
    categories_list = []
    for category_value, amount in sorted(category_totals.items(), key=lambda x: x[1], reverse=True):
        percentage = (amount / total_amount * 100) if total_amount > 0 else 0
        
        categories_list.append(CategoryAnalytics(
            category=get_category_name(category_value),
            total=amount,
            percentage=round(percentage, 2)
        ))
    
    # Создаем информацию о периоде
    period_info = PeriodInfo(
        type=period,
        month=month,
        quarter=quarter,
        year=year
    )
    
    return OverallAnalyticsResponse(
        total=total_amount,
        period=period_info,
        categories=categories_list
    )

@router.get("/analytics/{category}", response_model=CategoryDetailResponse)
def get_category_analytics(
    category: str,
    period: PeriodType = Query(..., description="Тип периода: month, quarter, year"),
    year: int = Query(..., description="Год для анализа"),
    month: Optional[int] = Query(None, description="Месяц (только для period=month)"),
    quarter: Optional[int] = Query(None, description="Квартал (только для period=quarter)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получить детализированную аналитику по конкретной категории.
    
    Возвращает:
    - Общую сумму по категории
    - Список подписок в этой категории с их вкладом
    """
    
    # Валидация параметров
    if period == PeriodType.month and month is None:
        raise HTTPException(status_code=400, detail="Month is required for monthly period")
    if period == PeriodType.quarter and quarter is None:
        raise HTTPException(status_code=400, detail="Quarter is required for quarterly period")
    
    # Проверяем валидность категории
    valid_categories = [cat.value for cat in Sub_category]
    if category not in valid_categories:
        raise HTTPException(status_code=400, detail=f"Invalid category. Valid categories: {valid_categories}")
    
    # Рассчитываем даты периода
    try:
        period_start, period_end = calculate_period_dates(period, year, month, quarter)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date parameters: {str(e)}")
    
    print(f"📊 Рассчет аналитики для категории '{category}' за период: {period_start} - {period_end}")
    
    # Получаем активные подписки пользователя в указанной категории
    category_subscriptions = db.query(Subscription).filter(
        Subscription.userId == current_user.id,
        Subscription.category == category,
        Subscription.archivedDate.is_(None)  # Только неархивированные
    ).all()
    
    if not category_subscriptions:
        # Возвращаем ответ с нулевыми значениями, если нет подписок в категории
        period_info = PeriodInfo(
            type=period,
            month=month,
            quarter=quarter,
            year=year
        )
        return CategoryDetailResponse(
            category=category,
            total=0,
            period=period_info,
            subscriptions=[]
        )
    
    subscription_ids = [sub.id for sub in category_subscriptions]
    subscription_map = {sub.id: sub for sub in category_subscriptions}
    
    # Получаем записи истории цен для подписок в категории за период
    price_history_records = db.query(PriceHistory).filter(
        PriceHistory.subscriptionId.in_(subscription_ids),
        PriceHistory.startDate >= period_start
    ).all()
    
    # Группируем по подпискам
    subscription_totals = {}
    for record in price_history_records:
        subscription_totals[record.subscriptionId] = subscription_totals.get(record.subscriptionId, 0) + record.amount
    
    # Вычисляем общую сумму по категории
    total_amount = sum(subscription_totals.values())
    
    # Формируем список подписок с процентами
    subscriptions_list = []
    for sub_id, amount in sorted(subscription_totals.items(), key=lambda x: x[1], reverse=True):
        subscription = subscription_map.get(sub_id)
        if subscription:
            percentage = (amount / total_amount * 100) if total_amount > 0 else 0
            
            subscriptions_list.append(SubscriptionAnalytics(
                id=subscription.id,
                name=subscription.name,
                total=amount,
                percentage=round(percentage, 2)
            ))
    
    # Создаем информацию о периоде
    period_info = PeriodInfo(
        type=period,
        month=month,
        quarter=quarter,
        year=year
    )
    
    return CategoryDetailResponse(
        category=category,
        total=total_amount,
        period=period_info,
        subscriptions=subscriptions_list
    )