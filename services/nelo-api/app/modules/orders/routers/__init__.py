"""Orders module routers."""

from app.modules.orders.routers.orders import router as orders_router
from app.modules.orders.routers.providers import router as providers_router
from app.modules.orders.routers.products import router as products_router

__all__ = ["orders_router", "providers_router", "products_router"]
