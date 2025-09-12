from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db.models import User
from app.db.schemas import UserCreate, UserLogin, UserResponse
from .service import hash_password, verify_password
from .oauth import create_access_token

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/signup", operation_id="auth_signup", response_model=UserResponse)
async def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    if user_data.auth_provider == "email":
        if not user_data.email or not user_data.password:
            raise HTTPException(status_code=400, detail="Email та пароль обов’язкові")
        if db.query(User).filter(User.email == user_data.email).first():
            raise HTTPException(status_code=400, detail="Користувач вже існує")
        hashed_pw = hash_password(user_data.password)
        user = User(email=user_data.email, hashed_password=hashed_pw, auth_provider="email")
    elif user_data.auth_provider == "guest":
        user = User(email=None, hashed_password=None, auth_provider="guest")
    else:
        raise HTTPException(status_code=400, detail="Невідомий тип авторизації")

    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", operation_id="auth_login")
async def login(login_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Невірний email або пароль")
    token = create_access_token(
        user_id=str(user.id),
        token_type="access"
    )
    return {"access_token": token, "token_type": "bearer"}

@router.post("/guest", operation_id="auth_guest_login")
async def guest_login(db: Session = Depends(get_db)):
    user = User(email=None, hashed_password=None, auth_provider="guest")
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(
        user_id=str(user.id),
        token_type="access"
    )
    return {"access_token": token, "token_type": "bearer"}
