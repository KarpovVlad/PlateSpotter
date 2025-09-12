from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from .database import Base

class Car(Base):
    __tablename__ = "cars"

    id = Column(Integer, primary_key=True, index=True)
    vin = Column(String, unique=True, index=True)
    plate = Column(String, index=True)
    make = Column(String)
    model = Column(String)
    year = Column(Integer)
    engine_capacity = Column(String)

class CarHistory(Base):
    __tablename__ = "car_history"

    id = Column(Integer, primary_key=True, index=True)
    plate = Column(String, index=True)
    vin = Column(String, nullable=True)
    make = Column(String, nullable=True)
    model = Column(String, nullable=True)
    year = Column(Integer, nullable=True)
    engine_capacity = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=True)
    auth_provider = Column(String, default="email")
    apple_sub = Column(String, unique=True, index=True, nullable=True)
    name = Column(String, nullable=True)
    bio = Column(String, nullable=True)

class Comment(Base):
    __tablename__ = "comments"
    id = Column(Integer, primary_key=True, index=True)
    plate = Column(String, index=True)
    author = Column(String)
    text = Column(String)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)
    plate_number = Column(String, index=True)
    timestamp = Column(DateTime, server_default=func.now())
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User", backref="history")
