from fastapi import APIRouter
from .oauth import create_access_token

router = APIRouter()

@router.post("/auth/email")
async def email_login():
    user_id = "55"
    access_token = create_access_token(
        user_id=user_id,
        token_type="email"
    )
    return {"access_token": access_token, "token_type": "bearer"}
