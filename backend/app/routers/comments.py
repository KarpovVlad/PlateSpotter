import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth.depencencies import get_current_user
from app.db.models import Comment, User
from app.db.database import get_db

router = APIRouter(prefix="/api/comments", tags=["comments"])

@router.get("/{plate}")
async def get_comments(plate: str, db: Session = Depends(get_db)):
    comments = (
        db.query(Comment)
        .filter(Comment.plate == plate)
        .order_by(Comment.timestamp.desc())
        .all()
    )
    return comments

@router.post("/{plate}", status_code=201)
async def add_comment(
    plate: str,
    data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    text = data.get("text", "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Порожній коментар")

    if contains_profanity(text):
        raise HTTPException(status_code=400, detail="Коментар містить заборонені слова")

    comment = Comment(
        plate=plate,
        author=current_user.name if current_user.name else current_user.email,
        text=text,
        timestamp=datetime.datetime.utcnow(),
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment

def contains_profanity(text: str) -> bool:
    words = set(text.lower().split())
    return any(bad in words for bad in BAD_WORDS)

BAD_WORDS = {"дурень", "лайка", "*****"}
