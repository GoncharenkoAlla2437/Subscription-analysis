# schemas/notification.py - проверьте что есть:
from pydantic import BaseModel, ConfigDict, field_validator
from typing import Optional
from datetime import datetime
import uuid


class NotificationBase(BaseModel):
    type: str
    title: str
    message: str
    scheduled_date: datetime
    action_url: Optional[str] = None


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    subscription_id: uuid.UUID
    type: str
    title: str
    message: str
    scheduled_date: datetime
    sent_at: Optional[datetime] = None
    read: bool
    action_url: Optional[str] = None
    created_at: datetime


class NotificationReadRequest(BaseModel):
    read: bool = True


class ReadAllResponse(BaseModel):
    message: str
    count: int