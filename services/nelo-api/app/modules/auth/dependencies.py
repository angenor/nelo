"""Auth module dependencies - authentication middleware."""

from typing import Annotated, Optional
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import redis.asyncio as redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.redis import get_redis
from app.modules.auth.models import User, UserRole
from app.modules.auth.services.jwt_service import JWTService

# HTTP Bearer scheme for Swagger UI
security = HTTPBearer(auto_error=False)


async def get_current_user_id(
    token: str,
    redis_client: redis.Redis,
) -> Optional[UUID]:
    """
    Extract and validate user ID from access token.

    Args:
        token: JWT access token
        redis_client: Redis client for blacklist check

    Returns:
        User UUID if valid, None otherwise
    """
    jwt_service = JWTService(redis_client)

    # Verify token
    payload = jwt_service.verify_access_token(token)
    if not payload:
        return None

    # Check blacklist
    if await jwt_service.is_blacklisted(token):
        return None

    # Check user-level blacklist (logout all)
    user_id = payload.get("sub")
    token_iat = payload.get("iat")
    if user_id and token_iat:
        if not await jwt_service.is_user_token_valid(user_id, token_iat):
            return None

    return UUID(user_id) if user_id else None


async def get_current_user(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> User:
    """
    Get the current authenticated user.

    Raises:
        HTTPException: If token is invalid or user not found
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token d'authentification requis",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = await get_current_user_id(credentials.credentials, redis_client)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Get user from database
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur non trouvé",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé",
        )

    if user.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Compte bloqué: {user.blocked_reason or 'Contactez le support'}",
        )

    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Get current active user (alias for get_current_user with active check)."""
    return current_user


async def get_optional_user(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> Optional[User]:
    """
    Get the current user if authenticated, None otherwise.

    Use this for endpoints that work with or without authentication.
    """
    if not credentials:
        return None

    user_id = await get_current_user_id(credentials.credentials, redis_client)
    if not user_id:
        return None

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user and user.is_active and not user.is_blocked:
        return user

    return None


# =============================================================================
# Role-based access control
# =============================================================================

def require_role(*allowed_roles: UserRole):
    """
    Dependency factory for role-based access control.

    Usage:
        @router.get("/admin")
        async def admin_endpoint(user: User = Depends(require_role(UserRole.ADMIN))):
            ...
    """

    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé pour ce rôle",
            )
        return current_user

    return role_checker


def require_any_role(*allowed_roles: UserRole):
    """Alias for require_role - requires any of the specified roles."""
    return require_role(*allowed_roles)


def require_admin():
    """Require admin role."""
    return require_role(UserRole.ADMIN)


def require_provider():
    """Require provider role."""
    return require_role(UserRole.PROVIDER)


def require_driver():
    """Require driver role."""
    return require_role(UserRole.DRIVER)


# =============================================================================
# Type aliases for dependency injection
# =============================================================================

CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[Optional[User], Depends(get_optional_user)]
AdminUser = Annotated[User, Depends(require_admin())]
ProviderUser = Annotated[User, Depends(require_provider())]
DriverUser = Annotated[User, Depends(require_driver())]
