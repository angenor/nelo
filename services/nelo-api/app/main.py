"""FastAPI application entry point."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.database import check_db_connection, engine
from app.core.redis import check_redis_connection, close_redis_pool
from app.shared.events import register_event_handlers

# Import module routers
from app.modules.auth.router import router as auth_router
from app.modules.users.router import router as users_router
from app.modules.orders.router import router as orders_module_router
from app.modules.orders.routers.orders import router as orders_router
from app.modules.orders.routers.providers import router as providers_router
from app.modules.orders.routers.products import router as products_router
from app.modules.deliveries.router import router as deliveries_router
from app.modules.payments.router import router as payments_router
from app.modules.notifications.router import router as notifications_router

settings = get_settings()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan events."""
    # Startup
    print(f"Starting {settings.app_name} v{settings.app_version}")
    print(f"Environment: {settings.environment}")

    # Register event handlers for order/delivery notifications
    register_event_handlers()
    print("Event handlers registered")

    yield

    # Shutdown
    await engine.dispose()
    await close_redis_pool()
    print("Shutdown complete")


def create_app() -> FastAPI:
    """Application factory."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="NELO Everything App - Backend API for proximity services",
        openapi_url=f"{settings.api_v1_prefix}/openapi.json",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Health check endpoints
    @app.get("/health", tags=["Health"])
    async def health_check() -> dict:
        """Basic health check."""
        return {"status": "healthy", "version": settings.app_version}

    @app.get("/health/ready", tags=["Health"])
    async def readiness_check() -> dict:
        """Readiness check with dependency status."""
        db_ok = await check_db_connection()
        redis_ok = await check_redis_connection()

        status = "ready" if (db_ok and redis_ok) else "not_ready"

        return {
            "status": status,
            "dependencies": {
                "database": "connected" if db_ok else "disconnected",
                "redis": "connected" if redis_ok else "disconnected",
            },
        }

    @app.get("/health/live", tags=["Health"])
    async def liveness_check() -> dict:
        """Liveness check for Kubernetes."""
        return {"status": "alive"}

    # Include API routers
    app.include_router(auth_router, prefix=settings.api_v1_prefix)
    app.include_router(users_router, prefix=settings.api_v1_prefix)
    app.include_router(orders_module_router, prefix=settings.api_v1_prefix)
    app.include_router(orders_router, prefix=settings.api_v1_prefix)
    app.include_router(providers_router, prefix=settings.api_v1_prefix)
    app.include_router(products_router, prefix=settings.api_v1_prefix)
    app.include_router(deliveries_router, prefix=settings.api_v1_prefix)
    app.include_router(payments_router, prefix=settings.api_v1_prefix)
    app.include_router(notifications_router, prefix=settings.api_v1_prefix)

    return app


app = create_app()
