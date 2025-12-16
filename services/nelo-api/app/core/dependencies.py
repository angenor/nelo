"""FastAPI dependencies."""

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
import redis.asyncio as redis

from app.core.database import get_db_session
from app.core.redis import get_redis

# Type aliases for dependency injection
DBSession = Annotated[AsyncSession, Depends(get_db_session)]
RedisClient = Annotated[redis.Redis, Depends(get_redis)]
