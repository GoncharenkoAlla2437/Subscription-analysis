from fastapi import APIRouter, Depends, HTTPException, status, Security, Request
from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend.models.user import User
from backend.utils.security import  hash_password, verify_password, create_access_token, create_refresh_token,decode_refresh_token, decode_token
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, OAuth2PasswordRequestForm
from ..schemas.user import UserRegister, UserLogin
security = HTTPBearer()

router = APIRouter(
    prefix="/api",
    tags=["auth"]
)


# DB Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ---------------------------------------
# 1. REGISTER (регистрация)
# ---------------------------------------
@router.post("/register")
def register(user: UserRegister, db: Session = Depends(get_db)):
    print("=" * 50)
    print("✅ UserRegister model successfully validated!")
    print(f"   Email: {user.email}")
    print(f"   Password: {'*' * len(user.password)} (length: {len(user.password)})")
    print("=" * 50)
    # Проверяем существование пользователя
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        # Security best practice: не говорим точно, что email уже существует
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration failed"
        )

    # Дополнительная проверка: пароль не должен содержать email
    email_local_part = user.email.split('@')[0].lower()
    if email_local_part in user.password.lower():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password should not contain your email"
        )

    # Дополнительная проверка: пароль не равен email
    if user.password.lower() == user.email.lower():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password cannot be the same as email"
        )

    # Хэшируем пароль и создаем пользователя
    new_user = User(
        email=user.email,
        password=hash_password(user.password)  # ✅ используем только password
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return {
            "message": "User registered successfully",
            "user_id": new_user.id,
            "email": new_user.email
        }

    except Exception as e:
        db.rollback()
        # Логируем ошибку для администратора
        import logging
        logger = logging.getLogger(__name__)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed, please try again"
        )


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



@router.post("/logout")
def logout():
    return {"message": "Logged out (token removed on client side)"}

@router.get("/me")
def get_me(user: User = Depends(get_current_user)):
    return {"id": user.id, "email": user.email}


@router.post("/test-validation")
async def test_validation(request: Request):
    try:
        raw_data = await request.json()
        print("📦 Raw data received:", raw_data)

        user = UserRegister(**raw_data)

        return {
            "success": True,
            "message": "✅ Validation passed",
            "data": {
                "email": user.email,
                "password_length": len(user.password),
                "confirm_password_length": len(user.confirm_password)
            }
        }

    except Exception as e:
        print("❌ Validation error:", str(e))
        import traceback
        traceback.print_exc()

        return {
            "success": False,
            "error": str(e),
            "type": type(e).__name__,
            "raw_data": raw_data
        }