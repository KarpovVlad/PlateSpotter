from collections import defaultdict
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict, List
from app.db.database import get_db
from app.db.models import Car

router = APIRouter(prefix="/cars", tags=["cars"])

@router.get("/brands", response_model=list[str])
def get_brands(db: Session = Depends(get_db)):
    brands = db.query(Car.make).distinct().all()
    return sorted([b[0] for b in brands if b[0]])

@router.get("/{brand}/models", response_model=list[str])
def get_models(brand: str, db: Session = Depends(get_db)):
    models = db.query(Car.model).filter(Car.make.ilike(brand)).distinct().all()
    if not models:
        raise HTTPException(status_code=404, detail="Бренд не знайдено")
    return sorted([m[0] for m in models if m[0]])

@router.get("/{brand}/{model}/plates", response_model=list[str])
def get_plates(brand: str, model: str, db: Session = Depends(get_db)):
    plates = db.query(Car.plate).filter(
        Car.make.ilike(brand),
        Car.model.ilike(model)
    ).all()
    if not plates:
        raise HTTPException(status_code=404, detail="Номери не знайдено")
    return [p[0] for p in plates if p[0]]

@router.get("/{brand}/{model}/plates/grouped", response_model=Dict[str, List[str]])
def get_grouped_plates(brand: str, model: str, db: Session = Depends(get_db)):
    cars = db.query(Car.plate).filter(
        Car.make.ilike(brand),
        Car.model.ilike(model)
    ).all()
    if not cars:
        raise HTTPException(status_code=404, detail="Номери не знайдено")

    grouped = defaultdict(list)
    for (plate,) in cars:
        if not plate:
            continue
        prefix = plate[:2].upper() if len(plate) >= 2 else "??"
        grouped[prefix].append(plate)

    return {k: sorted(v) for k, v in sorted(grouped.items())}
