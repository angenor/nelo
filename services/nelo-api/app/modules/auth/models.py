"""Auth module SQLAlchemy models."""

from datetime import datetime
from enum import Enum as PyEnum
from typing import Optional
from uuid import UUID

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import INET, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class UserRole(str, PyEnum):
    """User roles."""

    CLIENT = "client"
    PROVIDER = "provider"
    DRIVER = "driver"
    ADMIN = "admin"
    SUPPORT = "support"
    FINANCE = "finance"
    MARKETING = "marketing"


class KycLevel(str, PyEnum):
    """KYC verification levels."""

    NONE = "none"
    BASIC = "basic"
    STANDARD = "standard"
    BUSINESS = "business"


class User(Base):
    """Auth user model."""

    __tablename__ = "users"
    __table_args__ = {"schema": "auth"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    phone: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255), unique=True)
    phone_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255))
    pin_hash: Mapped[Optional[str]] = mapped_column(String(255))
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", schema="auth", create_type=False),
        default=UserRole.CLIENT,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False)
    blocked_reason: Mapped[Optional[str]] = mapped_column(Text)
    kyc_level: Mapped[KycLevel] = mapped_column(
        Enum(KycLevel, name="kyc_level", schema="auth", create_type=False),
        default=KycLevel.NONE,
    )
    failed_login_attempts: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
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
    sessions: Mapped[list["Session"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    otp_codes: Mapped[list["OTPCode"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    kyc_documents: Mapped[list["KycDocument"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class Session(Base):
    """User session with refresh token."""

    __tablename__ = "sessions"
    __table_args__ = {"schema": "auth"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("auth.users.id", ondelete="CASCADE"),
        nullable=False,
    )
    refresh_token_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    device_id: Mapped[Optional[str]] = mapped_column(String(255))
    device_type: Mapped[Optional[str]] = mapped_column(String(50))
    ip_address: Mapped[Optional[str]] = mapped_column(INET)
    last_city_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="sessions")


class OTPCode(Base):
    """OTP verification codes."""

    __tablename__ = "otp_codes"
    __table_args__ = {"schema": "auth"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    phone: Mapped[Optional[str]] = mapped_column(String(20))
    email: Mapped[Optional[str]] = mapped_column(String(255))
    user_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("auth.users.id", ondelete="CASCADE"),
    )
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    purpose: Mapped[str] = mapped_column(String(50), nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )

    # Relationships
    user: Mapped[Optional["User"]] = relationship(back_populates="otp_codes")


class KycDocument(Base):
    """KYC verification documents."""

    __tablename__ = "kyc_documents"
    __table_args__ = {"schema": "auth"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("auth.users.id", ondelete="CASCADE"),
        nullable=False,
    )
    document_type: Mapped[str] = mapped_column(String(50), nullable=False)
    document_number: Mapped[Optional[str]] = mapped_column(String(100))
    front_image_url: Mapped[Optional[str]] = mapped_column(Text)
    back_image_url: Mapped[Optional[str]] = mapped_column(Text)
    selfie_image_url: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    rejection_reason: Mapped[Optional[str]] = mapped_column(Text)
    verified_by: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
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
    user: Mapped["User"] = relationship(back_populates="kyc_documents")


class AuditLog(Base):
    """Audit log for tracking user actions."""

    __tablename__ = "audit_logs"
    __table_args__ = {"schema": "auth"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default="uuid_generate_v4()",
    )
    user_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    resource_type: Mapped[Optional[str]] = mapped_column(String(50))
    resource_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True))
    ip_address: Mapped[Optional[str]] = mapped_column(INET)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default="CURRENT_TIMESTAMP",
    )
