import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from os import getenv
from typing import Optional

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, EmailStr, validator

app = FastAPI(
    title="Mail Service",
    description="SMTP Mail Service",
    version="1.0.0"
)

# Configuration
SMTP_HOST = getenv("SMTP_HOST") or "smtp.gmail.com"
SMTP_PORT = int(getenv("SMTP_PORT") or "587")
SMTP_USER = getenv("SMTP_USER") or ""
SMTP_PASSWORD = getenv("SMTP_PASSWORD") or ""
SMTP_USE_TLS = (getenv("SMTP_USE_TLS") or "true").lower() == "true"
DEFAULT_SENDER = getenv("DEFAULT_SENDER") or "noreply@example.com"


class SendRequest(BaseModel):
    recipients: list[EmailStr]
    subject: str
    body: str
    html: Optional[str] = None
    sender: Optional[EmailStr] = None

    @validator("recipients", pre=True)
    def validate_recipients(cls, v):
        if not v or len(v) == 0:
            raise ValueError("Recipients list cannot be empty")
        return v

    @validator("subject", pre=True)
    def validate_subject(cls, v):
        if not v or len(v) == 0:
            raise ValueError("Subject cannot be empty")
        return v

    @validator("body", pre=True)
    def validate_body(cls, v):
        if not v or len(v) == 0:
            raise ValueError("Body cannot be empty")
        return v


class SendResponse(BaseModel):
    status: str
    message: str


@app.get("/ping")
async def ping():
    """Health check endpoint"""
    return {"status": "ok"}


@app.post("/send", response_model=SendResponse, status_code=status.HTTP_200_OK)
async def send_email(request: SendRequest):
    """Send email via SMTP"""
    sender = request.sender or DEFAULT_SENDER

    try:
        # Create message
        msg = MIMEMultipart("alternative")
        msg["Subject"] = request.subject
        msg["From"] = sender
        msg["To"] = ", ".join(request.recipients)

        # Add plain text part
        msg.attach(MIMEText(request.body, "plain"))

        # Add HTML part if provided
        if request.html:
            msg.attach(MIMEText(request.html, "html"))

        # Send via SMTP
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            if SMTP_USE_TLS:
                server.starttls()
            if SMTP_USER and SMTP_PASSWORD:
                server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(sender, request.recipients, msg.as_string())

        return SendResponse(
            status="success",
            message=f"Email sent to {', '.join(request.recipients)}"
        )

    except smtplib.SMTPAuthenticationError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="SMTP authentication failed"
        )
    except smtplib.SMTPException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"SMTP error: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error sending email: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000
    )
