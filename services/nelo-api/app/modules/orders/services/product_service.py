"""Product service for CRUD operations."""

from typing import Optional
from uuid import UUID

import redis.asyncio as redis
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import (
    GasProduct,
    Product,
    ProductCategory,
    ProductOption,
    ProductOptionItem,
    Provider,
)


class ProductService:
    """Service for product operations."""

    def __init__(self, db: AsyncSession, redis_client: Optional[redis.Redis] = None):
        self.db = db
        self.redis = redis_client

    # =========================================================================
    # Product Category CRUD
    # =========================================================================

    async def get_categories(self, provider_id: UUID) -> list[ProductCategory]:
        """Get all categories for a provider."""
        result = await self.db.execute(
            select(ProductCategory)
            .where(ProductCategory.provider_id == provider_id)
            .order_by(ProductCategory.display_order)
        )
        return list(result.scalars().all())

    async def get_category(
        self, provider_id: UUID, category_id: UUID
    ) -> Optional[ProductCategory]:
        """Get a specific category."""
        result = await self.db.execute(
            select(ProductCategory).where(
                ProductCategory.id == category_id,
                ProductCategory.provider_id == provider_id,
            )
        )
        return result.scalar_one_or_none()

    async def create_category(
        self,
        provider_id: UUID,
        name: str,
        display_order: int = 0,
        is_active: bool = True,
    ) -> ProductCategory:
        """Create a product category."""
        category = ProductCategory(
            provider_id=provider_id,
            name=name,
            display_order=display_order,
            is_active=is_active,
        )
        self.db.add(category)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return category

    async def update_category(
        self,
        provider_id: UUID,
        category_id: UUID,
        name: Optional[str] = None,
        display_order: Optional[int] = None,
        is_active: Optional[bool] = None,
    ) -> Optional[ProductCategory]:
        """Update a product category."""
        category = await self.get_category(provider_id, category_id)
        if not category:
            return None

        if name is not None:
            category.name = name
        if display_order is not None:
            category.display_order = display_order
        if is_active is not None:
            category.is_active = is_active

        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return category

    async def delete_category(self, provider_id: UUID, category_id: UUID) -> bool:
        """Delete a product category (products will have category_id set to NULL)."""
        category = await self.get_category(provider_id, category_id)
        if not category:
            return False

        await self.db.delete(category)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return True

    # =========================================================================
    # Product CRUD
    # =========================================================================

    async def get_products(
        self,
        provider_id: UUID,
        category_id: Optional[UUID] = None,
        is_available_only: bool = False,
        is_featured_only: bool = False,
    ) -> list[Product]:
        """Get products for a provider with filters."""
        query = (
            select(Product)
            .where(Product.provider_id == provider_id)
            .options(
                selectinload(Product.options).selectinload(ProductOption.items),
                selectinload(Product.category),
            )
        )

        if category_id:
            query = query.where(Product.category_id == category_id)
        if is_available_only:
            query = query.where(Product.is_available == True)
        if is_featured_only:
            query = query.where(Product.is_featured == True)

        query = query.order_by(Product.display_order)

        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_product(
        self, provider_id: UUID, product_id: UUID
    ) -> Optional[Product]:
        """Get a specific product with options."""
        result = await self.db.execute(
            select(Product)
            .where(Product.id == product_id, Product.provider_id == provider_id)
            .options(
                selectinload(Product.options).selectinload(ProductOption.items),
                selectinload(Product.category),
            )
        )
        return result.scalar_one_or_none()

    async def create_product(
        self,
        provider_id: UUID,
        name: str,
        price: int,
        category_id: Optional[UUID] = None,
        description: Optional[str] = None,
        image_url: Optional[str] = None,
        compare_at_price: Optional[int] = None,
        is_available: bool = True,
        is_featured: bool = False,
        is_vegetarian: bool = False,
        is_spicy: bool = False,
        prep_time: Optional[int] = None,
        display_order: int = 0,
        options: Optional[list[dict]] = None,
    ) -> Product:
        """Create a new product with optional options."""
        product = Product(
            provider_id=provider_id,
            category_id=category_id,
            name=name,
            description=description,
            image_url=image_url,
            price=price,
            compare_at_price=compare_at_price,
            is_available=is_available,
            is_featured=is_featured,
            is_vegetarian=is_vegetarian,
            is_spicy=is_spicy,
            prep_time=prep_time,
            display_order=display_order,
        )
        self.db.add(product)
        await self.db.flush()

        # Create options if provided
        if options:
            for opt_data in options:
                option = ProductOption(
                    product_id=product.id,
                    name=opt_data["name"],
                    type=opt_data.get("type", "single"),
                    is_required=opt_data.get("is_required", False),
                    max_selections=opt_data.get("max_selections", 1),
                )
                self.db.add(option)
                await self.db.flush()

                # Create option items
                for item_data in opt_data.get("items", []):
                    item = ProductOptionItem(
                        option_id=option.id,
                        name=item_data["name"],
                        price_adjustment=item_data.get("price_adjustment", 0),
                        is_available=item_data.get("is_available", True),
                    )
                    self.db.add(item)

        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        # Reload with relationships
        return await self.get_product(provider_id, product.id)

    async def update_product(
        self,
        provider_id: UUID,
        product_id: UUID,
        **kwargs,
    ) -> Optional[Product]:
        """Update a product."""
        product = await self.get_product(provider_id, product_id)
        if not product:
            return None

        # Update allowed fields
        allowed_fields = [
            "category_id",
            "name",
            "description",
            "image_url",
            "price",
            "compare_at_price",
            "is_available",
            "is_featured",
            "is_vegetarian",
            "is_spicy",
            "prep_time",
            "display_order",
        ]

        for key, value in kwargs.items():
            if key in allowed_fields and value is not None:
                setattr(product, key, value)

        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return await self.get_product(provider_id, product_id)

    async def delete_product(self, provider_id: UUID, product_id: UUID) -> bool:
        """Delete a product."""
        product = await self.get_product(provider_id, product_id)
        if not product:
            return False

        await self.db.delete(product)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return True

    async def toggle_product_availability(
        self, provider_id: UUID, product_id: UUID, is_available: bool
    ) -> Optional[Product]:
        """Toggle product availability."""
        return await self.update_product(
            provider_id, product_id, is_available=is_available
        )

    # =========================================================================
    # Product Options CRUD
    # =========================================================================

    async def get_product_options(self, product_id: UUID) -> list[ProductOption]:
        """Get all options for a product."""
        result = await self.db.execute(
            select(ProductOption)
            .where(ProductOption.product_id == product_id)
            .options(selectinload(ProductOption.items))
        )
        return list(result.scalars().all())

    async def add_product_option(
        self,
        provider_id: UUID,
        product_id: UUID,
        name: str,
        option_type: str = "single",
        is_required: bool = False,
        max_selections: int = 1,
        items: Optional[list[dict]] = None,
    ) -> Optional[ProductOption]:
        """Add an option to a product."""
        # Verify product exists and belongs to provider
        product = await self.get_product(provider_id, product_id)
        if not product:
            return None

        option = ProductOption(
            product_id=product_id,
            name=name,
            type=option_type,
            is_required=is_required,
            max_selections=max_selections,
        )
        self.db.add(option)
        await self.db.flush()

        # Create items
        if items:
            for item_data in items:
                item = ProductOptionItem(
                    option_id=option.id,
                    name=item_data["name"],
                    price_adjustment=item_data.get("price_adjustment", 0),
                    is_available=item_data.get("is_available", True),
                )
                self.db.add(item)

        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        # Reload option with items
        result = await self.db.execute(
            select(ProductOption)
            .where(ProductOption.id == option.id)
            .options(selectinload(ProductOption.items))
        )
        return result.scalar_one_or_none()

    async def delete_product_option(
        self, provider_id: UUID, product_id: UUID, option_id: UUID
    ) -> bool:
        """Delete a product option."""
        # Verify product exists and belongs to provider
        product = await self.get_product(provider_id, product_id)
        if not product:
            return False

        result = await self.db.execute(
            select(ProductOption).where(
                ProductOption.id == option_id, ProductOption.product_id == product_id
            )
        )
        option = result.scalar_one_or_none()
        if not option:
            return False

        await self.db.delete(option)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return True

    # =========================================================================
    # Gas Products CRUD
    # =========================================================================

    async def get_gas_products(
        self, provider_id: UUID, is_available_only: bool = False
    ) -> list[GasProduct]:
        """Get gas products for a provider."""
        query = select(GasProduct).where(GasProduct.provider_id == provider_id)

        if is_available_only:
            query = query.where(GasProduct.is_available == True)

        query = query.order_by(GasProduct.brand, GasProduct.bottle_size)

        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_gas_product(
        self, provider_id: UUID, gas_product_id: UUID
    ) -> Optional[GasProduct]:
        """Get a specific gas product."""
        result = await self.db.execute(
            select(GasProduct).where(
                GasProduct.id == gas_product_id, GasProduct.provider_id == provider_id
            )
        )
        return result.scalar_one_or_none()

    async def create_gas_product(
        self,
        provider_id: UUID,
        brand: str,
        bottle_size: str,
        refill_price: int,
        exchange_price: Optional[int] = None,
        quantity_available: int = 0,
        is_available: bool = True,
    ) -> GasProduct:
        """Create a gas product."""
        gas_product = GasProduct(
            provider_id=provider_id,
            brand=brand,
            bottle_size=bottle_size,
            refill_price=refill_price,
            exchange_price=exchange_price,
            quantity_available=quantity_available,
            is_available=is_available,
        )
        self.db.add(gas_product)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return gas_product

    async def update_gas_product(
        self,
        provider_id: UUID,
        gas_product_id: UUID,
        **kwargs,
    ) -> Optional[GasProduct]:
        """Update a gas product."""
        gas_product = await self.get_gas_product(provider_id, gas_product_id)
        if not gas_product:
            return None

        allowed_fields = [
            "brand",
            "bottle_size",
            "refill_price",
            "exchange_price",
            "quantity_available",
            "is_available",
        ]

        for key, value in kwargs.items():
            if key in allowed_fields and value is not None:
                setattr(gas_product, key, value)

        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return gas_product

    async def delete_gas_product(
        self, provider_id: UUID, gas_product_id: UUID
    ) -> bool:
        """Delete a gas product."""
        gas_product = await self.get_gas_product(provider_id, gas_product_id)
        if not gas_product:
            return False

        await self.db.delete(gas_product)
        await self.db.flush()

        # Invalidate menu cache
        await self._invalidate_menu_cache(provider_id)

        return True

    async def update_gas_stock(
        self, provider_id: UUID, gas_product_id: UUID, quantity: int
    ) -> Optional[GasProduct]:
        """Update gas product stock quantity."""
        return await self.update_gas_product(
            provider_id, gas_product_id, quantity_available=quantity
        )

    # =========================================================================
    # Private Helpers
    # =========================================================================

    async def _invalidate_menu_cache(self, provider_id: UUID) -> None:
        """Invalidate provider menu cache."""
        if self.redis:
            await self.redis.delete(f"provider_menu:{provider_id}")
