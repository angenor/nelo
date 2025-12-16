"""Redis async client configuration."""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

import redis.asyncio as redis
from redis.asyncio.connection import ConnectionPool

from app.core.config import get_settings

settings = get_settings()

# Connection pool
_pool: ConnectionPool | None = None


async def get_redis_pool() -> ConnectionPool:
    """Get or create Redis connection pool."""
    global _pool
    if _pool is None:
        _pool = ConnectionPool.from_url(
            str(settings.redis_url),
            max_connections=settings.redis_pool_size,
            decode_responses=True,
        )
    return _pool


async def get_redis() -> AsyncGenerator[redis.Redis, None]:
    """Dependency for FastAPI to get a Redis client."""
    pool = await get_redis_pool()
    client = redis.Redis(connection_pool=pool)
    try:
        yield client
    finally:
        await client.aclose()


@asynccontextmanager
async def get_redis_context() -> AsyncGenerator[redis.Redis, None]:
    """Context manager for Redis operations outside FastAPI."""
    pool = await get_redis_pool()
    client = redis.Redis(connection_pool=pool)
    try:
        yield client
    finally:
        await client.aclose()


async def check_redis_connection() -> bool:
    """Check Redis connectivity."""
    try:
        async with get_redis_context() as client:
            await client.ping()
        return True
    except Exception:
        return False


async def close_redis_pool() -> None:
    """Close Redis connection pool on shutdown."""
    global _pool
    if _pool is not None:
        await _pool.disconnect()
        _pool = None
