from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from backend.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)

     # Добавляем связь с подписками
    subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete-orphan")
