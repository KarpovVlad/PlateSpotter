from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.db import models
from .oauth import create_access_token
from .apple_auth import verify_apple_identity_token

router = APIRouter()

class AppleLoginIn(BaseModel):
    identity_token: str

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/auth/apple")
def apple_login(payload: AppleLoginIn, db: Session = Depends(get_db)):
    try:
        claims = verify_apple_identity_token(payload.identity_token)
        apple_sub = claims.get("sub")
        email = claims.get("email")

        if not apple_sub:
            raise HTTPException(status_code=400, detail="Не вірний токен apple")

        user = db.query(models.User).filter(models.User.apple_sub == apple_sub).first()
        if not user:
            if email:
                user = db.query(models.User).filter(models.User.email == email).first()
            if not user:
                user = models.User(email=email, auth_provider="apple", apple_sub=apple_sub)
                db.add(user)
                db.commit()
                db.refresh(user)
            else:
                user.apple_sub = apple_sub
                user.auth_provider = "apple"
                db.commit()
                db.refresh(user)

        access_token = create_access_token(user_id=str(user.id), token_type="apple")
        return {"access_token": access_token, "token_type": "bearer"}

    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Apple токен верифікація провалена: {e}")
