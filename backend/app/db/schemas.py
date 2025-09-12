from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    email: Optional[EmailStr]
    password: Optional[str]
    auth_provider: str = "email"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    email: Optional[EmailStr]
    auth_provider: str

    class Config:
        orm_mode = True

class HistoryCreate(BaseModel):
    plate_number: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None

class CarHistorySchema(BaseModel):
    id: int
    plate: str
    vin: Optional[str] = None
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    engine_capacity: Optional[str] = None
    created_at: datetime

    class Config:
        orm_mode = True

class HistoryResponse(BaseModel):
    plate_number: str
    timestamp: datetime

    class Config:
        orm_mode = True
