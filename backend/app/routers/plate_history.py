from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.models import CarHistory
from app.db.schemas import CarHistorySchema
from app.db.database import get_db

router = APIRouter(prefix="/api/plate_history", tags=["plate_history"])

@router.get("/plate_history/{plate}", response_model=list[CarHistorySchema])
def get_plate_history(plate: str, db: Session = Depends(get_db)):
    history = db.query(CarHistory).filter(CarHistory.plate == plate).all()
    if not history:
        raise HTTPException(status_code=404, detail="No history found for this plate")
    return history
