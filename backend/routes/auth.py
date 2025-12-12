from fastapi import APIRouter, Depends, HTTPException, status, Security
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from backend.database import SessionLocal, get_db
from backend.models.user import User
from backend.utils.security import  hash_password, verify_password, create_access_token, create_refresh_token,decode_refresh_token, decode_access_token
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, OAuth2PasswordRequestForm

router = APIRouter()
security = HTTPBearer()

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

# ----------------------------
# SCHEMAS (валидация данных)
# ----------------------------
class UserRegister(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# ---------------------------------------
# 1. REGISTER (регистрация)
# ---------------------------------------
@router.post("/register")
def register(user: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists")

    new_user = User(
        email=user.email,
        password=hash_password(user.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "User registered successfully"}


# ---------------------------------------
# 2. LOGIN (создание JWT токена)
# ---------------------------------------

@router.post("/login")
def login(data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()

    if not user or not verify_password(data.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid email or password")

    access_token = create_access_token({"user_id": user.id})
    refresh_token = create_refresh_token({"user_id": user.id})

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh")
def refresh(refresh_token: str, db: Session = Depends(get_db)):
    payload = decode_refresh_token(refresh_token)

    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    new_access_token = create_access_token({"user_id": payload["user_id"]})

    return {"access_token": new_access_token}



# ---------------------------------------
# 3. Получение текущего пользователя
# ---------------------------------------
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )

    user = db.query(User).filter(User.id == payload["user_id"]).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user

# ---------------------------------------
# 4. Protected route (защищённый эндпоинт)
# ---------------------------------------
@router.get("/profile")
def get_profile(credentials: HTTPAuthorizationCredentials = Depends(security),
                db: Session = Depends(get_db)):

    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user = db.query(User).filter(User.id == payload["user_id"]).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {"id": user.id, "email": user.email}


# ---------------------------------------
# 5. Logout
# ---------------------------------------
@router.post("/logout")
def logout():
    return {"message": "Logged out (token removed on client side)"}

security = [{"oauth2_scheme": []}]

@router.get("/me")
def get_me(user: User = Depends(get_current_user)):
    return {"id": user.id, "email": user.email}
