from fastapi import Depends, APIRouter, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from datetime import datetime, timedelta
from .service import SECRET_KEY, ALGORITHM

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

class UserMeResponse(BaseModel):
    user_id: str
    token_type: str
    expires_in: int

def create_access_token(user_id: str, token_type: str, expires_delta: timedelta = timedelta(hours=1)):
    to_encode = {
        "sub": user_id,
        "type": token_type,
        "exp": datetime.utcnow() + expires_delta
    }
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        exp_timestamp = payload.get("exp")

        if user_id is None or token_type is None:
            raise HTTPException(status_code=401, detail="Invalid token payload")

        expires_in = exp_timestamp - int(datetime.utcnow().timestamp())

        return {
            "user_id": user_id,
            "token_type": token_type,
            "expires_in": expires_in
        }
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@router.get("/user/me", response_model=UserMeResponse)
async def read_users_me(token: str = Depends(oauth2_scheme)):
    return decode_access_token(token)
