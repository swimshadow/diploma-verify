from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel


class AddBlockRequest(BaseModel):
    diploma_id: UUID
    data_hash: str


class AddBlockResponse(BaseModel):
    block_index: int
    block_hash: str
    nonce: int


class BlockItem(BaseModel):
    block_index: int
    timestamp: str
    diploma_id: UUID
    data_hash: str
    previous_hash: str
    block_hash: str
    nonce: int


class BlockchainVerifyResponse(BaseModel):
    valid: bool
    block_index: Optional[int] = None
    block_hash: Optional[str] = None
    timestamp: Optional[str] = None
    chain_intact: bool


class BlockchainChainResponse(BaseModel):
    blocks: List[BlockItem]


class BlockchainValidateResponse(BaseModel):
    valid: bool
    total_blocks: int
    broken_at_index: Optional[int] = None
