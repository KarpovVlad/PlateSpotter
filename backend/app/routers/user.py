from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db.models import User
from app.db.schemas import UserUpdate
from app.auth.depencencies import get_current_user

router = APIRouter(prefix="/user", tags=["user"])

@router.put("/update")
def update_user_profile(
    update_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = db.query(User).filter(User.id == current_user.id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if update_data.name is not None:
        user.name = update_data.name
    if update_data.bio is not None:
        user.bio = update_data.bio

    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "bio": user.bio
    }
