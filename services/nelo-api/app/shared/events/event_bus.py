"""
Internal Event Bus for module-to-module communication.
This will be replaced by RabbitMQ in Phase 2.
"""

import asyncio
import logging
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid4

logger = logging.getLogger(__name__)

EventHandler = Callable[[dict[str, Any]], Awaitable[None]]


@dataclass
class Event:
    """Internal event structure."""

    name: str
    data: dict[str, Any]
    id: UUID = field(default_factory=uuid4)
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict[str, Any]:
        """Convert event to dictionary."""
        return {
            "id": str(self.id),
            "name": self.name,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
        }


class EventBus:
    """
    In-process event bus for Phase 1.
    Follows publish-subscribe pattern for decoupled module communication.
    """

    _handlers: dict[str, list[EventHandler]] = {}

    @classmethod
    def subscribe(cls, event_name: str, handler: EventHandler) -> None:
        """Subscribe a handler to an event type."""
        if event_name not in cls._handlers:
            cls._handlers[event_name] = []
        cls._handlers[event_name].append(handler)
        logger.debug(f"Handler subscribed to '{event_name}'")

    @classmethod
    def unsubscribe(cls, event_name: str, handler: EventHandler) -> None:
        """Unsubscribe a handler from an event type."""
        if event_name in cls._handlers:
            try:
                cls._handlers[event_name].remove(handler)
            except ValueError:
                pass

    @classmethod
    async def publish(cls, event: Event) -> None:
        """Publish an event to all subscribed handlers."""
        handlers = cls._handlers.get(event.name, [])

        if not handlers:
            logger.debug(f"No handlers for event '{event.name}'")
            return

        logger.info(f"Publishing event '{event.name}' to {len(handlers)} handler(s)")

        # Execute handlers concurrently
        tasks = [cls._safe_execute(handler, event) for handler in handlers]
        await asyncio.gather(*tasks)

    @classmethod
    async def _safe_execute(cls, handler: EventHandler, event: Event) -> None:
        """Execute handler with error handling."""
        try:
            await handler(event.data)
        except Exception as e:
            logger.error(
                f"Error in handler for event '{event.name}': {e}",
                exc_info=True,
            )

    @classmethod
    def clear(cls) -> None:
        """Clear all handlers (useful for testing)."""
        cls._handlers.clear()
