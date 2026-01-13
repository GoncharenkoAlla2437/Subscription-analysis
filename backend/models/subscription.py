from sqlalchemy import Column, Integer, String, Date, DateTime, Boolean, ForeignKey
from sqlalchemy import Enum as SQLEnum
from sqlalchemy.orm import relationship
from backend.database import Base
from enum import Enum
from datetime import date, datetime
from dateutil.relativedelta import relativedelta

class Sub_category(str, Enum):
    music = "music"
    video = "video"
    books = "books"
    games = "games"
    education = "education"
    social = "social"
    other = "other"

class Sub_period(str, Enum):
    monthly = "monthly"
    quarterly = "quarterly"
    yearly = "yearly"

class PriceHistory(Base):
    __tablename__ = "price_history"  # Исправляем опечатку в названии таблицы

    id = Column(Integer, primary_key=True, index=True)
    subscriptionId = Column(Integer, ForeignKey("subscriptions.id"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    startDate = Column(Date, nullable=False, default=date.today())
    endDate = Column(Date)
    createdAt = Column(DateTime, default=datetime.utcnow)
    
    # Связь с подпиской
    subscription = relationship("Subscription", back_populates="price_history")

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    userId = Column(Integer, ForeignKey("users.id"), index=True)
    name = Column(String, unique=True, index=True)
    currentAmount = Column(Integer, nullable=False, default=0)
    nextPaymentDate = Column(Date)
    connectedDate = Column(Date, nullable=False, default=date.today())
    archivedDate = Column(Date, nullable=True)
    category = Column(SQLEnum(Sub_category), nullable=False)
    notifyDays = Column(Integer, nullable=False, default=3)
    billingCycle = Column(SQLEnum(Sub_period), nullable=False, default="monthly")
    autoRenewal = Column(Boolean, default=False)
    notificationsEnabled = Column(Boolean, default=True)
    createdAt = Column(DateTime, default=datetime.utcnow)
    updatedAt = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Связи
    user = relationship("User", back_populates="subscriptions")
    price_history = relationship("PriceHistory", back_populates="subscription", cascade="all, delete-orphan")
    
    def calculate_next_payment_date(self, from_date: date = None):
        """Рассчитывает следующую дату платежа на основе даты подключения и периода"""
        if not from_date:
            from_date = self.nextPaymentDate or self.connectedDate or date.today()
        
        if self.billingCycle == Sub_period.monthly:
            return from_date + relativedelta(months=1)
        elif self.billingCycle == Sub_period.quarterly:
            return from_date + relativedelta(months=3)
        elif self.billingCycle == Sub_period.yearly:
            return from_date + relativedelta(years=1)
        else:
            return from_date + relativedelta(months=1)
    
    @property
    def days_remaining(self):
        if self.nextPaymentDate:
            return (self.nextPaymentDate - date.today()).days
        return 0