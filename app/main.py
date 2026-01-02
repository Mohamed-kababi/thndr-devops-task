from decimal import Decimal
from fastapi import Depends, HTTPException
from fastapi import FastAPI
from pydantic import BaseModel, Field

from app.dependencies.get_current_user import get_current_user
from app.models import User
from app.db import session_factory


app = FastAPI()


class AmountRequest(BaseModel):
    amount: Decimal = Field(..., gt=0, description="Amount must be positive")


class BalanceResponse(BaseModel):
    username: str
    balance: Decimal
    message: str


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/")
def index(
    current_user: User = Depends(get_current_user),
):
    return f"Hello, {current_user.username}!"


@app.post("/deposit", response_model=BalanceResponse)
def deposit(
    request: AmountRequest,
    current_user: User = Depends(get_current_user),
):
    """Deposit money into the user's balance."""
    # Convert to cents to handle fractional amounts correctly
    amount_cents = int(request.amount * 100)

    with session_factory() as session:
        user = session.query(User).filter(User.id == current_user.id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        user.balance += amount_cents
        session.commit()
        session.refresh(user)

        return BalanceResponse(
            username=user.username,
            balance=Decimal(user.balance) / 100,
            message=f"Successfully deposited {request.amount}"
        )


@app.post("/withdraw", response_model=BalanceResponse)
def withdraw(
    request: AmountRequest,
    current_user: User = Depends(get_current_user),
):
    """Withdraw money from the user's balance."""
    # Convert to cents to handle fractional amounts correctly
    amount_cents = int(request.amount * 100)

    with session_factory() as session:
        user = session.query(User).filter(User.id == current_user.id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        if user.balance < amount_cents:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient balance. Current balance: {Decimal(user.balance) / 100}"
            )

        user.balance -= amount_cents
        session.commit()
        session.refresh(user)

        return BalanceResponse(
            username=user.username,
            balance=Decimal(user.balance) / 100,
            message=f"Successfully withdrew {request.amount}"
        )
