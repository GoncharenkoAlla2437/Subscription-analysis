# backend/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

# Всегда указываем явный путь относительно файла database.py
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'subscriptions.db')}"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


# ✅ СОЗДАНИЕ ТАБЛИЦ ПРИ ИМПОРТЕ МОДУЛЯ
def init_db():
    """Создает все таблицы в базе данных"""
    print("🔄 Creating database tables...")

    # Импортируем все модели для создания таблиц
    from backend.models.user import User
    # Добавьте другие модели если есть:
    # from backend.models.subscription import Subscription
    # from backend.models.notification import Notification

    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully!")


# Автоматически создаем таблицы при импорте модуля
init_db()


# DB Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()