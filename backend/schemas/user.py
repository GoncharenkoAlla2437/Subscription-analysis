from pydantic import BaseModel, EmailStr, field_validator, Field
import re

class UserRegister(BaseModel):
    email: str
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str
