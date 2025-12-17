"""Auth module Pydantic schemas."""

import re
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.modules.auth.models import KycLevel, UserRole


# =============================================================================
# Base schemas
# =============================================================================

class PhoneNumber(BaseModel):
    """Phone number with validation."""

    phone: str = Field(..., min_length=10, max_length=20)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Remove spaces and dashes
        v = re.sub(r"[\s\-]", "", v)
        # Ensure starts with + or digits only
        if not re.match(r"^\+?[0-9]{10,15}$", v):
            raise ValueError("Format de téléphone invalide")
        return v


# =============================================================================
# Request schemas
# =============================================================================

class SendOTPRequest(PhoneNumber):
    """Request to send OTP."""

    purpose: str = Field(default="verify", pattern="^(verify|login|reset_pin)$")


class VerifyOTPRequest(PhoneNumber):
    """Request to verify OTP."""

    code: str = Field(..., min_length=6, max_length=6, pattern="^[0-9]{6}$")
    purpose: str = Field(default="verify", pattern="^(verify|login|reset_pin)$")


class RegisterRequest(PhoneNumber):
    """User registration request."""

    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8, max_length=100)
    referral_code: Optional[str] = Field(None, max_length=20)


class LoginRequest(BaseModel):
    """Login request - phone + OTP or phone + password."""

    phone: str = Field(..., min_length=10, max_length=20)
    otp_code: Optional[str] = Field(None, min_length=6, max_length=6)
    password: Optional[str] = Field(None, min_length=8, max_length=100)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        v = re.sub(r"[\s\-]", "", v)
        if not re.match(r"^\+?[0-9]{10,15}$", v):
            raise ValueError("Format de téléphone invalide")
        return v


class RefreshTokenRequest(BaseModel):
    """Refresh token request."""

    refresh_token: str


class SetPINRequest(BaseModel):
    """Set or change PIN request."""

    pin: str = Field(..., min_length=4, max_length=6, pattern="^[0-9]{4,6}$")


class VerifyPINRequest(BaseModel):
    """Verify PIN request."""

    pin: str = Field(..., min_length=4, max_length=6, pattern="^[0-9]{4,6}$")


# =============================================================================
# Response schemas
# =============================================================================

class OTPSentResponse(BaseModel):
    """Response after OTP sent."""

    message: str = "Code envoyé"
    expires_in: int = Field(default=300, description="Seconds until expiration")


class TokenResponse(BaseModel):
    """JWT tokens response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(description="Access token expiration in seconds")


class UserResponse(BaseModel):
    """User information response."""

    id: UUID
    phone: str
    email: Optional[str] = None
    phone_verified: bool
    email_verified: bool
    role: UserRole
    kyc_level: KycLevel
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    """Full auth response with user and tokens."""

    user: UserResponse
    tokens: TokenResponse


class MessageResponse(BaseModel):
    """Generic message response."""

    message: str


# =============================================================================
# Session schemas
# =============================================================================

class SessionInfo(BaseModel):
    """Session information."""

    id: UUID
    device_type: Optional[str] = None
    ip_address: Optional[str] = None
    created_at: datetime
    is_current: bool = False

    class Config:
        from_attributes = True


class SessionListResponse(BaseModel):
    """List of user sessions."""

    sessions: list[SessionInfo]
