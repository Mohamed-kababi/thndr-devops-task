from pydantic import BaseModel


class User(BaseModel):
    id: int
    username: str

    class Config:
        from_attributes = True
