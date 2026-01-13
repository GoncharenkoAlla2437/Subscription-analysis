from sys import prefix
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
import logging
from sqlalchemy.orm import Session
from backend.routes.auth import router as auth_router
from backend.routes.subs import router as subs_router
from backend.routes.notifications import router as notifications_router
from backend.routes.analytics import router as analytics_router
import backend.database
from backend.database import init_db

init_db()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ИЗМЕНЕНИЕ 1: Добавить название и docs (2 строки)
app = FastAPI(
    title="Subscription Analyzer API",
    docs_url="/docs"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(subs_router)
app.include_router(notifications_router)
app.include_router(analytics_router) 

@app.get("/")
async def root():
    return {"message": "Subscription Analyzer API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)