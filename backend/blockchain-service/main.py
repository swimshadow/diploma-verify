import os
import sys
import uuid
from fastapi import FastAPI
from loguru import logger

from database import engine
from models import Base
from routers import router as blockchain_router

logger.remove()
logger.add(sys.stdout, level="INFO")

app = FastAPI(
    title="Blockchain Service",
    description="Append-only blockchain for diploma verification",
    version="1.0.0",
)

try:
    from payload_crypto import PayloadEncryptionMiddleware
    app.add_middleware(PayloadEncryptionMiddleware)
except Exception:
    pass

app.include_router(blockchain_router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "blockchain-service"}


@app.on_event("startup")
def create_tables():
    Base.metadata.create_all(bind=engine)
    from sqlalchemy.orm import Session
    from models import BlockchainRecord

    from database import SessionLocal

    db = SessionLocal()
    try:
        existing = db.query(BlockchainRecord).count()
        if existing == 0:
            genesis = {
                "index": 0,
                "timestamp": "2024-01-01T00:00:00",
                "diploma_id": str(uuid.UUID("00000000-0000-0000-0000-000000000000")),
                "data_hash": "genesis",
                "previous_hash": "0" * 64,
                "nonce": 0,
            }
            from routers import calculate_hash
            genesis["block_hash"] = calculate_hash(genesis)
            record = BlockchainRecord(
                block_index=0,
                timestamp=genesis["timestamp"],
                diploma_id=genesis["diploma_id"],
                data_hash=genesis["data_hash"],
                previous_hash=genesis["previous_hash"],
                block_hash=genesis["block_hash"],
                nonce=0,
            )
            db.add(record)
            db.commit()
    finally:
        db.close()
