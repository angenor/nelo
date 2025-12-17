"""Users module service - profile and address management."""

import secrets
import string
from typing import Optional
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.users.models import Address, City, Profile, Zone


class UserService:
    """Service for user profile and address management."""

    def __init__(self, db: AsyncSession):
        self.db = db

    # =========================================================================
    # Profile operations
    # =========================================================================

    async def get_profile(self, user_id: UUID) -> Optional[Profile]:
        """Get user profile with relationships loaded."""
        result = await self.db.execute(
            select(Profile)
            .where(Profile.id == user_id)
            .options(
                selectinload(Profile.default_city),
                selectinload(Profile.default_zone),
            )
        )
        return result.scalar_one_or_none()

    async def create_profile(
        self,
        user_id: UUID,
        phone: str,
        email: Optional[str] = None,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        referred_by_id: Optional[UUID] = None,
    ) -> Profile:
        """Create a new user profile."""
        referral_code = self._generate_referral_code()

        profile = Profile(
            id=user_id,
            phone=phone,
            email=email,
            first_name=first_name,
            last_name=last_name,
            referral_code=referral_code,
            referred_by_id=referred_by_id,
        )
        self.db.add(profile)
        await self.db.flush()
        return profile

    async def update_profile(
        self,
        user_id: UUID,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        display_name: Optional[str] = None,
        email: Optional[str] = None,
        preferred_language: Optional[str] = None,
        default_city_id: Optional[UUID] = None,
        default_zone_id: Optional[UUID] = None,
        notification_settings: Optional[dict] = None,
    ) -> Optional[Profile]:
        """Update user profile."""
        profile = await self.get_profile(user_id)
        if not profile:
            return None

        if first_name is not None:
            profile.first_name = first_name
        if last_name is not None:
            profile.last_name = last_name
        if display_name is not None:
            profile.display_name = display_name
        if email is not None:
            profile.email = email
        if preferred_language is not None:
            profile.preferred_language = preferred_language
        if default_city_id is not None:
            profile.default_city_id = default_city_id
        if default_zone_id is not None:
            profile.default_zone_id = default_zone_id
        if notification_settings is not None:
            profile.notification_settings = notification_settings

        await self.db.flush()

        # Reload with relationships
        return await self.get_profile(user_id)

    async def get_profile_by_referral_code(self, referral_code: str) -> Optional[Profile]:
        """Get profile by referral code."""
        result = await self.db.execute(
            select(Profile).where(Profile.referral_code == referral_code)
        )
        return result.scalar_one_or_none()

    # =========================================================================
    # Address operations
    # =========================================================================

    async def get_addresses(self, user_id: UUID) -> list[Address]:
        """Get all addresses for a user."""
        result = await self.db.execute(
            select(Address)
            .where(Address.user_id == user_id)
            .options(
                selectinload(Address.city),
                selectinload(Address.zone),
            )
            .order_by(Address.is_default.desc(), Address.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_address(self, user_id: UUID, address_id: UUID) -> Optional[Address]:
        """Get a specific address."""
        result = await self.db.execute(
            select(Address)
            .where(Address.id == address_id, Address.user_id == user_id)
            .options(
                selectinload(Address.city),
                selectinload(Address.zone),
            )
        )
        return result.scalar_one_or_none()

    async def create_address(
        self,
        user_id: UUID,
        address_line1: str,
        latitude: float,
        longitude: float,
        label: str = "home",
        name: Optional[str] = None,
        address_line2: Optional[str] = None,
        landmark: Optional[str] = None,
        city_id: Optional[UUID] = None,
        zone_id: Optional[UUID] = None,
        contact_phone: Optional[str] = None,
        is_default: bool = False,
    ) -> Address:
        """Create a new address."""
        # If this is the first address or is_default is True, make it default
        existing = await self.get_addresses(user_id)
        if not existing or is_default:
            # Reset other defaults
            if existing:
                await self.db.execute(
                    update(Address)
                    .where(Address.user_id == user_id)
                    .values(is_default=False)
                )
            is_default = True

        address = Address(
            user_id=user_id,
            label=label,
            name=name,
            address_line1=address_line1,
            address_line2=address_line2,
            landmark=landmark,
            city_id=city_id,
            zone_id=zone_id,
            latitude=latitude,
            longitude=longitude,
            contact_phone=contact_phone,
            is_default=is_default,
        )
        self.db.add(address)
        await self.db.flush()

        # Reload with relationships
        return await self.get_address(user_id, address.id)

    async def update_address(
        self,
        user_id: UUID,
        address_id: UUID,
        label: Optional[str] = None,
        name: Optional[str] = None,
        address_line1: Optional[str] = None,
        address_line2: Optional[str] = None,
        landmark: Optional[str] = None,
        city_id: Optional[UUID] = None,
        zone_id: Optional[UUID] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        contact_phone: Optional[str] = None,
        is_default: Optional[bool] = None,
    ) -> Optional[Address]:
        """Update an address."""
        address = await self.get_address(user_id, address_id)
        if not address:
            return None

        if label is not None:
            address.label = label
        if name is not None:
            address.name = name
        if address_line1 is not None:
            address.address_line1 = address_line1
        if address_line2 is not None:
            address.address_line2 = address_line2
        if landmark is not None:
            address.landmark = landmark
        if city_id is not None:
            address.city_id = city_id
        if zone_id is not None:
            address.zone_id = zone_id
        if latitude is not None:
            address.latitude = latitude
        if longitude is not None:
            address.longitude = longitude
        if contact_phone is not None:
            address.contact_phone = contact_phone

        if is_default is True:
            # Reset other defaults
            await self.db.execute(
                update(Address)
                .where(Address.user_id == user_id, Address.id != address_id)
                .values(is_default=False)
            )
            address.is_default = True

        await self.db.flush()
        return await self.get_address(user_id, address_id)

    async def delete_address(self, user_id: UUID, address_id: UUID) -> bool:
        """Delete an address."""
        address = await self.get_address(user_id, address_id)
        if not address:
            return False

        was_default = address.is_default
        await self.db.delete(address)
        await self.db.flush()

        # If deleted address was default, make another one default
        if was_default:
            remaining = await self.get_addresses(user_id)
            if remaining:
                remaining[0].is_default = True

        return True

    async def get_default_address(self, user_id: UUID) -> Optional[Address]:
        """Get user's default address."""
        result = await self.db.execute(
            select(Address)
            .where(Address.user_id == user_id, Address.is_default == True)
            .options(
                selectinload(Address.city),
                selectinload(Address.zone),
            )
        )
        return result.scalar_one_or_none()

    # =========================================================================
    # Geographic data
    # =========================================================================

    async def get_city(self, city_id: UUID) -> Optional[City]:
        """Get city by ID."""
        result = await self.db.execute(select(City).where(City.id == city_id))
        return result.scalar_one_or_none()

    async def get_cities(self, country_id: Optional[UUID] = None) -> list[City]:
        """Get all cities, optionally filtered by country."""
        query = select(City).where(City.is_active == True)
        if country_id:
            query = query.where(City.country_id == country_id)
        result = await self.db.execute(query.order_by(City.name))
        return list(result.scalars().all())

    async def get_zones(self, city_id: UUID) -> list[Zone]:
        """Get all zones for a city."""
        result = await self.db.execute(
            select(Zone)
            .where(Zone.city_id == city_id, Zone.is_active == True)
            .order_by(Zone.name)
        )
        return list(result.scalars().all())

    # =========================================================================
    # Private helpers
    # =========================================================================

    def _generate_referral_code(self) -> str:
        """Generate unique referral code."""
        chars = string.ascii_uppercase + string.digits
        return "".join(secrets.choice(chars) for _ in range(8))
