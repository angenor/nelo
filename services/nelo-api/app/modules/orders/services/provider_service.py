"""Provider service with geospatial search."""

import json
import re
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional
from uuid import UUID

import redis.asyncio as redis
from geoalchemy2.functions import ST_DWithin, ST_Distance, ST_SetSRID, ST_MakePoint
from sqlalchemy import and_, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import (
    City,
    GasProduct,
    Product,
    ProductCategory,
    Provider,
    ProviderSchedule,
    Zone,
)


class ProviderService:
    """Service for provider operations with geospatial search."""

    # Cache TTL in seconds
    CACHE_TTL = 300  # 5 minutes

    def __init__(self, db: AsyncSession, redis_client: Optional[redis.Redis] = None):
        self.db = db
        self.redis = redis_client

    # =========================================================================
    # Provider CRUD
    # =========================================================================

    async def get_provider(self, provider_id: UUID) -> Optional[Provider]:
        """Get provider by ID with relationships."""
        result = await self.db.execute(
            select(Provider)
            .where(Provider.id == provider_id)
            .options(
                selectinload(Provider.city),
                selectinload(Provider.zone),
                selectinload(Provider.schedules),
            )
        )
        return result.scalar_one_or_none()

    async def get_provider_by_slug(
        self, city_id: UUID, slug: str
    ) -> Optional[Provider]:
        """Get provider by city and slug."""
        result = await self.db.execute(
            select(Provider)
            .where(Provider.city_id == city_id, Provider.slug == slug)
            .options(
                selectinload(Provider.city),
                selectinload(Provider.zone),
                selectinload(Provider.schedules),
            )
        )
        return result.scalar_one_or_none()

    async def create_provider(
        self,
        user_id: UUID,
        name: str,
        provider_type: str,
        phone: str,
        address_line1: str,
        city_id: UUID,
        latitude: Decimal,
        longitude: Decimal,
        description: Optional[str] = None,
        email: Optional[str] = None,
        whatsapp: Optional[str] = None,
        landmark: Optional[str] = None,
        zone_id: Optional[UUID] = None,
        logo_url: Optional[str] = None,
        cover_image_url: Optional[str] = None,
        min_order_amount: int = 0,
        average_prep_time: int = 30,
        delivery_radius_km: Decimal = Decimal("5"),
        schedules: Optional[list[dict]] = None,
    ) -> Provider:
        """Create a new provider."""
        # Generate slug from name
        slug = self._generate_slug(name)

        # Check if slug exists in city
        existing = await self.get_provider_by_slug(city_id, slug)
        if existing:
            # Add suffix to make unique
            slug = f"{slug}-{str(user_id)[:8]}"

        provider = Provider(
            user_id=user_id,
            name=name,
            slug=slug,
            description=description,
            type=provider_type,
            phone=phone,
            email=email,
            whatsapp=whatsapp,
            address_line1=address_line1,
            landmark=landmark,
            city_id=city_id,
            zone_id=zone_id,
            latitude=latitude,
            longitude=longitude,
            logo_url=logo_url,
            cover_image_url=cover_image_url,
            min_order_amount=min_order_amount,
            average_prep_time=average_prep_time,
            delivery_radius_km=delivery_radius_km,
            status="pending",
        )
        self.db.add(provider)
        await self.db.flush()

        # Add schedules if provided
        if schedules:
            for schedule_data in schedules:
                schedule = ProviderSchedule(
                    provider_id=provider.id,
                    day_of_week=schedule_data["day_of_week"],
                    open_time=schedule_data["open_time"],
                    close_time=schedule_data["close_time"],
                    is_closed=schedule_data.get("is_closed", False),
                )
                self.db.add(schedule)

        await self.db.flush()

        # Reload with relationships
        return await self.get_provider(provider.id)

    async def update_provider(
        self,
        provider_id: UUID,
        user_id: UUID,
        **kwargs,
    ) -> Optional[Provider]:
        """Update provider (only owner can update)."""
        provider = await self.get_provider(provider_id)
        if not provider:
            return None

        # Check ownership
        if provider.user_id != user_id:
            return None

        # Update fields
        for key, value in kwargs.items():
            if value is not None and hasattr(provider, key):
                setattr(provider, key, value)

        await self.db.flush()

        # Invalidate cache
        await self._invalidate_provider_cache(provider_id)

        return await self.get_provider(provider_id)

    async def update_provider_status(
        self, provider_id: UUID, status: str
    ) -> Optional[Provider]:
        """Update provider status (admin only)."""
        provider = await self.get_provider(provider_id)
        if not provider:
            return None

        provider.status = status
        await self.db.flush()

        return provider

    async def toggle_provider_open(
        self, provider_id: UUID, user_id: UUID, is_open: bool
    ) -> Optional[Provider]:
        """Toggle provider open/closed status."""
        provider = await self.get_provider(provider_id)
        if not provider or provider.user_id != user_id:
            return None

        provider.is_open = is_open
        await self.db.flush()

        # Invalidate cache
        await self._invalidate_provider_cache(provider_id)

        return provider

    # =========================================================================
    # Provider Schedules
    # =========================================================================

    async def get_schedules(self, provider_id: UUID) -> list[ProviderSchedule]:
        """Get all schedules for a provider."""
        result = await self.db.execute(
            select(ProviderSchedule)
            .where(ProviderSchedule.provider_id == provider_id)
            .order_by(ProviderSchedule.day_of_week)
        )
        return list(result.scalars().all())

    async def update_schedule(
        self,
        provider_id: UUID,
        day_of_week: int,
        open_time: Optional[str] = None,
        close_time: Optional[str] = None,
        is_closed: Optional[bool] = None,
    ) -> Optional[ProviderSchedule]:
        """Update or create schedule for a day."""
        result = await self.db.execute(
            select(ProviderSchedule).where(
                ProviderSchedule.provider_id == provider_id,
                ProviderSchedule.day_of_week == day_of_week,
            )
        )
        schedule = result.scalar_one_or_none()

        if schedule:
            if open_time is not None:
                schedule.open_time = open_time
            if close_time is not None:
                schedule.close_time = close_time
            if is_closed is not None:
                schedule.is_closed = is_closed
        else:
            schedule = ProviderSchedule(
                provider_id=provider_id,
                day_of_week=day_of_week,
                open_time=open_time or "09:00",
                close_time=close_time or "21:00",
                is_closed=is_closed or False,
            )
            self.db.add(schedule)

        await self.db.flush()
        return schedule

    def is_provider_open_now(self, provider: Provider) -> bool:
        """Check if provider is currently open based on schedule."""
        if not provider.is_open:
            return False

        if provider.status != "active":
            return False

        now = datetime.now(timezone.utc)
        current_day = now.weekday()  # 0 = Monday
        current_time = now.time()

        for schedule in provider.schedules:
            if schedule.day_of_week == current_day:
                if schedule.is_closed:
                    return False
                return schedule.open_time <= current_time <= schedule.close_time

        # No schedule for today, consider closed
        return False

    # =========================================================================
    # Provider Search
    # =========================================================================

    async def list_providers(
        self,
        city_id: UUID,
        provider_type: Optional[str] = None,
        is_open_only: bool = False,
        is_featured_only: bool = False,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Provider], int]:
        """List providers with filters and pagination."""
        query = select(Provider).where(
            Provider.city_id == city_id,
            Provider.status == "active",
        )

        if provider_type:
            query = query.where(Provider.type == provider_type)

        if is_open_only:
            query = query.where(Provider.is_open == True)

        if is_featured_only:
            query = query.where(Provider.is_featured == True)

        if search:
            search_term = f"%{search}%"
            query = query.where(Provider.name.ilike(search_term))

        # Count total
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar()

        # Apply pagination
        query = (
            query.options(selectinload(Provider.schedules))
            .order_by(Provider.is_featured.desc(), Provider.average_rating.desc().nullslast())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )

        result = await self.db.execute(query)
        providers = list(result.scalars().all())

        return providers, total

    async def find_nearby_providers(
        self,
        latitude: Decimal,
        longitude: Decimal,
        radius_km: Decimal = Decimal("5"),
        provider_type: Optional[str] = None,
        is_open_only: bool = False,
        limit: int = 50,
    ) -> list[dict]:
        """Find providers within radius using PostGIS."""
        # Convert km to meters for ST_DWithin
        radius_meters = float(radius_km) * 1000

        # Build point geometry
        point = func.ST_SetSRID(
            func.ST_MakePoint(float(longitude), float(latitude)), 4326
        )

        # Calculate distance in km
        distance = (
            func.ST_Distance(
                func.ST_Transform(Provider.location, 3857),
                func.ST_Transform(point, 3857),
            )
            / 1000
        ).label("distance_km")

        query = (
            select(Provider, distance)
            .where(
                Provider.status == "active",
                func.ST_DWithin(
                    func.ST_Transform(Provider.location, 3857),
                    func.ST_Transform(point, 3857),
                    radius_meters,
                ),
            )
            .options(selectinload(Provider.schedules))
        )

        if provider_type:
            query = query.where(Provider.type == provider_type)

        if is_open_only:
            query = query.where(Provider.is_open == True)

        query = query.order_by(distance).limit(limit)

        result = await self.db.execute(query)
        rows = result.all()

        return [
            {
                "provider": provider,
                "distance_km": round(dist, 2) if dist else None,
            }
            for provider, dist in rows
        ]

    # =========================================================================
    # Provider Menu
    # =========================================================================

    async def get_provider_menu(self, provider_id: UUID) -> Optional[dict]:
        """Get provider's full menu with categories and products."""
        # Try cache first
        cache_key = f"provider_menu:{provider_id}"
        if self.redis:
            cached = await self.redis.get(cache_key)
            if cached:
                return json.loads(cached)

        provider = await self.get_provider(provider_id)
        if not provider:
            return None

        # Get categories with products
        categories_result = await self.db.execute(
            select(ProductCategory)
            .where(
                ProductCategory.provider_id == provider_id,
                ProductCategory.is_active == True,
            )
            .order_by(ProductCategory.display_order)
        )
        categories = list(categories_result.scalars().all())

        # Get products with options
        products_result = await self.db.execute(
            select(Product)
            .where(Product.provider_id == provider_id, Product.is_available == True)
            .options(selectinload(Product.options).selectinload("items"))
            .order_by(Product.display_order)
        )
        products = list(products_result.scalars().all())

        # Get gas products
        gas_result = await self.db.execute(
            select(GasProduct).where(
                GasProduct.provider_id == provider_id, GasProduct.is_available == True
            )
        )
        gas_products = list(gas_result.scalars().all())

        # Group products by category
        categorized = {cat.id: [] for cat in categories}
        uncategorized = []

        for product in products:
            if product.category_id and product.category_id in categorized:
                categorized[product.category_id].append(product)
            else:
                uncategorized.append(product)

        menu_data = {
            "provider_id": str(provider_id),
            "provider_name": provider.name,
            "categories": [
                {
                    "id": str(cat.id),
                    "name": cat.name,
                    "display_order": cat.display_order,
                    "products": [self._serialize_product(p) for p in categorized[cat.id]],
                }
                for cat in categories
            ],
            "uncategorized_products": [
                self._serialize_product(p) for p in uncategorized
            ],
            "gas_products": [self._serialize_gas_product(gp) for gp in gas_products],
            "total_products": len(products) + len(gas_products),
        }

        # Cache result
        if self.redis:
            await self.redis.setex(cache_key, self.CACHE_TTL, json.dumps(menu_data))

        return menu_data

    # =========================================================================
    # Geographic Data
    # =========================================================================

    async def get_cities(self, is_active_only: bool = True) -> list[City]:
        """Get all cities."""
        query = select(City).order_by(City.name)
        if is_active_only:
            query = query.where(City.is_active == True)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_city(self, city_id: UUID) -> Optional[City]:
        """Get city by ID."""
        result = await self.db.execute(select(City).where(City.id == city_id))
        return result.scalar_one_or_none()

    async def get_zones(
        self, city_id: UUID, is_active_only: bool = True
    ) -> list[Zone]:
        """Get zones for a city."""
        query = select(Zone).where(Zone.city_id == city_id).order_by(Zone.name)
        if is_active_only:
            query = query.where(Zone.is_active == True)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    # =========================================================================
    # Private Helpers
    # =========================================================================

    def _generate_slug(self, name: str) -> str:
        """Generate URL-friendly slug from name."""
        slug = name.lower()
        slug = re.sub(r"[àáâãäå]", "a", slug)
        slug = re.sub(r"[èéêë]", "e", slug)
        slug = re.sub(r"[ìíîï]", "i", slug)
        slug = re.sub(r"[òóôõö]", "o", slug)
        slug = re.sub(r"[ùúûü]", "u", slug)
        slug = re.sub(r"[ç]", "c", slug)
        slug = re.sub(r"[^a-z0-9]+", "-", slug)
        slug = slug.strip("-")
        return slug

    def _serialize_product(self, product: Product) -> dict:
        """Serialize product for JSON."""
        return {
            "id": str(product.id),
            "name": product.name,
            "description": product.description,
            "image_url": product.image_url,
            "price": product.price,
            "compare_at_price": product.compare_at_price,
            "is_available": product.is_available,
            "is_featured": product.is_featured,
            "is_vegetarian": product.is_vegetarian,
            "is_spicy": product.is_spicy,
            "prep_time": product.prep_time,
            "options": [
                {
                    "id": str(opt.id),
                    "name": opt.name,
                    "type": opt.type,
                    "is_required": opt.is_required,
                    "max_selections": opt.max_selections,
                    "items": [
                        {
                            "id": str(item.id),
                            "name": item.name,
                            "price_adjustment": item.price_adjustment,
                            "is_available": item.is_available,
                        }
                        for item in opt.items
                    ],
                }
                for opt in product.options
            ],
        }

    def _serialize_gas_product(self, gas_product: GasProduct) -> dict:
        """Serialize gas product for JSON."""
        return {
            "id": str(gas_product.id),
            "brand": gas_product.brand,
            "bottle_size": gas_product.bottle_size,
            "refill_price": gas_product.refill_price,
            "exchange_price": gas_product.exchange_price,
            "quantity_available": gas_product.quantity_available,
            "is_available": gas_product.is_available,
        }

    async def _invalidate_provider_cache(self, provider_id: UUID) -> None:
        """Invalidate provider-related caches."""
        if self.redis:
            await self.redis.delete(f"provider_menu:{provider_id}")
