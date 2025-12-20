"""Orders module service with state machine."""

import random
import string
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import (
    GasProduct,
    Order,
    OrderItem,
    OrderStatus,
    Product,
    Provider,
)
from app.shared.events.event_bus import EventBus, Event


class OrderStateMachine:
    """State machine for order status transitions."""

    # Valid transitions: current_status -> [allowed_next_statuses]
    TRANSITIONS = {
        OrderStatus.PENDING: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
        OrderStatus.CONFIRMED: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
        OrderStatus.PREPARING: [OrderStatus.READY, OrderStatus.CANCELLED],
        OrderStatus.READY: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
        OrderStatus.PICKED_UP: [OrderStatus.DELIVERING, OrderStatus.CANCELLED],
        OrderStatus.DELIVERING: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
        OrderStatus.DELIVERED: [OrderStatus.REFUNDED],
        OrderStatus.CANCELLED: [],
        OrderStatus.REFUNDED: [],
    }

    @classmethod
    def can_transition(cls, from_status: OrderStatus, to_status: OrderStatus) -> bool:
        """Check if transition is valid."""
        allowed = cls.TRANSITIONS.get(from_status, [])
        return to_status in allowed

    @classmethod
    def get_allowed_transitions(cls, status: OrderStatus) -> list[OrderStatus]:
        """Get allowed next statuses."""
        return cls.TRANSITIONS.get(status, [])


class OrderService:
    """Service for order operations."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.state_machine = OrderStateMachine()

    # =========================================================================
    # Order Creation
    # =========================================================================

    async def create_order(
        self,
        user_id: UUID,
        provider_id: UUID,
        items: list[dict],
        delivery_address: dict,
        payment_method: str,
        special_instructions: Optional[str] = None,
        promotion_code: Optional[str] = None,
        tip_amount: int = 0,
        is_scheduled: bool = False,
        scheduled_for: Optional[datetime] = None,
    ) -> Order:
        """Create a new order with cart validation."""
        # Validate provider
        provider = await self._get_provider(provider_id)
        if not provider:
            raise ValueError("Prestataire non trouve")
        if not provider.is_open:
            raise ValueError("Le prestataire est ferme")
        if provider.status != "active":
            raise ValueError("Le prestataire n'est pas actif")

        # Validate and calculate items
        order_items, subtotal = await self._validate_and_calculate_items(
            provider_id, items
        )

        # Check minimum order amount
        if subtotal < provider.min_order_amount:
            raise ValueError(
                f"Commande minimum: {provider.min_order_amount} FCFA"
            )

        # Calculate fees
        delivery_fee = await self._calculate_delivery_fee(
            provider, delivery_address
        )
        service_fee = self._calculate_service_fee(subtotal)

        # Apply promotion if provided
        discount_amount = 0
        promotion_id = None
        if promotion_code:
            discount_amount, promotion_id = await self._apply_promotion(
                user_id, promotion_code, subtotal
            )

        # Calculate total
        total = subtotal + delivery_fee + service_fee - discount_amount + tip_amount

        # Generate reference
        reference = self._generate_reference()

        # Create order
        order = Order(
            reference=reference,
            user_id=user_id,
            provider_id=provider_id,
            service_type=provider.type,
            status=OrderStatus.PENDING.value,
            delivery_address_id=delivery_address.get("id"),
            delivery_address_snapshot=delivery_address,
            special_instructions=special_instructions,
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            service_fee=service_fee,
            discount_amount=discount_amount,
            tip_amount=tip_amount,
            total=total,
            promotion_id=promotion_id,
            promotion_code=promotion_code,
            payment_method=payment_method,
            is_scheduled=is_scheduled,
            scheduled_for=scheduled_for,
            estimated_prep_time=provider.average_prep_time,
        )
        self.db.add(order)
        await self.db.flush()

        # Create order items
        for item_data in order_items:
            order_item = OrderItem(
                order_id=order.id,
                product_id=item_data.get("product_id"),
                gas_product_id=item_data.get("gas_product_id"),
                product_name=item_data["name"],
                product_image_url=item_data.get("image_url"),
                quantity=item_data["quantity"],
                unit_price=item_data["unit_price"],
                total_price=item_data["total_price"],
                selected_options=item_data.get("selected_options", []),
                special_instructions=item_data.get("special_instructions"),
            )
            self.db.add(order_item)

        await self.db.flush()

        # Record initial status in history
        await self._record_status_change(order.id, None, OrderStatus.PENDING, user_id)

        # Publish event
        await EventBus.publish(Event(
            name="order.created",
            data={
                "order_id": str(order.id),
                "reference": order.reference,
                "user_id": str(user_id),
                "provider_id": str(provider_id),
                "total": total,
            }
        ))

        return await self.get_order(order.id)

    async def _validate_and_calculate_items(
        self, provider_id: UUID, items: list[dict]
    ) -> tuple[list[dict], int]:
        """Validate items and calculate prices."""
        if not items:
            raise ValueError("Le panier est vide")

        order_items = []
        subtotal = 0

        for item in items:
            product_id = item.get("product_id")
            gas_product_id = item.get("gas_product_id")
            quantity = item.get("quantity", 1)

            if quantity < 1:
                raise ValueError("Quantite invalide")

            if product_id:
                # Standard product
                product = await self._get_product(provider_id, product_id)
                if not product:
                    raise ValueError(f"Produit non trouve: {product_id}")
                if not product.is_available:
                    raise ValueError(f"Produit non disponible: {product.name}")

                # Calculate base price
                unit_price = product.price

                # Add selected options
                selected_options = []
                for opt in item.get("options", []):
                    option_item = await self._get_option_item(opt["item_id"])
                    if option_item and option_item.is_available:
                        unit_price += option_item.price_adjustment
                        selected_options.append({
                            "option_id": str(opt.get("option_id")),
                            "item_id": str(opt["item_id"]),
                            "name": option_item.name,
                            "price_adjustment": option_item.price_adjustment,
                        })

                total_price = unit_price * quantity
                subtotal += total_price

                order_items.append({
                    "product_id": product_id,
                    "name": product.name,
                    "image_url": product.image_url,
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "total_price": total_price,
                    "selected_options": selected_options,
                    "special_instructions": item.get("special_instructions"),
                })

            elif gas_product_id:
                # Gas product
                gas_product = await self._get_gas_product(provider_id, gas_product_id)
                if not gas_product:
                    raise ValueError(f"Produit gaz non trouve: {gas_product_id}")
                if not gas_product.is_available:
                    raise ValueError(f"Produit gaz non disponible: {gas_product.brand}")
                if gas_product.quantity_available < quantity:
                    raise ValueError(f"Stock insuffisant pour {gas_product.brand}")

                # Use refill price by default
                unit_price = gas_product.refill_price
                if item.get("is_exchange") and gas_product.exchange_price:
                    unit_price = gas_product.exchange_price

                total_price = unit_price * quantity
                subtotal += total_price

                order_items.append({
                    "gas_product_id": gas_product_id,
                    "name": f"{gas_product.brand} {gas_product.bottle_size}",
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "total_price": total_price,
                    "selected_options": [],
                })

            else:
                raise ValueError("Item sans produit valide")

        return order_items, subtotal

    async def _calculate_delivery_fee(
        self, _provider: Provider, _delivery_address: dict
    ) -> int:
        """Calculate delivery fee based on distance."""
        # Simple flat fee for MVP
        # TODO: Use PostGIS to calculate actual distance using _provider and _delivery_address
        base_fee = 500  # 500 FCFA base

        # Could add distance-based calculation here
        # For now, return base fee
        return base_fee

    def _calculate_service_fee(self, subtotal: int) -> int:
        """Calculate service fee (percentage of subtotal)."""
        # 2% service fee, minimum 100 FCFA
        fee = int(subtotal * 0.02)
        return max(fee, 100)

    async def _apply_promotion(
        self, _user_id: UUID, _code: str, _subtotal: int
    ) -> tuple[int, Optional[UUID]]:
        """Apply promotion code and return discount amount."""
        # TODO: Implement promotion validation using _user_id, _code, _subtotal
        # For now, return no discount
        return 0, None

    def _generate_reference(self) -> str:
        """Generate unique order reference."""
        chars = string.ascii_uppercase + string.digits
        suffix = "".join(random.choices(chars, k=8))
        return f"ORD-{suffix}"

    # =========================================================================
    # Order Status Management
    # =========================================================================

    async def update_order_status(
        self,
        order_id: UUID,
        new_status: OrderStatus,
        changed_by: UUID,
        reason: Optional[str] = None,
    ) -> Order:
        """Update order status with validation."""
        order = await self.get_order(order_id)
        if not order:
            raise ValueError("Commande non trouvee")

        current_status = OrderStatus(order.status)

        # Validate transition
        if not self.state_machine.can_transition(current_status, new_status):
            raise ValueError(
                f"Transition invalide: {current_status.value} -> {new_status.value}"
            )

        # Update status
        order.status = new_status.value

        # Update timestamps based on status
        now = datetime.now(timezone.utc)
        if new_status == OrderStatus.CONFIRMED:
            order.confirmed_at = now
        elif new_status == OrderStatus.READY:
            order.ready_at = now
        elif new_status == OrderStatus.PICKED_UP:
            order.picked_up_at = now
        elif new_status == OrderStatus.DELIVERED:
            order.delivered_at = now
        elif new_status == OrderStatus.CANCELLED:
            order.cancelled_at = now
            order.cancellation_reason = reason
            order.cancelled_by = str(changed_by)

        await self.db.flush()

        # Record status change
        await self._record_status_change(
            order_id, current_status, new_status, changed_by, reason
        )

        # Publish event
        await EventBus.publish(Event(
            name=f"order.{new_status.value}",
            data={
                "order_id": str(order_id),
                "reference": order.reference,
                "from_status": current_status.value,
                "to_status": new_status.value,
            }
        ))

        return order

    async def confirm_order(self, order_id: UUID, provider_user_id: UUID) -> Order:
        """Confirm an order (provider action)."""
        order = await self.get_order(order_id)
        if not order:
            raise ValueError("Commande non trouvee")

        # Verify provider ownership
        provider = await self._get_provider(order.provider_id)
        if not provider or provider.user_id != provider_user_id:
            raise ValueError("Non autorise")

        return await self.update_order_status(
            order_id, OrderStatus.CONFIRMED, provider_user_id
        )

    async def cancel_order(
        self, order_id: UUID, cancelled_by: UUID, reason: str
    ) -> Order:
        """Cancel an order."""
        return await self.update_order_status(
            order_id, OrderStatus.CANCELLED, cancelled_by, reason
        )

    async def _record_status_change(
        self,
        order_id: UUID,
        from_status: Optional[OrderStatus],
        to_status: OrderStatus,
        changed_by: UUID,
        reason: Optional[str] = None,
    ) -> None:
        """Record status change in history."""
        from sqlalchemy import text

        # Insert into order_status_history table
        await self.db.execute(
            text("""
                INSERT INTO orders.order_status_history
                (order_id, from_status, to_status, changed_by, changed_by_type, reason)
                VALUES (:order_id, :from_status, :to_status, :changed_by, :changed_by_type, :reason)
            """),
            {
                "order_id": order_id,
                "from_status": from_status.value if from_status else None,
                "to_status": to_status.value,
                "changed_by": changed_by,
                "changed_by_type": "user",  # Could be user, system, admin
                "reason": reason,
            }
        )

    # =========================================================================
    # Order Queries
    # =========================================================================

    async def get_order(self, order_id: UUID) -> Optional[Order]:
        """Get order by ID with items."""
        result = await self.db.execute(
            select(Order)
            .where(Order.id == order_id)
            .options(
                selectinload(Order.items),
                selectinload(Order.provider),
            )
        )
        return result.scalar_one_or_none()

    async def get_order_by_reference(self, reference: str) -> Optional[Order]:
        """Get order by reference."""
        result = await self.db.execute(
            select(Order)
            .where(Order.reference == reference)
            .options(
                selectinload(Order.items),
                selectinload(Order.provider),
            )
        )
        return result.scalar_one_or_none()

    async def list_user_orders(
        self,
        user_id: UUID,
        status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Order], int]:
        """List orders for a user."""
        query = select(Order).where(Order.user_id == user_id)

        if status:
            query = query.where(Order.status == status)

        # Count total
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar()

        # Apply pagination
        query = (
            query.options(selectinload(Order.items), selectinload(Order.provider))
            .order_by(Order.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )

        result = await self.db.execute(query)
        orders = list(result.scalars().all())

        return orders, total

    async def list_provider_orders(
        self,
        provider_id: UUID,
        status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Order], int]:
        """List orders for a provider."""
        query = select(Order).where(Order.provider_id == provider_id)

        if status:
            query = query.where(Order.status == status)

        # Count total
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar()

        # Apply pagination
        query = (
            query.options(selectinload(Order.items))
            .order_by(Order.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )

        result = await self.db.execute(query)
        orders = list(result.scalars().all())

        return orders, total

    async def get_order_status_history(self, order_id: UUID) -> list[dict]:
        """Get order status history."""
        from sqlalchemy import text

        result = await self.db.execute(
            text("""
                SELECT id, from_status, to_status, changed_by, changed_by_type, reason, created_at
                FROM orders.order_status_history
                WHERE order_id = :order_id
                ORDER BY created_at ASC
            """),
            {"order_id": order_id}
        )
        rows = result.fetchall()

        return [
            {
                "id": str(row.id),
                "from_status": row.from_status,
                "to_status": row.to_status,
                "changed_by": str(row.changed_by) if row.changed_by else None,
                "changed_by_type": row.changed_by_type,
                "reason": row.reason,
                "created_at": row.created_at.isoformat(),
            }
            for row in rows
        ]

    # =========================================================================
    # Order Tracking
    # =========================================================================

    async def get_order_tracking(self, order_id: UUID) -> dict:
        """Get order tracking information."""
        order = await self.get_order(order_id)
        if not order:
            raise ValueError("Commande non trouvee")

        # Get status history
        history = await self.get_order_status_history(order_id)

        # Get delivery info if exists
        delivery_info = await self._get_delivery_info(order_id)

        return {
            "order_id": str(order.id),
            "reference": order.reference,
            "status": order.status,
            "provider": {
                "id": str(order.provider.id),
                "name": order.provider.name,
                "phone": order.provider.phone,
            } if order.provider else None,
            "delivery_address": order.delivery_address_snapshot,
            "estimated_prep_time": order.estimated_prep_time,
            "estimated_delivery_time": order.estimated_delivery_time,
            "confirmed_at": order.confirmed_at.isoformat() if order.confirmed_at else None,
            "ready_at": order.ready_at.isoformat() if order.ready_at else None,
            "picked_up_at": order.picked_up_at.isoformat() if order.picked_up_at else None,
            "delivered_at": order.delivered_at.isoformat() if order.delivered_at else None,
            "status_history": history,
            "delivery": delivery_info,
        }

    async def _get_delivery_info(self, order_id: UUID) -> Optional[dict]:
        """Get delivery information for an order."""
        from sqlalchemy import text

        result = await self.db.execute(
            text("""
                SELECT d.id, d.reference, d.status, d.driver_id,
                       dr.first_name, dr.last_name, dr.phone, dr.avatar_url,
                       dr.vehicle_type, dr.vehicle_plate,
                       d.eta_minutes, d.delivery_code
                FROM deliveries.deliveries d
                LEFT JOIN deliveries.drivers dr ON d.driver_id = dr.id
                WHERE d.order_id = :order_id
            """),
            {"order_id": order_id}
        )
        row = result.fetchone()

        if not row:
            return None

        return {
            "id": str(row.id),
            "reference": row.reference,
            "status": row.status,
            "eta_minutes": row.eta_minutes,
            "delivery_code": row.delivery_code,
            "driver": {
                "id": str(row.driver_id),
                "name": f"{row.first_name} {row.last_name}",
                "phone": row.phone,
                "avatar_url": row.avatar_url,
                "vehicle_type": row.vehicle_type,
                "vehicle_plate": row.vehicle_plate,
            } if row.driver_id else None,
        }

    # =========================================================================
    # Private Helpers
    # =========================================================================

    async def _get_provider(self, provider_id: UUID) -> Optional[Provider]:
        """Get provider by ID."""
        result = await self.db.execute(
            select(Provider).where(Provider.id == provider_id)
        )
        return result.scalar_one_or_none()

    async def _get_product(self, provider_id: UUID, product_id: UUID) -> Optional[Product]:
        """Get product by ID."""
        result = await self.db.execute(
            select(Product).where(
                Product.id == product_id,
                Product.provider_id == provider_id,
            )
        )
        return result.scalar_one_or_none()

    async def _get_gas_product(
        self, provider_id: UUID, gas_product_id: UUID
    ) -> Optional[GasProduct]:
        """Get gas product by ID."""
        result = await self.db.execute(
            select(GasProduct).where(
                GasProduct.id == gas_product_id,
                GasProduct.provider_id == provider_id,
            )
        )
        return result.scalar_one_or_none()

    async def _get_option_item(self, item_id: UUID):
        """Get product option item by ID."""
        from app.modules.orders.models import ProductOptionItem

        result = await self.db.execute(
            select(ProductOptionItem).where(ProductOptionItem.id == item_id)
        )
        return result.scalar_one_or_none()
