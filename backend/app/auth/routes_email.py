from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.db import models
from .service import hash_password, verify_password
from .oauth import create_access_token

router = APIRouter()

class RegisterIn(BaseModel):
    email: EmailStr
    password: str

class LoginIn(BaseModel):
    email: EmailStr
    password: str

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/auth/register")
def register(body: RegisterIn, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Користувач із таким email вже існує")

    user = models.User(
        email=body.email,
        hashed_password=hash_password(body.password),
        auth_provider="email"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user_id=str(user.id), token_type="email")
    return {"access_token": token, "token_type": "bearer"}

@router.post("/auth/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == body.email).first()
    if not user or not user.hashed_password:
        raise HTTPException(status_code=401, detail="Невірні облікові дані")

    if not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Невірні облікові дані")

    token = create_access_token(user_id=str(user.id), token_type="email")
    return {"access_token": token, "token_type": "bearer"}
