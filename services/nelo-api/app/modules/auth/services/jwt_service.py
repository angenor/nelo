"""JWT service with token blacklisting."""

import hashlib
import logging
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

import redis.asyncio as redis
from jose import JWTError, jwt

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


class JWTService:
    """Service for JWT token operations with Redis blacklist."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    def _get_blacklist_key(self, jti: str) -> str:
        """Generate Redis key for token blacklist."""
        return f"token_blacklist:{jti}"

    def _hash_token(self, token: str) -> str:
        """Create a short hash of the token for the JTI."""
        return hashlib.sha256(token.encode()).hexdigest()[:16]

    def create_access_token(
        self,
        user_id: UUID,
        role: str,
        extra_claims: dict[str, Any] | None = None,
    ) -> str:
        """
        Create a JWT access token.

        Args:
            user_id: User UUID
            role: User role
            extra_claims: Additional claims to include

        Returns:
            JWT access token string
        """
        now = datetime.now(timezone.utc)
        expire = now + timedelta(minutes=settings.access_token_expire_minutes)

        payload = {
            "sub": str(user_id),
            "role": role,
            "type": "access",
            "iat": now,
            "exp": expire,
        }

        if extra_claims:
            payload.update(extra_claims)

        return jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)

    def create_refresh_token(
        self,
        user_id: UUID,
        session_id: UUID | None = None,
    ) -> tuple[str, datetime]:
        """
        Create a JWT refresh token.

        Args:
            user_id: User UUID
            session_id: Optional session UUID for tracking

        Returns:
            Tuple of (token, expiration_datetime)
        """
        now = datetime.now(timezone.utc)
        expire = now + timedelta(days=settings.refresh_token_expire_days)

        payload = {
            "sub": str(user_id),
            "type": "refresh",
            "iat": now,
            "exp": expire,
        }

        if session_id:
            payload["sid"] = str(session_id)

        token = jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)
        return token, expire

    def decode_token(self, token: str) -> dict[str, Any] | None:
        """
        Decode and validate a JWT token.

        Args:
            token: JWT token string

        Returns:
            Token payload if valid, None otherwise
        """
        try:
            payload = jwt.decode(
                token,
                settings.secret_key,
                algorithms=[settings.jwt_algorithm],
            )
            return payload
        except JWTError as e:
            logger.debug(f"Token decode error: {e}")
            return None

    def verify_access_token(self, token: str) -> dict[str, Any] | None:
        """
        Verify an access token.

        Args:
            token: JWT access token

        Returns:
            Token payload if valid, None otherwise
        """
        payload = self.decode_token(token)
        if not payload:
            return None

        if payload.get("type") != "access":
            return None

        return payload

    def verify_refresh_token(self, token: str) -> dict[str, Any] | None:
        """
        Verify a refresh token.

        Args:
            token: JWT refresh token

        Returns:
            Token payload if valid, None otherwise
        """
        payload = self.decode_token(token)
        if not payload:
            return None

        if payload.get("type") != "refresh":
            return None

        return payload

    async def is_blacklisted(self, token: str) -> bool:
        """
        Check if a token is blacklisted.

        Args:
            token: JWT token string

        Returns:
            True if blacklisted, False otherwise
        """
        jti = self._hash_token(token)
        key = self._get_blacklist_key(jti)
        return await self.redis.exists(key) > 0

    async def blacklist_token(self, token: str) -> None:
        """
        Add a token to the blacklist.

        The token is stored until its original expiration time.

        Args:
            token: JWT token to blacklist
        """
        payload = self.decode_token(token)
        if not payload:
            return

        jti = self._hash_token(token)
        key = self._get_blacklist_key(jti)

        # Calculate TTL until token expiration
        exp = payload.get("exp")
        if exp:
            now = datetime.now(timezone.utc)
            exp_dt = datetime.fromtimestamp(exp, tz=timezone.utc)
            ttl = int((exp_dt - now).total_seconds())

            if ttl > 0:
                await self.redis.setex(key, ttl, "1")
                logger.info(f"Token blacklisted (jti: {jti}, ttl: {ttl}s)")

    async def blacklist_user_tokens(self, user_id: UUID) -> None:
        """
        Blacklist all tokens for a user by storing a timestamp.

        Any token issued before this timestamp will be rejected.

        Args:
            user_id: User UUID
        """
        key = f"user_token_blacklist:{user_id}"
        timestamp = int(datetime.now(timezone.utc).timestamp())
        # Keep for max token lifetime (refresh token duration)
        ttl = settings.refresh_token_expire_days * 24 * 3600
        await self.redis.setex(key, ttl, str(timestamp))
        logger.info(f"All tokens blacklisted for user {user_id}")

    async def is_user_token_valid(self, user_id: str, token_iat: int) -> bool:
        """
        Check if a user's token is valid based on the blacklist timestamp.

        Args:
            user_id: User UUID string
            token_iat: Token issued-at timestamp

        Returns:
            True if token is valid, False if issued before blacklist
        """
        key = f"user_token_blacklist:{user_id}"
        blacklist_ts = await self.redis.get(key)

        if blacklist_ts:
            # Token is invalid if issued before blacklist timestamp
            if token_iat < int(blacklist_ts):
                return False

        return True
