from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import date
from enum import Enum

class PeriodType(str, Enum):
    month = "month"
    quarter = "quarter"
    year = "year"

class PeriodInfo(BaseModel):
    type: PeriodType
    month: Optional[int] = None
    quarter: Optional[int] = None
    year: int

class CategoryAnalytics(BaseModel):
    category: str
    total: int
    percentage: float

class OverallAnalyticsResponse(BaseModel):
    total: int
    period: PeriodInfo
    categories: List[CategoryAnalytics]

class SubscriptionAnalytics(BaseModel):
    id: int
    name: str
    total: int
    percentage: float

class CategoryDetailResponse(BaseModel):
    category: str
    total: int
    period: PeriodInfo
    subscriptions: List[SubscriptionAnalytics]