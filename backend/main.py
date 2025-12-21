from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

# Импортируем роутер из auth.py
from backend.routes.auth import router as auth_router
from backend.routes.subs import router as subs_router

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене укажи конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутер аутентификации
app.include_router(auth_router)
app.include_router(subs_router)

# Базовые эндпоинты
@app.get("/")
async def root():
    return {"message": "Subscription Analyzer API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)