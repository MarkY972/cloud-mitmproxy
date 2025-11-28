from sqlalchemy import Column, Integer, String
from .database import Base

class Instance(Base):
    __tablename__ = "instances"

    id = Column(Integer, primary_key=True, index=True)
    task_arn = Column(String, unique=True, index=True)
    status = Column(String)
    public_ip = Column(String)
