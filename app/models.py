from sqlalchemy import Column
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy.orm import DeclarativeBase

from app.db import metadata


class Base(DeclarativeBase):
    metadata = metadata


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    balance = Column(Integer, nullable=False)

    def __repr__(self) -> str:
        return f"<User(id={self.id}, username={self.username}, balance={self.balance})>"
