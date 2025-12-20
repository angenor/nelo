"""Orders module Pydantic schemas - providers, products, orders."""

from datetime import datetime, time
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =============================================================================
# Base Schemas
# =============================================================================


class CityResponse(BaseModel):
    """City response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    is_active: bool = True


class ZoneResponse(BaseModel):
    """Zone response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    city_id: UUID
    name: str
    slug: str
    delivery_fee_base: int = 500
    is_active: bool = True


# =============================================================================
# Provider Category Schemas
# =============================================================================


class ProviderCategoryResponse(BaseModel):
    """Provider category response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    parent_id: Optional[UUID] = None
    name: str
    slug: str
    icon_url: Optional[str] = None
    provider_type: str
    display_order: int = 0
    is_active: bool = True


# =============================================================================
# Provider Schedule Schemas
# =============================================================================


class ProviderScheduleCreate(BaseModel):
    """Provider schedule create schema."""

    day_of_week: int = Field(..., ge=0, le=6)  # 0 = Monday, 6 = Sunday
    open_time: time
    close_time: time
    is_closed: bool = False


class ProviderScheduleResponse(BaseModel):
    """Provider schedule response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    day_of_week: int
    open_time: time
    close_time: time
    is_closed: bool = False


class ProviderScheduleUpdate(BaseModel):
    """Provider schedule update schema."""

    open_time: Optional[time] = None
    close_time: Optional[time] = None
    is_closed: Optional[bool] = None


# =============================================================================
# Provider Schemas
# =============================================================================


class ProviderCreate(BaseModel):
    """Provider create schema."""

    name: str = Field(..., min_length=2, max_length=200)
    description: Optional[str] = None
    type: str = Field(..., pattern="^(restaurant|gas_depot|grocery|pharmacy|pressing|artisan)$")
    phone: str = Field(..., min_length=8, max_length=20)
    email: Optional[str] = None
    whatsapp: Optional[str] = None
    address_line1: str = Field(..., min_length=5, max_length=255)
    landmark: Optional[str] = None
    city_id: UUID
    zone_id: Optional[UUID] = None
    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    min_order_amount: int = Field(default=0, ge=0)
    average_prep_time: int = Field(default=30, ge=5)
    delivery_radius_km: Decimal = Field(default=5, ge=1, le=50)
    schedules: Optional[list[ProviderScheduleCreate]] = None


class ProviderUpdate(BaseModel):
    """Provider update schema."""

    name: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = None
    phone: Optional[str] = Field(None, min_length=8, max_length=20)
    email: Optional[str] = None
    whatsapp: Optional[str] = None
    address_line1: Optional[str] = Field(None, min_length=5, max_length=255)
    landmark: Optional[str] = None
    zone_id: Optional[UUID] = None
    latitude: Optional[Decimal] = Field(None, ge=-90, le=90)
    longitude: Optional[Decimal] = Field(None, ge=-180, le=180)
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    min_order_amount: Optional[int] = Field(None, ge=0)
    average_prep_time: Optional[int] = Field(None, ge=5)
    delivery_radius_km: Optional[Decimal] = Field(None, ge=1, le=50)
    is_open: Optional[bool] = None
    is_featured: Optional[bool] = None


class ProviderSummary(BaseModel):
    """Provider summary for list views."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    type: str
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    address_line1: str
    average_rating: Optional[Decimal] = None
    rating_count: int = 0
    min_order_amount: int = 0
    average_prep_time: int = 30
    is_open: bool = False
    is_featured: bool = False
    distance_km: Optional[float] = None  # Calculated field


class ProviderResponse(BaseModel):
    """Full provider response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    name: str
    slug: str
    description: Optional[str] = None
    type: str
    phone: str
    email: Optional[str] = None
    whatsapp: Optional[str] = None
    address_line1: str
    landmark: Optional[str] = None
    city_id: UUID
    zone_id: Optional[UUID] = None
    latitude: Decimal
    longitude: Decimal
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    min_order_amount: int = 0
    average_prep_time: int = 30
    delivery_radius_km: Decimal = Decimal("5")
    commission_rate: Decimal = Decimal("0.15")
    average_rating: Optional[Decimal] = None
    rating_count: int = 0
    total_orders: int = 0
    status: str = "pending"
    is_open: bool = False
    is_featured: bool = False
    created_at: datetime
    updated_at: datetime
    schedules: list[ProviderScheduleResponse] = []
    city: Optional[CityResponse] = None
    zone: Optional[ZoneResponse] = None


class ProviderListResponse(BaseModel):
    """Provider list response with pagination."""

    providers: list[ProviderSummary]
    total: int
    page: int = 1
    page_size: int = 20
    has_next: bool = False


class NearbyProviderRequest(BaseModel):
    """Request for nearby providers."""

    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)
    radius_km: Decimal = Field(default=5, ge=0.5, le=50)
    provider_type: Optional[str] = None
    is_open_only: bool = False


# =============================================================================
# Product Category Schemas
# =============================================================================


class ProductCategoryCreate(BaseModel):
    """Product category create schema."""

    name: str = Field(..., min_length=2, max_length=100)
    display_order: int = Field(default=0, ge=0)
    is_active: bool = True


class ProductCategoryUpdate(BaseModel):
    """Product category update schema."""

    name: Optional[str] = Field(None, min_length=2, max_length=100)
    display_order: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductCategoryResponse(BaseModel):
    """Product category response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    provider_id: UUID
    name: str
    display_order: int = 0
    is_active: bool = True


# =============================================================================
# Product Option Schemas
# =============================================================================


class ProductOptionItemCreate(BaseModel):
    """Product option item create schema."""

    name: str = Field(..., min_length=1, max_length=100)
    price_adjustment: int = Field(default=0)
    is_available: bool = True


class ProductOptionItemResponse(BaseModel):
    """Product option item response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price_adjustment: int = 0
    is_available: bool = True


class ProductOptionCreate(BaseModel):
    """Product option create schema."""

    name: str = Field(..., min_length=1, max_length=100)
    type: str = Field(default="single", pattern="^(single|multiple)$")
    is_required: bool = False
    max_selections: int = Field(default=1, ge=1)
    items: list[ProductOptionItemCreate] = []


class ProductOptionResponse(BaseModel):
    """Product option response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID
    name: str
    type: str = "single"
    is_required: bool = False
    max_selections: int = 1
    items: list[ProductOptionItemResponse] = []


# =============================================================================
# Product Schemas
# =============================================================================


class ProductCreate(BaseModel):
    """Product create schema."""

    category_id: Optional[UUID] = None
    name: str = Field(..., min_length=2, max_length=200)
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: int = Field(..., ge=0)
    compare_at_price: Optional[int] = Field(None, ge=0)
    is_available: bool = True
    is_featured: bool = False
    is_vegetarian: bool = False
    is_spicy: bool = False
    prep_time: Optional[int] = Field(None, ge=0)
    display_order: int = Field(default=0, ge=0)
    options: Optional[list[ProductOptionCreate]] = None


class ProductUpdate(BaseModel):
    """Product update schema."""

    category_id: Optional[UUID] = None
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: Optional[int] = Field(None, ge=0)
    compare_at_price: Optional[int] = Field(None, ge=0)
    is_available: Optional[bool] = None
    is_featured: Optional[bool] = None
    is_vegetarian: Optional[bool] = None
    is_spicy: Optional[bool] = None
    prep_time: Optional[int] = Field(None, ge=0)
    display_order: Optional[int] = Field(None, ge=0)


class ProductSummary(BaseModel):
    """Product summary for list views."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    image_url: Optional[str] = None
    price: int
    compare_at_price: Optional[int] = None
    is_available: bool = True
    is_featured: bool = False
    is_vegetarian: bool = False
    is_spicy: bool = False


class ProductResponse(BaseModel):
    """Full product response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    provider_id: UUID
    category_id: Optional[UUID] = None
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: int
    compare_at_price: Optional[int] = None
    is_available: bool = True
    is_featured: bool = False
    is_vegetarian: bool = False
    is_spicy: bool = False
    prep_time: Optional[int] = None
    display_order: int = 0
    created_at: datetime
    updated_at: datetime
    options: list[ProductOptionResponse] = []
    category: Optional[ProductCategoryResponse] = None


class ProductListResponse(BaseModel):
    """Product list response."""

    products: list[ProductResponse]
    total: int


# =============================================================================
# Gas Product Schemas
# =============================================================================


class GasProductCreate(BaseModel):
    """Gas product create schema."""

    brand: str = Field(..., min_length=1, max_length=50)
    bottle_size: str = Field(..., min_length=1, max_length=20)
    refill_price: int = Field(..., ge=0)
    exchange_price: Optional[int] = Field(None, ge=0)
    quantity_available: int = Field(default=0, ge=0)
    is_available: bool = True


class GasProductUpdate(BaseModel):
    """Gas product update schema."""

    brand: Optional[str] = Field(None, min_length=1, max_length=50)
    bottle_size: Optional[str] = Field(None, min_length=1, max_length=20)
    refill_price: Optional[int] = Field(None, ge=0)
    exchange_price: Optional[int] = Field(None, ge=0)
    quantity_available: Optional[int] = Field(None, ge=0)
    is_available: Optional[bool] = None


class GasProductResponse(BaseModel):
    """Gas product response schema."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    provider_id: UUID
    brand: str
    bottle_size: str
    refill_price: int
    exchange_price: Optional[int] = None
    quantity_available: int = 0
    is_available: bool = True
    created_at: datetime
    updated_at: datetime


class GasProductListResponse(BaseModel):
    """Gas product list response."""

    products: list[GasProductResponse]
    total: int


# =============================================================================
# Menu Response (combines categories and products)
# =============================================================================


class MenuCategoryWithProducts(BaseModel):
    """Menu category with products."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    display_order: int = 0
    products: list[ProductResponse] = []


class ProviderMenuResponse(BaseModel):
    """Provider menu response with categories and products."""

    provider_id: UUID
    provider_name: str
    categories: list[MenuCategoryWithProducts] = []
    uncategorized_products: list[ProductResponse] = []
    gas_products: list[GasProductResponse] = []
    total_products: int = 0
