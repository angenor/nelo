"""Orders module routers."""

from app.modules.orders.routers.providers import router as providers_router
from app.modules.orders.routers.products import router as products_router

__all__ = ["providers_router", "products_router"]
