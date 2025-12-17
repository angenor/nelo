"""Users module SQLAlchemy models."""

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from geoalchemy2 import Geometry
from sqlalchemy import (
    BigInteger,
    Boolean,
    CHAR,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Country(Base):
    """Country reference data."""

    __tablename__ = "countries"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    code: Mapped[str] = mapped_column(CHAR(2), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone_code: Mapped[str] = mapped_column(String(5), nullable=False)
    currency_code: Mapped[str] = mapped_column(CHAR(3), nullable=False)

    # Relationships
    cities: Mapped[list["City"]] = relationship(back_populates="country")


class City(Base):
    """City reference data."""

    __tablename__ = "cities"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    country_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.countries.id"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False)
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 8))
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(11, 8))
    timezone: Mapped[str] = mapped_column(String(50), default="Africa/Abidjan")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    country: Mapped["Country"] = relationship(back_populates="cities")
    zones: Mapped[list["Zone"]] = relationship(back_populates="city")


class Zone(Base):
    """Delivery zone within a city."""

    __tablename__ = "zones"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    city_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.cities.id"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False)
    polygon: Mapped[Optional[str]] = mapped_column(Geometry("POLYGON", srid=4326))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    city: Mapped["City"] = relationship(back_populates="zones")


class Profile(Base):
    """User profile data - separate from auth.users."""

    __tablename__ = "profiles"
    __table_args__ = {"schema": "users"}

    # Same UUID as auth.users, but NO foreign key (microservice-ready)
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    first_name: Mapped[Optional[str]] = mapped_column(String(100))
    last_name: Mapped[Optional[str]] = mapped_column(String(100))
    display_name: Mapped[Optional[str]] = mapped_column(String(100))
    avatar_url: Mapped[Optional[str]] = mapped_column(Text)
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255))
    default_city_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.cities.id"),
    )
    default_zone_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.zones.id"),
    )
    preferred_language: Mapped[str] = mapped_column(CHAR(2), default="fr")
    notification_settings: Mapped[dict] = mapped_column(
        JSONB,
        default={"push": True, "sms": True, "email": False},
    )
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    total_spent: Mapped[int] = mapped_column(BigInteger, default=0)
    average_rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2))
    referral_code: Mapped[Optional[str]] = mapped_column(String(20), unique=True)
    referred_by_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
        onupdate=datetime.utcnow,
    )

    # Relationships
    default_city: Mapped[Optional["City"]] = relationship(foreign_keys=[default_city_id])
    default_zone: Mapped[Optional["Zone"]] = relationship(foreign_keys=[default_zone_id])
    addresses: Mapped[list["Address"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    favorites: Mapped[list["Favorite"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    loyalty: Mapped[Optional["LoyaltyPoints"]] = relationship(back_populates="user", uselist=False)


class Address(Base):
    """User delivery address."""

    __tablename__ = "addresses"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    label: Mapped[str] = mapped_column(String(50), default="home")
    name: Mapped[Optional[str]] = mapped_column(String(100))
    address_line1: Mapped[str] = mapped_column(String(255), nullable=False)
    address_line2: Mapped[Optional[str]] = mapped_column(String(255))
    landmark: Mapped[Optional[str]] = mapped_column(String(255))
    city_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.cities.id"),
    )
    zone_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.zones.id"),
    )
    latitude: Mapped[Decimal] = mapped_column(Numeric(10, 8), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(11, 8), nullable=False)
    # Note: 'location' is a generated column in the DB, not mapped here
    contact_phone: Mapped[Optional[str]] = mapped_column(String(20))
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
        onupdate=datetime.utcnow,
    )

    # Relationships
    user: Mapped["Profile"] = relationship(back_populates="addresses")
    city: Mapped[Optional["City"]] = relationship()
    zone: Mapped[Optional["Zone"]] = relationship()


class Favorite(Base):
    """User favorites (providers, products, drivers)."""

    __tablename__ = "favorites"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    favorite_type: Mapped[str] = mapped_column(String(20), nullable=False)
    entity_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )

    # Relationships
    user: Mapped["Profile"] = relationship(back_populates="favorites")


class LoyaltyPoints(Base):
    """User loyalty points."""

    __tablename__ = "loyalty_points"
    __table_args__ = {"schema": "users"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.profiles.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    points_balance: Mapped[int] = mapped_column(Integer, default=0)
    tier: Mapped[str] = mapped_column(String(20), default="bronze")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
        onupdate=datetime.utcnow,
    )

    # Relationships
    user: Mapped["Profile"] = relationship(back_populates="loyalty")
