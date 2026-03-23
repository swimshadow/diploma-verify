import uuid
from sqlalchemy import Column, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class BlockchainRecord(Base):
    __tablename__ = "blockchain_records"

    id = Column(Integer, primary_key=True, autoincrement=True)
    block_index = Column(Integer, unique=True, nullable=False)
    timestamp = Column(String(50), nullable=False)
    diploma_id = Column(UUID(as_uuid=True), nullable=False)
    data_hash = Column(String(255), nullable=False)
    previous_hash = Column(String(255), nullable=False)
    block_hash = Column(String(255), unique=True, nullable=False)
    nonce = Column(Integer, nullable=False)
