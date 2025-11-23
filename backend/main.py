from fastapi import FastAPI
from backend.database import engine, Base
from backend.routes.auth import router as auth_router


app = FastAPI()

Base.metadata.create_all(bind=engine)

app.include_router(auth_router, prefix="/auth", tags=["auth"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=True
    )

# для теста: авто-документация будет по адресу /docs
