# models/notification.py
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Integer
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
from backend.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    subscription_id = Column(Integer, ForeignKey("subscriptions.id"), nullable=False)
    type = Column(String, nullable=False)  # "subscription_created", "price_changed", etc.
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    read = Column(Boolean, default=False)
    scheduled_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Связи
    user = relationship("User", back_populates="notifications")
    subscription = relationship("Subscription")