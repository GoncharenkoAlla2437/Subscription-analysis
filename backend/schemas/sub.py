from pydantic import BaseModel, Field, validator
from datetime import date, datetime
from typing import Optional, List
from enum import Enum

class SubCategoryEnum(str, Enum):
    music = "music"
    video = "video"
    books = "books"
    games = "games"
    education = "education"
    social = "social"
    other = "other"

class SubPeriodEnum(str, Enum):
    monthly = "monthly"
    quarterly = "quarterly"
    yearly = "yearly"

class CreateSubscriptionRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Название подписки")
    currentAmount: int = Field(..., ge=0, description="Текущая стоимость подписки")
    nextPaymentDate: Optional[date] = None
    connectedDate: Optional[date] = None
    archivedDate: Optional[date] = None
    category: SubCategoryEnum = Field(..., description="Категория подписки")
    notifyDays: Optional[int] = Field(default=3, ge=1, le=30, description="Дней до уведомления")
    billingCycle: Optional[SubPeriodEnum] = Field(default=SubPeriodEnum.monthly, description="Период оплаты")
    autoRenewal: Optional[bool] = Field(default=False, description="Автопродление подписки")
    notificationsEnabled: Optional[bool] = Field(default=True, description="Включены ли уведомления")
    
    class Config:
        schema_extra = {
            "example": {
                "name": "Netflix Premium",
                "currentAmount": 1499,
                "nextPaymentDate": "2024-12-15",
                "connectedDate": "2024-01-15",
                "category": "video",
                "notifyDays": 3,
                "billingCycle": "monthly",
                "autoRenewal": False,
                "notificationsEnabled": True
            }
        }
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Subscription name cannot be empty')
        return v.strip()

class PriceHistoryItem(BaseModel):
    id: Optional[int] = None
    amount: int
    startDate: date
    createdAt: datetime
    
    class Config:
        orm_mode = True

class SubscriptionResponse(BaseModel):
    id: int
    userId: int
    name: str
    currentAmount: int
    nextPaymentDate: Optional[date]
    connectedDate: date
    archivedDate: Optional[date]
    category: str
    notifyDays: int
    billingCycle: str
    autoRenewal: bool
    notificationsEnabled: bool
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        orm_mode = True

class SubscriptionWithPriceHistory(SubscriptionResponse):
    priceHistory: List[PriceHistoryItem] = []