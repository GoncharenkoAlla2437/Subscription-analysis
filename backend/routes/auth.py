from fastapi import APIRouter, Depends, HTTPException, status, Security, Request
from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend.models.user import User
from backend.utils.security import  hash_password, verify_password, create_access_token, create_refresh_token,decode_refresh_token, decode_token
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, OAuth2PasswordRequestForm
from ..schemas.user import UserRegister, UserLogin
from backend.models.notification import Notification
from backend.database import get_db
security = HTTPBearer()

router = APIRouter(
    prefix="/api",
    tags=["auth"]
)


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
    print("=" * 60)
    print(f"🔍 LOGIN ATTEMPT for email: {data.email}")
    print(f"   Password length: {len(data.password)}")

    # 1. ОЧИСТКА КЕША СЕССИИ
    db.expire_all()
    print("   ✅ Session cache cleared")

    # 2. ДИАГНОСТИКА: проверяем ВСЕХ пользователей
    all_users = db.query(User).all()
    print(f"   📊 Total users in current session: {len(all_users)}")

    if all_users:
        for u in all_users:
            print(f"     - ID: {u.id}, Email: {u.email}")
    else:
        print("     ❌ No users found in session!")

    # 3. RAW SQL запрос (обход кеша SQLAlchemy)
    from sqlalchemy import text
    try:
        sql_result = db.execute(
            text("SELECT id, email, password FROM users WHERE email = :email"),
            {"email": data.email}
        ).first()

        if sql_result:
            print(f"   🔍 User FOUND via raw SQL: ID={sql_result[0]}, Email={sql_result[1]}")
            print(f"   🔍 Hashed password from SQL: {sql_result[2][:30]}...")
        else:
            print(f"   🔍 User NOT FOUND via raw SQL")
    except Exception as e:
        print(f"   ⚠️ Raw SQL error: {e}")

    # 4. ORM запрос (может быть закешировано)
    user = db.query(User).filter(User.email == data.email).first()

    if user:
        print(f"   ✅ User found via ORM: ID={user.id}, Email={user.email}")
        print(f"   🔑 Hashed password from ORM: {user.password[:30]}...")

        # 5. ПРОВЕРКА ПАРОЛЯ
        is_password_valid = verify_password(data.password, user.password)
        print(f"   🔐 Password verification: {is_password_valid}")

        if not is_password_valid:
            print("   ❌ Password verification FAILED")
            print("=" * 60)
            raise HTTPException(status_code=400, detail="Invalid email or password")
    else:
        print(f"   ❌ User NOT FOUND via ORM")
        print("=" * 60)
        raise HTTPException(status_code=400, detail="Invalid email or password")

    # 6. СОЗДАНИЕ ТОКЕНОВ
    try:
        access_token = create_access_token({"user_id": user.id})
        refresh_token = create_refresh_token({"user_id": user.id})

        print(f"   🎫 Access token created: {access_token[:30]}...")
        print(f"   🎫 Refresh token created: {refresh_token[:30]}...")
        print(f"   ✅ LOGIN SUCCESSFUL for user ID: {user.id}")

    except Exception as e:
        print(f"   ❌ Token creation error: {e}")
        raise HTTPException(status_code=500, detail="Token creation failed")

    print("=" * 60)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user_id": user.id,  # ⚠️ ДОБАВЬТЕ это для фронтенда
        "message": "Login successful"
    }
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