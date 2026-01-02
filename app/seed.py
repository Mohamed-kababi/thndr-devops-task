from sqlalchemy import delete

from app.db import session_factory
from app.models import User

session = session_factory()

session.execute(delete(User))

for i in range(10):
    user = User(username=f"user_{i}", balance=10000 * i)
    session.add(user)

session.commit()
