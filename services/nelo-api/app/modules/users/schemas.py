"""Users module Pydantic schemas."""

import re
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


# =============================================================================
# Base schemas
# =============================================================================

class CityBase(BaseModel):
    """City base schema."""

    id: UUID
    name: str
    slug: str

    class Config:
        from_attributes = True


class ZoneBase(BaseModel):
    """Zone base schema."""

    id: UUID
    name: str
    slug: str

    class Config:
        from_attributes = True


# =============================================================================
# Profile schemas
# =============================================================================

class ProfileBase(BaseModel):
    """Profile base schema."""

    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    display_name: Optional[str] = Field(None, max_length=100)
    email: Optional[EmailStr] = None
    preferred_language: str = Field(default="fr", pattern="^(fr|en)$")


class ProfileUpdate(ProfileBase):
    """Profile update request."""

    default_city_id: Optional[UUID] = None
    default_zone_id: Optional[UUID] = None
    notification_settings: Optional[dict] = None


class NotificationSettings(BaseModel):
    """Notification settings."""

    push: bool = True
    sms: bool = True
    email: bool = False


class ProfileResponse(BaseModel):
    """Profile response."""

    id: UUID
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone: str
    email: Optional[str] = None
    default_city: Optional[CityBase] = None
    default_zone: Optional[ZoneBase] = None
    preferred_language: str
    notification_settings: dict
    total_orders: int
    total_spent: int
    average_rating: Optional[Decimal] = None
    referral_code: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# =============================================================================
# Address schemas
# =============================================================================

class AddressBase(BaseModel):
    """Address base schema."""

    label: str = Field(default="home", max_length=50)
    name: Optional[str] = Field(None, max_length=100)
    address_line1: str = Field(..., max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    landmark: Optional[str] = Field(None, max_length=255)
    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)
    contact_phone: Optional[str] = Field(None, max_length=20)

    @field_validator("contact_phone")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        v = re.sub(r"[\s\-]", "", v)
        if not re.match(r"^\+?[0-9]{10,15}$", v):
            raise ValueError("Format de téléphone invalide")
        return v


class AddressCreate(AddressBase):
    """Create address request."""

    city_id: Optional[UUID] = None
    zone_id: Optional[UUID] = None
    is_default: bool = False


class AddressUpdate(BaseModel):
    """Update address request."""

    label: Optional[str] = Field(None, max_length=50)
    name: Optional[str] = Field(None, max_length=100)
    address_line1: Optional[str] = Field(None, max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    landmark: Optional[str] = Field(None, max_length=255)
    latitude: Optional[Decimal] = Field(None, ge=-90, le=90)
    longitude: Optional[Decimal] = Field(None, ge=-180, le=180)
    contact_phone: Optional[str] = Field(None, max_length=20)
    city_id: Optional[UUID] = None
    zone_id: Optional[UUID] = None
    is_default: Optional[bool] = None


class AddressResponse(BaseModel):
    """Address response."""

    id: UUID
    label: str
    name: Optional[str] = None
    address_line1: str
    address_line2: Optional[str] = None
    landmark: Optional[str] = None
    city: Optional[CityBase] = None
    zone: Optional[ZoneBase] = None
    latitude: Decimal
    longitude: Decimal
    contact_phone: Optional[str] = None
    is_default: bool
    created_at: datetime

    class Config:
        from_attributes = True


class AddressListResponse(BaseModel):
    """List of addresses."""

    addresses: list[AddressResponse]
    total: int


# =============================================================================
# Favorite schemas
# =============================================================================

class FavoriteCreate(BaseModel):
    """Create favorite request."""

    favorite_type: str = Field(..., pattern="^(provider|product|driver)$")
    entity_id: UUID


class FavoriteResponse(BaseModel):
    """Favorite response."""

    id: UUID
    favorite_type: str
    entity_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


# =============================================================================
# Loyalty schemas
# =============================================================================

class LoyaltyResponse(BaseModel):
    """Loyalty points response."""

    points_balance: int
    tier: str
    next_tier: Optional[str] = None
    points_to_next_tier: Optional[int] = None

    class Config:
        from_attributes = True
