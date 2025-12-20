"""Deliveries module Pydantic schemas - drivers, deliveries, offers."""

from datetime import datetime, time
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =============================================================================
# Driver Schemas
# =============================================================================


class DriverVehicleInfo(BaseModel):
    """Driver vehicle information."""

    type: str = Field(..., pattern="^(motorcycle|bicycle|car|scooter)$")
    plate_number: Optional[str] = Field(None, max_length=20)
    brand: Optional[str] = Field(None, max_length=50)
    model: Optional[str] = Field(None, max_length=50)
    color: Optional[str] = Field(None, max_length=30)
    year: Optional[int] = Field(None, ge=1990, le=2030)


class DriverRegister(BaseModel):
    """Driver registration schema."""

    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=8, max_length=20)
    email: Optional[str] = None
    city_id: UUID
    zone_id: Optional[UUID] = None
    vehicle: DriverVehicleInfo
    id_number: Optional[str] = Field(None, max_length=50)
    license_number: Optional[str] = Field(None, max_length=50)


class DriverUpdate(BaseModel):
    """Driver profile update schema."""

    first_name: Optional[str] = Field(None, min_length=2, max_length=100)
    last_name: Optional[str] = Field(None, min_length=2, max_length=100)
    email: Optional[str] = None
    photo_url: Optional[str] = None
    zone_id: Optional[UUID] = None


class DriverVehicleUpdate(BaseModel):
    """Driver vehicle update schema."""

    type: Optional[str] = Field(None, pattern="^(motorcycle|bicycle|car|scooter)$")
    plate_number: Optional[str] = Field(None, max_length=20)
    brand: Optional[str] = Field(None, max_length=50)
    model: Optional[str] = Field(None, max_length=50)
    color: Optional[str] = Field(None, max_length=30)
    year: Optional[int] = Field(None, ge=1990, le=2030)


class DriverLocationUpdate(BaseModel):
    """Driver location update schema."""

    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)
    heading: Optional[Decimal] = Field(None, ge=0, le=360)
    speed: Optional[Decimal] = Field(None, ge=0)


class DriverStatusUpdate(BaseModel):
    """Driver status update schema."""

    is_online: bool


class DriverAvailabilityCreate(BaseModel):
    """Driver availability schedule creation."""

    day_of_week: int = Field(..., ge=0, le=6)  # 0 = Monday
    start_time: time
    end_time: time
    is_active: bool = True


class DriverAvailabilityResponse(BaseModel):
    """Driver availability response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    day_of_week: int
    start_time: time
    end_time: time
    is_active: bool = True


class DriverSummary(BaseModel):
    """Driver summary for list views."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    first_name: str
    last_name: str
    phone: str
    photo_url: Optional[str] = None
    vehicle_type: str
    average_rating: Optional[Decimal] = None
    rating_count: int = 0
    total_deliveries: int = 0
    is_online: bool = False
    is_available: bool = False


class DriverResponse(BaseModel):
    """Full driver response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    first_name: str
    last_name: str
    phone: str
    email: Optional[str] = None
    photo_url: Optional[str] = None
    city_id: UUID
    zone_id: Optional[UUID] = None
    vehicle_type: str
    vehicle_plate_number: Optional[str] = None
    vehicle_brand: Optional[str] = None
    vehicle_model: Optional[str] = None
    vehicle_color: Optional[str] = None
    vehicle_year: Optional[int] = None
    id_number: Optional[str] = None
    license_number: Optional[str] = None
    average_rating: Optional[Decimal] = None
    rating_count: int = 0
    total_deliveries: int = 0
    total_earnings: int = 0
    status: str = "pending"
    is_online: bool = False
    is_available: bool = False
    current_latitude: Optional[Decimal] = None
    current_longitude: Optional[Decimal] = None
    location_updated_at: Optional[datetime] = None
    commission_rate: Decimal = Decimal("0.10")
    created_at: datetime
    updated_at: datetime
    availability_schedules: list[DriverAvailabilityResponse] = []


class DriverListResponse(BaseModel):
    """Driver list response with pagination."""

    drivers: list[DriverSummary]
    total: int
    page: int = 1
    page_size: int = 20
    has_next: bool = False


class DriverDocumentCreate(BaseModel):
    """Driver document upload schema."""

    type: str = Field(
        ..., pattern="^(id_card|driver_license|vehicle_registration|insurance)$"
    )
    document_url: str
    expiry_date: Optional[datetime] = None


class DriverDocumentResponse(BaseModel):
    """Driver document response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    type: str
    document_url: str
    status: str = "pending"
    expiry_date: Optional[datetime] = None
    verified_at: Optional[datetime] = None
    created_at: datetime


class DriverEarningsResponse(BaseModel):
    """Driver earnings summary."""

    total_earnings: int = 0
    today_earnings: int = 0
    week_earnings: int = 0
    month_earnings: int = 0
    pending_payout: int = 0
    total_deliveries: int = 0
    today_deliveries: int = 0


# =============================================================================
# Delivery Offer Schemas
# =============================================================================


class DeliveryOfferResponse(BaseModel):
    """Delivery offer response for drivers."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    delivery_id: UUID
    order_reference: str
    provider_name: str
    provider_address: str
    pickup_latitude: Decimal
    pickup_longitude: Decimal
    delivery_address: str
    delivery_latitude: Decimal
    delivery_longitude: Decimal
    estimated_distance_km: Decimal
    estimated_duration_minutes: int
    delivery_fee: int
    driver_earnings: int
    expires_at: datetime
    status: str = "pending"
    created_at: datetime


class DeliveryOfferAction(BaseModel):
    """Delivery offer action (accept/reject)."""

    reason: Optional[str] = Field(None, max_length=200)  # For rejection


# =============================================================================
# Delivery Schemas
# =============================================================================


class DeliveryCreate(BaseModel):
    """Delivery creation schema (internal use)."""

    order_id: UUID
    pickup_address: str
    pickup_latitude: Decimal = Field(..., ge=-90, le=90)
    pickup_longitude: Decimal = Field(..., ge=-180, le=180)
    delivery_address: str
    delivery_latitude: Decimal = Field(..., ge=-90, le=90)
    delivery_longitude: Decimal = Field(..., ge=-180, le=180)
    delivery_fee: int = Field(..., ge=0)
    estimated_distance_km: Optional[Decimal] = None
    estimated_duration_minutes: Optional[int] = None
    special_instructions: Optional[str] = Field(None, max_length=500)


class DeliveryStatusUpdate(BaseModel):
    """Delivery status update schema."""

    status: str = Field(
        ...,
        pattern="^(assigned|en_route_pickup|arrived_pickup|picked_up|en_route_delivery|arrived_delivery|delivered|failed|cancelled)$",
    )
    notes: Optional[str] = Field(None, max_length=500)
    latitude: Optional[Decimal] = Field(None, ge=-90, le=90)
    longitude: Optional[Decimal] = Field(None, ge=-180, le=180)


class DeliveryConfirmation(BaseModel):
    """Delivery confirmation by driver."""

    confirmation_code: str = Field(..., min_length=6, max_length=6)
    signature_url: Optional[str] = None
    photo_url: Optional[str] = None


class DeliveryStatusHistoryResponse(BaseModel):
    """Delivery status history entry."""

    model_config = ConfigDict(from_attributes=True)

    status: str
    notes: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    created_at: datetime


class DeliveryLocationHistoryResponse(BaseModel):
    """Delivery location history entry."""

    model_config = ConfigDict(from_attributes=True)

    latitude: Decimal
    longitude: Decimal
    heading: Optional[Decimal] = None
    speed: Optional[Decimal] = None
    recorded_at: datetime


class DeliverySummary(BaseModel):
    """Delivery summary for list views."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_id: UUID
    order_reference: str
    status: str
    pickup_address: str
    delivery_address: str
    delivery_fee: int
    driver_earnings: int
    created_at: datetime
    picked_up_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None


class DeliveryResponse(BaseModel):
    """Full delivery response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_id: UUID
    order_reference: str
    driver_id: Optional[UUID] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    driver_photo_url: Optional[str] = None
    driver_rating: Optional[Decimal] = None
    status: str
    pickup_address: str
    pickup_latitude: Decimal
    pickup_longitude: Decimal
    delivery_address: str
    delivery_latitude: Decimal
    delivery_longitude: Decimal
    delivery_fee: int
    driver_earnings: int
    estimated_distance_km: Optional[Decimal] = None
    estimated_duration_minutes: Optional[int] = None
    actual_distance_km: Optional[Decimal] = None
    actual_duration_minutes: Optional[int] = None
    special_instructions: Optional[str] = None
    confirmation_code: Optional[str] = None
    signature_url: Optional[str] = None
    proof_photo_url: Optional[str] = None
    assigned_at: Optional[datetime] = None
    picked_up_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    failed_at: Optional[datetime] = None
    failure_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    status_history: list[DeliveryStatusHistoryResponse] = []


class DeliveryListResponse(BaseModel):
    """Delivery list response with pagination."""

    deliveries: list[DeliverySummary]
    total: int
    page: int = 1
    page_size: int = 20
    has_next: bool = False


class DeliveryTrackingResponse(BaseModel):
    """Delivery tracking response for customers."""

    model_config = ConfigDict(from_attributes=True)

    delivery_id: UUID
    order_id: UUID
    order_reference: str
    status: str
    driver_id: Optional[UUID] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    driver_photo_url: Optional[str] = None
    driver_rating: Optional[Decimal] = None
    driver_latitude: Optional[Decimal] = None
    driver_longitude: Optional[Decimal] = None
    driver_heading: Optional[Decimal] = None
    location_updated_at: Optional[datetime] = None
    pickup_address: str
    pickup_latitude: Decimal
    pickup_longitude: Decimal
    delivery_address: str
    delivery_latitude: Decimal
    delivery_longitude: Decimal
    estimated_arrival_time: Optional[datetime] = None
    status_history: list[DeliveryStatusHistoryResponse] = []
    location_history: list[DeliveryLocationHistoryResponse] = []


class DriverRatingCreate(BaseModel):
    """Driver rating creation schema."""

    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=500)


class DriverRatingResponse(BaseModel):
    """Driver rating response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    delivery_id: UUID
    driver_id: UUID
    rating: int
    comment: Optional[str] = None
    created_at: datetime


# =============================================================================
# Nearby Driver Response (for matching)
# =============================================================================


class NearbyDriverResponse(BaseModel):
    """Nearby driver for matching display."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    first_name: str
    last_name: str
    phone: str
    photo_url: Optional[str] = None
    vehicle_type: str
    average_rating: Optional[Decimal] = None
    total_deliveries: int = 0
    distance_km: float
    estimated_arrival_minutes: int
    match_score: float
