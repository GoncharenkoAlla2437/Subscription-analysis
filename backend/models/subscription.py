from sqlalchemy import Column, Integer, String, Date, Boolean, ForeignKey
from sqlalchemy import Enum as SQLEnum
from database import Base
from enum import Enum
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
from backend.models.user import User


class Sub_category(str, Enum):
    music = "music"
    video = "video"
    books = "books"
    games = "games"
    education = "education"
    social = "social"
    other = "other"

class Sub_period(str, Enum):
    mounthly = "mounthly"
    quarterly = "quarterly"
    yearly = "yearly"

class Subscription(Base):
    tablename = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    userId = Column(Integer,  ForeignKey("users.id"), primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    currentAmount = Column(Integer, nullable = False, default = 0) #стоимость подписки
    nextPaymentDate = Column(Date) #дата следующего списания, высчитывается по периоду обновления, может удалю
    connectedDate = Column(Date, nullable=False, default = date.today()) #дата подключения подписки
    archivedDate = Column(Date, nullable=True) #дата архивирования подписки
    category = Column(SQLEnum(Sub_category), nullable=False)
    notifyDays = Column(Integer, nullable=False, default = 3) #За сколько дней уведомлять об окончании подписки (мин и макс в отдельной функции)
    billingCycle = Column(SQLEnum(Sub_period), nullable = False, default = "mounthly") #период обновления
    # num_debits = Column(Integer, nullable=False, default = 0) #сколько раз списывались деньги, возможно понадобится при аналитике
    # autoRenewal = Column(Boolean, default=False) # автопродлять или сразу кидать в архив - если во фронте добавим такую галочку при создании подписки
    notificationsEnabled = Column(Boolean, default=True) # отправлять ли уведомления - опять же нужна галочка во фронте

    # def set_duration(self, months: int):  
    #     self.end_date = self.connectedDate + relativedelta(months=months)
    # вообще это функция, чтобы не использовать nextPaymentDate, но пока хз, понадобится ли
    
    # # Свойство для проверки активна ли подписка - дипсик написал, не уверена, что нужно, мейби потом удалю
    # @property
    # def is_active(self):
    #     if self.archivedDate == False:
    #         return date.today() <= self.nextPaymentDate
    #     return 0
    
    # Свойство для получения оставшихся дней до списания
    @property
    def days_remaining(self):
        if self.nextPaymentDate:
            return (self.nextPaymentDate - date.today()).days
        return 0