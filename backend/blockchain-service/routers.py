import hashlib
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import BlockchainRecord
from schemas import (
    AddBlockRequest,
    AddBlockResponse,
    BlockchainChainResponse,
    BlockchainValidateResponse,
    BlockchainVerifyResponse,
    BlockItem,
)

router = APIRouter(prefix="/blockchain", tags=["blockchain"])


def calculate_hash(block_data: dict) -> str:
    data = f"{block_data['index']}{block_data['timestamp']}{block_data['diploma_id']}{block_data['data_hash']}{block_data['previous_hash']}{block_data['nonce']}"
    return hashlib.sha256(data.encode()).hexdigest()


def proof_of_work(block_data: dict) -> tuple[str, int]:
    nonce = 0
    while True:
        block_data["nonce"] = nonce
        block_hash = calculate_hash(block_data)
        if block_hash.startswith("00"):
            return block_hash, nonce
        nonce += 1


def _record_to_block(record: BlockchainRecord) -> dict:
    return {
        "block_index": record.block_index,
        "timestamp": record.timestamp,
        "diploma_id": record.diploma_id,
        "data_hash": record.data_hash,
        "previous_hash": record.previous_hash,
        "block_hash": record.block_hash,
        "nonce": record.nonce,
    }


@router.post("/add", response_model=AddBlockResponse)
def add_block(payload: AddBlockRequest, db: Session = Depends(get_db)):
    last = db.query(BlockchainRecord).order_by(BlockchainRecord.block_index.desc()).first()
    previous_hash = "0" * 64 if last is None else last.block_hash
    block_index = 0 if last is None else last.block_index + 1
    block_data = {
        "index": block_index,
        "timestamp": datetime.utcnow().replace(microsecond=0).isoformat(),
        "diploma_id": str(payload.diploma_id),
        "data_hash": payload.data_hash,
        "previous_hash": previous_hash,
        "nonce": 0,
    }
    block_hash, nonce = proof_of_work(block_data)
    record = BlockchainRecord(
        block_index=block_index,
        timestamp=block_data["timestamp"],
        diploma_id=payload.diploma_id,
        data_hash=payload.data_hash,
        previous_hash=previous_hash,
        block_hash=block_hash,
        nonce=nonce,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return AddBlockResponse(block_index=block_index, block_hash=block_hash, nonce=nonce)


@router.get("/verify/{diploma_id}", response_model=BlockchainVerifyResponse)
def verify_block(diploma_id: UUID, db: Session = Depends(get_db)):
    record = (
        db.query(BlockchainRecord)
        .filter(BlockchainRecord.diploma_id == diploma_id)
        .order_by(BlockchainRecord.block_index.desc())
        .first()
    )
    if record is None:
        return BlockchainVerifyResponse(valid=False, chain_intact=False)
    recalculated = calculate_hash(
        {
            "index": record.block_index,
            "timestamp": record.timestamp,
            "diploma_id": str(record.diploma_id),
            "data_hash": record.data_hash,
            "previous_hash": record.previous_hash,
            "nonce": record.nonce,
        }
    )
    chain_intact = True
    if recalculated != record.block_hash:
        return BlockchainVerifyResponse(
            valid=False,
            block_index=record.block_index,
            block_hash=record.block_hash,
            timestamp=record.timestamp,
            chain_intact=False,
        )
    if record.block_index != 0:
        previous = (
            db.query(BlockchainRecord)
            .filter(BlockchainRecord.block_index == record.block_index - 1)
            .first()
        )
        chain_intact = previous is not None and previous.block_hash == record.previous_hash
    return BlockchainVerifyResponse(
        valid=True,
        block_index=record.block_index,
        block_hash=record.block_hash,
        timestamp=record.timestamp,
        chain_intact=chain_intact,
    )


@router.get("/chain", response_model=BlockchainChainResponse)
def get_chain(db: Session = Depends(get_db)):
    records = (
        db.query(BlockchainRecord)
        .order_by(BlockchainRecord.block_index.desc())
        .limit(50)
        .all()
    )
    blocks = [_record_to_block(r) for r in reversed(records)]
    return BlockchainChainResponse(blocks=blocks)


@router.get("/validate", response_model=BlockchainValidateResponse)
def validate_chain(db: Session = Depends(get_db)):
    records = db.query(BlockchainRecord).order_by(BlockchainRecord.block_index.asc()).all()
    previous_hash = "0" * 64
    for record in records:
        recalculated = calculate_hash(
            {
                "index": record.block_index,
                "timestamp": record.timestamp,
                "diploma_id": str(record.diploma_id),
                "data_hash": record.data_hash,
                "previous_hash": record.previous_hash,
                "nonce": record.nonce,
            }
        )
        if recalculated != record.block_hash:
            return BlockchainValidateResponse(
                valid=False,
                total_blocks=len(records),
                broken_at_index=record.block_index,
            )
        if record.block_index != 0 and record.previous_hash != previous_hash:
            return BlockchainValidateResponse(
                valid=False,
                total_blocks=len(records),
                broken_at_index=record.block_index,
            )
        previous_hash = record.block_hash
    return BlockchainValidateResponse(valid=True, total_blocks=len(records))
