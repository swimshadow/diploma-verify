from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class UploadResponse(BaseModel):
    file_id: str
    original_name: str
    size_bytes: int
