from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class ExtractRequest(BaseModel):
    file_id: str
    diploma_id: str


class ExtractResponse(BaseModel):
    status: str
    diploma_id: str
