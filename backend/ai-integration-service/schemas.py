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


class ExtractedDataPayload(BaseModel):
    full_name: str
    diploma_number: str
    series: str
    degree: str
    specialization: str
    issue_date: str


class AiResultRequest(BaseModel):
    diploma_id: str
    extracted_data: ExtractedDataPayload
    confidence: float
    raw_text: str
    processing_time_ms: int


class AiResultResponse(BaseModel):
    received: bool
    diploma_id: str
    next_status: str
