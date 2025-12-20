"""
Event handlers for order and delivery events.
These handlers connect the EventBus to the notification service.
"""

import logging
from typing import Any
from uuid import UUID

from app.shared.events.event_bus import EventBus

logger = logging.getLogger(__name__)


# =============================================================================
# Order Event Handlers
# =============================================================================


async def handle_order_created(data: dict[str, Any]) -> None:
    """Handle order.created event."""
    logger.info(
        f"Order created: {data.get('order_reference')}",
        extra={"event": "order.created", "data": data},
    )

    # In production, this would:
    # 1. Get NotificationService from dependency container
    # 2. Notify customer that order was created
    # 3. Notify provider of new order
    # 4. Start timer for auto-cancellation if not confirmed


async def handle_order_confirmed(data: dict[str, Any]) -> None:
    """Handle order.confirmed event."""
    logger.info(
        f"Order confirmed: {data.get('order_reference')}",
        extra={"event": "order.confirmed", "data": data},
    )

    # Notify customer that order was confirmed
    # Start preparation timer


async def handle_order_ready(data: dict[str, Any]) -> None:
    """Handle order.ready event."""
    logger.info(
        f"Order ready: {data.get('order_reference')}",
        extra={"event": "order.ready", "data": data},
    )

    # Notify customer that order is ready
    # Trigger driver matching if not already assigned


async def handle_order_cancelled(data: dict[str, Any]) -> None:
    """Handle order.cancelled event."""
    logger.info(
        f"Order cancelled: {data.get('order_reference')}",
        extra={"event": "order.cancelled", "data": data},
    )

    # Notify customer of cancellation
    # If driver assigned, notify driver
    # Process refund if applicable


async def handle_order_delivered(data: dict[str, Any]) -> None:
    """Handle order.delivered event."""
    logger.info(
        f"Order delivered: {data.get('order_reference')}",
        extra={"event": "order.delivered", "data": data},
    )

    # Notify customer of delivery
    # Request rating
    # Process payment to provider and driver


# =============================================================================
# Delivery Event Handlers
# =============================================================================


async def handle_delivery_assigned(data: dict[str, Any]) -> None:
    """Handle delivery.assigned event."""
    logger.info(
        f"Delivery assigned: driver {data.get('driver_id')} for order {data.get('order_reference')}",
        extra={"event": "delivery.assigned", "data": data},
    )

    # Notify customer that driver was assigned
    # Notify driver of assignment confirmation


async def handle_delivery_picked_up(data: dict[str, Any]) -> None:
    """Handle delivery.picked_up event."""
    logger.info(
        f"Delivery picked up: {data.get('order_reference')}",
        extra={"event": "delivery.picked_up", "data": data},
    )

    # Notify customer that order is on the way
    # Start ETA tracking


async def handle_delivery_completed(data: dict[str, Any]) -> None:
    """Handle delivery.completed event."""
    logger.info(
        f"Delivery completed: {data.get('order_reference')}",
        extra={"event": "delivery.completed", "data": data},
    )

    # Notify customer of successful delivery
    # Calculate driver earnings
    # Update driver stats


async def handle_delivery_failed(data: dict[str, Any]) -> None:
    """Handle delivery.failed event."""
    logger.info(
        f"Delivery failed: {data.get('order_reference')}",
        extra={"event": "delivery.failed", "data": data},
    )

    # Notify customer of failed delivery
    # Process refund or reschedule


# =============================================================================
# Driver Event Handlers
# =============================================================================


async def handle_driver_offer_sent(data: dict[str, Any]) -> None:
    """Handle driver.offer_sent event."""
    logger.info(
        f"Offer sent to driver {data.get('driver_id')}",
        extra={"event": "driver.offer_sent", "data": data},
    )

    # Send push notification to driver


async def handle_driver_offer_expired(data: dict[str, Any]) -> None:
    """Handle driver.offer_expired event."""
    logger.info(
        f"Offer expired for driver {data.get('driver_id')}",
        extra={"event": "driver.offer_expired", "data": data},
    )

    # Notify driver that offer expired
    # Try next driver in queue


# =============================================================================
# Registration
# =============================================================================


def register_event_handlers() -> None:
    """Register all event handlers with the EventBus."""
    # Order events
    EventBus.subscribe("order.created", handle_order_created)
    EventBus.subscribe("order.confirmed", handle_order_confirmed)
    EventBus.subscribe("order.ready", handle_order_ready)
    EventBus.subscribe("order.cancelled", handle_order_cancelled)
    EventBus.subscribe("order.delivered", handle_order_delivered)

    # Delivery events
    EventBus.subscribe("delivery.assigned", handle_delivery_assigned)
    EventBus.subscribe("delivery.picked_up", handle_delivery_picked_up)
    EventBus.subscribe("delivery.completed", handle_delivery_completed)
    EventBus.subscribe("delivery.failed", handle_delivery_failed)

    # Driver events
    EventBus.subscribe("driver.offer_sent", handle_driver_offer_sent)
    EventBus.subscribe("driver.offer_expired", handle_driver_offer_expired)

    logger.info("Event handlers registered successfully")
