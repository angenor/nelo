"""Internal event bus for module communication."""
from app.shared.events.event_bus import Event, EventBus
from app.shared.events.handlers import register_event_handlers

__all__ = ["Event", "EventBus", "register_event_handlers"]
