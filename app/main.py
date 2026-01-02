from fastapi import Depends
from fastapi import FastAPI

from app.dependencies.get_current_user import get_current_user
from app.models import User


app = FastAPI()


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/")
def index(
    current_user: User = Depends(get_current_user),
):
    return f"Hello, {current_user.username}!"
