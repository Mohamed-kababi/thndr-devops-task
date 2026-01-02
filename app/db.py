from sqlalchemy import create_engine
from sqlalchemy import MetaData
from sqlalchemy.orm import sessionmaker

metadata = MetaData()

# Create a sync engine and session factory
engine = create_engine("sqlite:///./db.sqlite")
session_factory = sessionmaker(engine)
