from fastapi import HTTPException
from fastapi import Request
from fastapi import status

from app.db import session_factory
from app.models import User


def get_current_user(request: Request) -> User:
    if user_id := request.headers.get("user_id", None):
        with session_factory() as session:
            user = session.get(User, user_id)
            if user:
                return user
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
