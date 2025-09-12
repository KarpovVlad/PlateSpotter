from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.db.models import SearchHistory
from app.db.schemas import HistoryResponse, HistoryCreate
from app.auth.depencencies import get_current_user

router = APIRouter(prefix="/history", tags=["History"])

@router.post("/", operation_id="history_add", response_model=HistoryResponse)
async def add_history(item: HistoryCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.auth_provider == "guest":
        return {"plate_number": item.plate_number, "timestamp": None}

    record = SearchHistory(plate_number=item.plate_number, user_id=current_user.id)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record

@router.get("/", operation_id="history_get", response_model=List[HistoryResponse])
async def get_history(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.auth_provider == "guest":
        return []
    return db.query(SearchHistory).filter(SearchHistory.user_id == current_user.id) \
        .order_by(SearchHistory.timestamp.desc()).limit(10).all()
