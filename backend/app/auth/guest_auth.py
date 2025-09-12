from fastapi import APIRouter
from .oauth import create_access_token

router = APIRouter()

@router.post("/auth/guest")
async def guest_login():
    access_token = create_access_token(
        user_id="15",
        token_type="guest"
    )
    return {"access_token": access_token, "token_type": "bearer"}
