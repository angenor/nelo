"""Deliveries module models - drivers, deliveries, tracking."""

from datetime import datetime
from decimal import Decimal
from enum import Enum as PyEnum
from typing import Optional
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
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# =============================================================================
# Enums
# =============================================================================


class VehicleType(str, PyEnum):
    """Vehicle type enum."""

    BICYCLE = "bicycle"
    MOTORCYCLE = "motorcycle"
    TRICYCLE = "tricycle"
    CAR = "car"
    VAN = "van"


class DeliveryStatus(str, PyEnum):
    """Delivery status enum."""

    PENDING = "pending"
    ASSIGNED = "assigned"
    ACCEPTED = "accepted"
    PICKING_UP = "picking_up"
    PICKED_UP = "picked_up"
    DELIVERING = "delivering"
    DELIVERED = "delivered"
    FAILED = "failed"
    CANCELLED = "cancelled"


class DriverStatus(str, PyEnum):
    """Driver approval status."""

    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    REJECTED = "rejected"


class OfferStatus(str, PyEnum):
    """Delivery offer status."""

    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"


# =============================================================================
# Geographic Models (local copy for autonomy)
# =============================================================================


class City(Base):
    """City model for deliveries schema."""

    __tablename__ = "cities"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    country_code: Mapped[str] = mapped_column(String(2), default="CI", nullable=False)
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 8))
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(11, 8))

    # Relationships
    drivers: Mapped[list["Driver"]] = relationship("Driver", back_populates="city")


class Zone(Base):
    """Delivery zone model."""

    __tablename__ = "zones"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True)
    city_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.cities.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    polygon: Mapped[Optional[str]] = mapped_column(Geometry("POLYGON", srid=4326))


# =============================================================================
# Driver Models
# =============================================================================


class Driver(Base):
    """Delivery driver model."""

    __tablename__ = "drivers"
    __table_args__ = (
        Index("idx_deliveries_drivers_city", "city_id"),
        Index("idx_deliveries_drivers_location", "current_location", postgresql_using="gist"),
        Index(
            "idx_deliveries_drivers_available",
            "city_id",
            "is_available",
            "is_online",
            postgresql_where="is_available = true AND is_online = true",
        ),
        {"schema": "deliveries"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    user_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), unique=True, nullable=False)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    display_name: Mapped[Optional[str]] = mapped_column(String(100))
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    avatar_url: Mapped[Optional[str]] = mapped_column(Text)
    city_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.cities.id"), nullable=False
    )
    operating_zones: Mapped[list] = mapped_column(ARRAY(PG_UUID(as_uuid=True)), default=list)
    vehicle_type: Mapped[str] = mapped_column(String(20), nullable=False)
    vehicle_brand: Mapped[Optional[str]] = mapped_column(String(50))
    vehicle_model: Mapped[Optional[str]] = mapped_column(String(50))
    vehicle_plate: Mapped[Optional[str]] = mapped_column(String(20))
    vehicle_photo_url: Mapped[Optional[str]] = mapped_column(Text)
    max_orders: Mapped[int] = mapped_column(Integer, default=2)
    average_rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2))
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    total_deliveries: Mapped[int] = mapped_column(Integer, default=0)
    total_earnings: Mapped[int] = mapped_column(Integer, default=0)  # In smallest unit (FCFA)
    completion_rate: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=100)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    is_available: Mapped[bool] = mapped_column(Boolean, default=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    current_latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 8))
    current_longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(11, 8))
    current_location: Mapped[Optional[str]] = mapped_column(Geometry("POINT", srid=4326))
    location_updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    commission_rate: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=0.10)
    wallet_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    city: Mapped["City"] = relationship("City", back_populates="drivers")
    documents: Mapped[list["DriverDocument"]] = relationship(
        "DriverDocument", back_populates="driver", cascade="all, delete-orphan"
    )
    availabilities: Mapped[list["DriverAvailability"]] = relationship(
        "DriverAvailability", back_populates="driver", cascade="all, delete-orphan"
    )
    deliveries: Mapped[list["Delivery"]] = relationship("Delivery", back_populates="driver")
    offers: Mapped[list["DeliveryOffer"]] = relationship("DeliveryOffer", back_populates="driver")
    earnings: Mapped[list["DriverEarning"]] = relationship("DriverEarning", back_populates="driver")


class DriverDocument(Base):
    """Driver document for verification."""

    __tablename__ = "driver_documents"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    driver_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("deliveries.drivers.id", ondelete="CASCADE"),
        nullable=False,
    )
    document_type: Mapped[str] = mapped_column(String(50), nullable=False)
    document_number: Mapped[Optional[str]] = mapped_column(String(100))
    front_image_url: Mapped[str] = mapped_column(Text, nullable=False)
    back_image_url: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    verified_by: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    driver: Mapped["Driver"] = relationship("Driver", back_populates="documents")


class DriverAvailability(Base):
    """Driver availability schedule."""

    __tablename__ = "driver_availability"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    driver_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("deliveries.drivers.id", ondelete="CASCADE"),
        nullable=False,
    )
    day_of_week: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    start_time: Mapped[datetime] = mapped_column(Time, nullable=False)
    end_time: Mapped[datetime] = mapped_column(Time, nullable=False)
    preferred_zone_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))

    # Relationships
    driver: Mapped["Driver"] = relationship("Driver", back_populates="availabilities")


# =============================================================================
# Delivery Models
# =============================================================================


class Delivery(Base):
    """Delivery model."""

    __tablename__ = "deliveries"
    __table_args__ = (
        Index("idx_deliveries_deliveries_order", "order_id"),
        Index("idx_deliveries_deliveries_driver", "driver_id"),
        Index("idx_deliveries_deliveries_status", "status"),
        Index("idx_deliveries_deliveries_pickup", "pickup_location", postgresql_using="gist"),
        {"schema": "deliveries"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    reference: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    order_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)
    order_reference: Mapped[str] = mapped_column(String(20), nullable=False)
    driver_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.drivers.id")
    )
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)

    # Pickup location (snapshot)
    pickup_latitude: Mapped[Decimal] = mapped_column(Numeric(10, 8), nullable=False)
    pickup_longitude: Mapped[Decimal] = mapped_column(Numeric(11, 8), nullable=False)
    pickup_location: Mapped[Optional[str]] = mapped_column(Geometry("POINT", srid=4326))
    pickup_address: Mapped[str] = mapped_column(Text, nullable=False)
    pickup_contact_name: Mapped[Optional[str]] = mapped_column(String(100))
    pickup_contact_phone: Mapped[Optional[str]] = mapped_column(String(20))

    # Delivery location (snapshot)
    delivery_latitude: Mapped[Decimal] = mapped_column(Numeric(10, 8), nullable=False)
    delivery_longitude: Mapped[Decimal] = mapped_column(Numeric(11, 8), nullable=False)
    delivery_location: Mapped[Optional[str]] = mapped_column(Geometry("POINT", srid=4326))
    delivery_address: Mapped[str] = mapped_column(Text, nullable=False)
    delivery_contact_name: Mapped[Optional[str]] = mapped_column(String(100))
    delivery_contact_phone: Mapped[Optional[str]] = mapped_column(String(20))

    distance_km: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))
    delivery_fee: Mapped[int] = mapped_column(Integer, nullable=False)
    tip_amount: Mapped[int] = mapped_column(Integer, default=0)
    driver_earnings: Mapped[Optional[int]] = mapped_column(Integer)
    collected_cash: Mapped[int] = mapped_column(Integer, default=0)

    delivery_code: Mapped[Optional[str]] = mapped_column(String(6))
    delivery_photo_url: Mapped[Optional[str]] = mapped_column(Text)

    estimated_delivery_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer)

    assigned_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    picked_up_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    delivered_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    failure_reason: Mapped[Optional[str]] = mapped_column(Text)
    matching_score: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    driver: Mapped[Optional["Driver"]] = relationship("Driver", back_populates="deliveries")
    offers: Mapped[list["DeliveryOffer"]] = relationship(
        "DeliveryOffer", back_populates="delivery", cascade="all, delete-orphan"
    )
    location_history: Mapped[list["DeliveryLocationHistory"]] = relationship(
        "DeliveryLocationHistory", back_populates="delivery", cascade="all, delete-orphan"
    )
    status_history: Mapped[list["DeliveryStatusHistory"]] = relationship(
        "DeliveryStatusHistory", back_populates="delivery", cascade="all, delete-orphan"
    )


class DeliveryOffer(Base):
    """Delivery offer to a driver."""

    __tablename__ = "delivery_offers"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    delivery_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("deliveries.deliveries.id", ondelete="CASCADE"),
        nullable=False,
    )
    driver_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.drivers.id"), nullable=False
    )
    matching_score: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    distance_km: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))
    estimated_earnings: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    delivery: Mapped["Delivery"] = relationship("Delivery", back_populates="offers")
    driver: Mapped["Driver"] = relationship("Driver", back_populates="offers")


class DeliveryLocationHistory(Base):
    """GPS tracking history for a delivery."""

    __tablename__ = "delivery_location_history"
    __table_args__ = (
        Index("idx_deliveries_location_history", "delivery_id", "recorded_at"),
        {"schema": "deliveries"},
    )

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    delivery_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("deliveries.deliveries.id", ondelete="CASCADE"),
        nullable=False,
    )
    driver_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)
    latitude: Mapped[Decimal] = mapped_column(Numeric(10, 8), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(11, 8), nullable=False)
    speed: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2))
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    delivery: Mapped["Delivery"] = relationship("Delivery", back_populates="location_history")


class DeliveryStatusHistory(Base):
    """Status change history for a delivery."""

    __tablename__ = "delivery_status_history"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    delivery_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey("deliveries.deliveries.id", ondelete="CASCADE"),
        nullable=False,
    )
    from_status: Mapped[Optional[str]] = mapped_column(String(20))
    to_status: Mapped[str] = mapped_column(String(20), nullable=False)
    changed_by: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 8))
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(11, 8))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    delivery: Mapped["Delivery"] = relationship("Delivery", back_populates="status_history")


class DriverEarning(Base):
    """Driver earnings record."""

    __tablename__ = "driver_earnings"
    __table_args__ = {"schema": "deliveries"}

    id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, server_default=func.uuid_generate_v4()
    )
    driver_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.drivers.id"), nullable=False
    )
    delivery_id: Mapped[Optional[UUID]] = mapped_column(
        PG_UUID(as_uuid=True), ForeignKey("deliveries.deliveries.id")
    )
    type: Mapped[str] = mapped_column(String(20), nullable=False)
    gross_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    commission_amount: Mapped[int] = mapped_column(Integer, default=0)
    net_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    payout_id: Mapped[Optional[UUID]] = mapped_column(PG_UUID(as_uuid=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    driver: Mapped["Driver"] = relationship("Driver", back_populates="earnings")
