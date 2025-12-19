from pydantic import BaseModel, EmailStr, field_validator, Field
import re

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        v = v.lower().strip()

        disposable_domains = [
            'tempmail.com', '10minutemail.com', 'guerrillamail.com',
            'mailinator.com', 'yopmail.com', 'throwawaymail.com',
            'fakeinbox.com', 'trashmail.com', 'temp-mail.org'
        ]

        domain = v.split('@')[-1]
        if domain in disposable_domains:
            raise ValueError('Temporary email addresses are not allowed')

        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if len(v) > 128:
            raise ValueError('Password must be less than 128 characters')
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one number')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(char.islower() for char in v):
            raise ValueError('Password must contain at least one lowercase letter')

        special_chars = r'[!@#$%^&*(),.?":{}|<>]'
        if not re.search(special_chars, v):
            raise ValueError('Password must contain at least one special character')

        return v

    # ✅ САМЫЙ ПРОСТОЙ И РАБОЧИЙ СПОСОБ:
    def __init__(self, **data):
        super().__init__(**data)
        if self.password != self.confirm_password:
            raise ValueError('Passwords do not match')

class UserLogin(BaseModel):
    email: EmailStr
    password: str
