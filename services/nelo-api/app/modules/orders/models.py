"""Orders module models - providers, products, orders."""

from datetime import time
from decimal import Decimal
from enum import Enum as PyEnum
from typing import TYPE_CHECKING, Optional
from uuid import UUID

from geoalchemy2 import Geometry
from sqlalchemy import (
    ARRAY,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    Time,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    pass


# =============================================================================
# Enums
# =============================================================================


class ProviderType(str, PyEnum):
    """Provider type enum."""

    RESTAURANT = "restaurant"
    GAS_DEPOT = "gas_depot"
    GROCERY = "grocery"
    PHARMACY = "pharmacy"
    PRESSING = "pressing"
    ARTISAN = "artisan"


class OrderStatus(str, PyEnum):
    """Order status enum."""

    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    READY = "ready"
    PICKED_UP = "picked_up"
    DELIVERING = "delivering"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class PaymentMethod(str, PyEnum):
    """Payment method enum."""

    WALLET = "wallet"
    MOBILE_MONEY = "mobile_money"
    CARD = "card"
    CASH = "cash"


# =============================================================================
# Geographic Models (local copy for autonomy)
# =============================================================================


class Country(Base):
    """Country model for orders schema."""

    __tablename__ = "countries"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True)
    code: Mapped[str] = mapped_column(String(2), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    currency_code: Mapped[str] = mapped_column(String(3), nullable=False)

    # Relationships
    cities: Mapped[list["City"]] = relationship("City", back_populates="country")


class City(Base):
    """City model for orders schema."""

    __tablename__ = "cities"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True)
    country_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.countries.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False)
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 8))
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(11, 8))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    country: Mapped["Country"] = relationship("Country", back_populates="cities")
    zones: Mapped[list["Zone"]] = relationship("Zone", back_populates="city")
    providers: Mapped[list["Provider"]] = relationship("Provider", back_populates="city")


class Zone(Base):
    """Delivery zone model for orders schema."""

    __tablename__ = "zones"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True)
    city_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.cities.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False)
    polygon: Mapped[Optional[str]] = mapped_column(Geometry("POLYGON", srid=4326))
    delivery_fee_base: Mapped[int] = mapped_column(Integer, default=500)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    city: Mapped["City"] = relationship("City", back_populates="zones")
    providers: Mapped[list["Provider"]] = relationship("Provider", back_populates="zone")


# =============================================================================
# Pricing Models
# =============================================================================


class PricingRule(Base):
    """Pricing rules for delivery fees."""

    __tablename__ = "pricing_rules"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    city_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.cities.id")
    )
    zone_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.zones.id")
    )
    provider_type: Mapped[Optional[str]] = mapped_column(String(20))
    base_fee: Mapped[int] = mapped_column(Integer, default=500, nullable=False)
    per_km_fee: Mapped[int] = mapped_column(Integer, default=100, nullable=False)
    min_order_amount: Mapped[int] = mapped_column(Integer, default=1000)
    free_delivery_threshold: Mapped[Optional[int]] = mapped_column(Integer)
    surge_multiplier: Mapped[Decimal] = mapped_column(Numeric(3, 2), default=1.00)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


# =============================================================================
# Provider Models
# =============================================================================


class ProviderCategory(Base):
    """Provider category (restaurant types, etc.)."""

    __tablename__ = "provider_categories"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    parent_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.provider_categories.id")
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    icon_url: Mapped[Optional[str]] = mapped_column(Text)
    provider_type: Mapped[str] = mapped_column(String(20), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Self-referential relationship
    parent: Mapped[Optional["ProviderCategory"]] = relationship(
        "ProviderCategory", remote_side=[id], back_populates="children"
    )
    children: Mapped[list["ProviderCategory"]] = relationship(
        "ProviderCategory", back_populates="parent"
    )


class Provider(Base):
    """Service provider (restaurant, gas depot, etc.)."""

    __tablename__ = "providers"
    __table_args__ = (
        Index("idx_orders_providers_city", "city_id"),
        Index("idx_orders_providers_location", "location", postgresql_using="gist"),
        Index(
            "idx_orders_providers_open",
            "city_id",
            "is_open",
            postgresql_where="is_open = true",
        ),
        {"schema": "orders"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    user_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    slug: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    type: Mapped[str] = mapped_column(String(20), nullable=False)
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255))
    whatsapp: Mapped[Optional[str]] = mapped_column(String(20))
    address_line1: Mapped[str] = mapped_column(String(255), nullable=False)
    landmark: Mapped[Optional[str]] = mapped_column(String(255))
    city_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.cities.id"), nullable=False
    )
    zone_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.zones.id")
    )
    latitude: Mapped[Decimal] = mapped_column(Numeric(10, 8), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(11, 8), nullable=False)
    location: Mapped[Optional[str]] = mapped_column(Geometry("POINT", srid=4326))
    logo_url: Mapped[Optional[str]] = mapped_column(Text)
    cover_image_url: Mapped[Optional[str]] = mapped_column(Text)
    min_order_amount: Mapped[int] = mapped_column(Integer, default=0)
    average_prep_time: Mapped[int] = mapped_column(Integer, default=30)
    delivery_radius_km: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=5)
    commission_rate: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=0.15)
    average_rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2))
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    is_open: Mapped[bool] = mapped_column(Boolean, default=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    city: Mapped["City"] = relationship("City", back_populates="providers")
    zone: Mapped[Optional["Zone"]] = relationship("Zone", back_populates="providers")
    schedules: Mapped[list["ProviderSchedule"]] = relationship(
        "ProviderSchedule", back_populates="provider", cascade="all, delete-orphan"
    )
    product_categories: Mapped[list["ProductCategory"]] = relationship(
        "ProductCategory", back_populates="provider", cascade="all, delete-orphan"
    )
    products: Mapped[list["Product"]] = relationship(
        "Product", back_populates="provider", cascade="all, delete-orphan"
    )
    gas_products: Mapped[list["GasProduct"]] = relationship(
        "GasProduct", back_populates="provider", cascade="all, delete-orphan"
    )


class ProviderSchedule(Base):
    """Provider operating hours."""

    __tablename__ = "provider_schedules"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    provider_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.providers.id", ondelete="CASCADE"),
        nullable=False,
    )
    day_of_week: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    open_time: Mapped[time] = mapped_column(Time, nullable=False)
    close_time: Mapped[time] = mapped_column(Time, nullable=False)
    is_closed: Mapped[bool] = mapped_column(Boolean, default=False)

    # Relationships
    provider: Mapped["Provider"] = relationship("Provider", back_populates="schedules")


# =============================================================================
# Product Models
# =============================================================================


class ProductCategory(Base):
    """Product category within a provider."""

    __tablename__ = "product_categories"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    provider_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.providers.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    provider: Mapped["Provider"] = relationship(
        "Provider", back_populates="product_categories"
    )
    products: Mapped[list["Product"]] = relationship(
        "Product", back_populates="category"
    )


class Product(Base):
    """Product model."""

    __tablename__ = "products"
    __table_args__ = (
        Index("idx_orders_products_provider", "provider_id"),
        {"schema": "orders"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    provider_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.providers.id", ondelete="CASCADE"),
        nullable=False,
    )
    category_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.product_categories.id", ondelete="SET NULL"),
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    image_url: Mapped[Optional[str]] = mapped_column(Text)
    price: Mapped[int] = mapped_column(Integer, nullable=False)
    compare_at_price: Mapped[Optional[int]] = mapped_column(Integer)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_vegetarian: Mapped[bool] = mapped_column(Boolean, default=False)
    is_spicy: Mapped[bool] = mapped_column(Boolean, default=False)
    prep_time: Mapped[Optional[int]] = mapped_column(Integer)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    provider: Mapped["Provider"] = relationship("Provider", back_populates="products")
    category: Mapped[Optional["ProductCategory"]] = relationship(
        "ProductCategory", back_populates="products"
    )
    options: Mapped[list["ProductOption"]] = relationship(
        "ProductOption", back_populates="product", cascade="all, delete-orphan"
    )


class ProductOption(Base):
    """Product option group (e.g., size, extras)."""

    __tablename__ = "product_options"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    product_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.products.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[str] = mapped_column(String(20), default="single")
    is_required: Mapped[bool] = mapped_column(Boolean, default=False)
    max_selections: Mapped[int] = mapped_column(Integer, default=1)

    # Relationships
    product: Mapped["Product"] = relationship("Product", back_populates="options")
    items: Mapped[list["ProductOptionItem"]] = relationship(
        "ProductOptionItem", back_populates="option", cascade="all, delete-orphan"
    )


class ProductOptionItem(Base):
    """Individual option item (e.g., small, medium, large)."""

    __tablename__ = "product_option_items"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    option_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.product_options.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    price_adjustment: Mapped[int] = mapped_column(Integer, default=0)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    option: Mapped["ProductOption"] = relationship("ProductOption", back_populates="items")


class GasProduct(Base):
    """Gas product (for gas depots)."""

    __tablename__ = "gas_products"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    provider_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.providers.id", ondelete="CASCADE"),
        nullable=False,
    )
    brand: Mapped[str] = mapped_column(String(50), nullable=False)
    bottle_size: Mapped[str] = mapped_column(String(20), nullable=False)
    refill_price: Mapped[int] = mapped_column(Integer, nullable=False)
    exchange_price: Mapped[Optional[int]] = mapped_column(Integer)
    quantity_available: Mapped[int] = mapped_column(Integer, default=0)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    provider: Mapped["Provider"] = relationship("Provider", back_populates="gas_products")


# =============================================================================
# Order Models (will be fully implemented in M4)
# =============================================================================


class Order(Base):
    """Order model."""

    __tablename__ = "orders"
    __table_args__ = (
        Index("idx_orders_orders_user", "user_id"),
        Index("idx_orders_orders_provider", "provider_id"),
        Index("idx_orders_orders_status", "status"),
        Index("idx_orders_orders_reference", "reference"),
        {"schema": "orders"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    reference: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    user_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)
    provider_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.providers.id"), nullable=False
    )
    service_type: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    delivery_address_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    delivery_address_snapshot: Mapped[dict] = mapped_column(JSONB, nullable=False)
    special_instructions: Mapped[Optional[str]] = mapped_column(Text)
    subtotal: Mapped[int] = mapped_column(Integer, nullable=False)
    delivery_fee: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    service_fee: Mapped[int] = mapped_column(Integer, default=0)
    discount_amount: Mapped[int] = mapped_column(Integer, default=0)
    tip_amount: Mapped[int] = mapped_column(Integer, default=0)
    total: Mapped[int] = mapped_column(Integer, nullable=False)
    promotion_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    promotion_code: Mapped[Optional[str]] = mapped_column(String(50))
    payment_method: Mapped[str] = mapped_column(String(20), nullable=False)
    payment_status: Mapped[str] = mapped_column(String(20), default="pending")
    paid_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    transaction_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    is_scheduled: Mapped[bool] = mapped_column(Boolean, default=False)
    scheduled_for: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    estimated_prep_time: Mapped[Optional[int]] = mapped_column(Integer)
    estimated_delivery_time: Mapped[Optional[int]] = mapped_column(Integer)
    confirmed_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    ready_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    picked_up_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    delivered_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    cancelled_at: Mapped[Optional[DateTime]] = mapped_column(DateTime(timezone=True))
    cancellation_reason: Mapped[Optional[str]] = mapped_column(Text)
    cancelled_by: Mapped[Optional[str]] = mapped_column(String(20))
    is_rated: Mapped[bool] = mapped_column(Boolean, default=False)
    provider_rating: Mapped[Optional[int]] = mapped_column(SmallInteger)
    driver_rating: Mapped[Optional[int]] = mapped_column(SmallInteger)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    provider: Mapped["Provider"] = relationship("Provider")
    items: Mapped[list["OrderItem"]] = relationship(
        "OrderItem", back_populates="order", cascade="all, delete-orphan"
    )


class OrderItem(Base):
    """Order item model."""

    __tablename__ = "order_items"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    order_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.orders.id", ondelete="CASCADE"),
        nullable=False,
    )
    product_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    gas_product_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    product_name: Mapped[str] = mapped_column(String(200), nullable=False)
    product_image_url: Mapped[Optional[str]] = mapped_column(Text)
    quantity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    unit_price: Mapped[int] = mapped_column(Integer, nullable=False)
    total_price: Mapped[int] = mapped_column(Integer, nullable=False)
    selected_options: Mapped[list] = mapped_column(JSONB, default=list)
    special_instructions: Mapped[Optional[str]] = mapped_column(Text)

    # Relationships
    order: Mapped["Order"] = relationship("Order", back_populates="items")


class Rating(Base):
    """Rating model for orders, providers, drivers."""

    __tablename__ = "ratings"
    __table_args__ = {"schema": "orders"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    order_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("orders.orders.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)
    rating_type: Mapped[str] = mapped_column(String(20), nullable=False)
    provider_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.providers.id")
    )
    driver_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    product_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("orders.products.id")
    )
    rating: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    comment: Mapped[Optional[str]] = mapped_column(Text)
    tags: Mapped[list] = mapped_column(ARRAY(Text), default=list)
    is_visible: Mapped[bool] = mapped_column(Boolean, default=True)
    provider_response: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
