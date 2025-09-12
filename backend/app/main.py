from fastapi import FastAPI, HTTPException, Query, Depends, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.auth.depencencies import get_current_user
from app.db import models
from app.db.models import User
from app.db.models import CarHistory
from app.auth.routes import router as auth_router
from app.auth.routes_apple import router as apple_router
from app.auth.routes_email import router as email_router
from app.history.routes import router as history_router
from app.routers.user import router as user_router
from app.routers.cars import router as cars_router
from app.routers.plate_history import router as plate_history_router
from app.routers.vin_search import router as vin_router
from app.routers.comments import router as comments_router
from pydantic import BaseModel

models.Base.metadata.create_all(bind=engine)
app = FastAPI()
router = APIRouter()
app.include_router(auth_router)
app.include_router(history_router)
app.include_router(apple_router)
app.include_router(email_router)
app.include_router(user_router)
app.include_router(cars_router)
app.include_router(vin_router)
app.include_router(plate_history_router)
app.include_router(comments_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["Authorization", "Content-Type"],
)

class CarInfo(BaseModel):
    vin: str
    make: str
    model: str
    year: int
    engineCapacity: str

    class Config:
        orm_mode = True

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/api/lookup", response_model=CarInfo)
def lookup_plate(
    plate: str = Query(..., min_length=6, max_length=10),
    db: Session = Depends(get_db)
):
    plate = plate.upper()
    car = db.query(models.Car).filter(models.Car.plate == plate).first()
    if car:
        return CarInfo(
            vin=car.vin,
            make=car.make,
            model=car.model,
            year=car.year,
            engineCapacity=getattr(car, "engine_capacity", "—")
        )
    raise HTTPException(status_code=404, detail="Автомобіль не знайдено")

@app.get("/user/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    return {
        "user_id": current_user.id,
        "email": current_user.email,
        "auth_provider": current_user.auth_provider
    }

@router.get("/api/count")
def get_car_count(db: Session = Depends(get_db)):
    count = db.query(models.Car).count()
    return {"count": count}

app.include_router(router)
