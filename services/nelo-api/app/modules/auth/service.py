"""Auth module service - business logic for authentication."""

import secrets
import string
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

import redis.asyncio as redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.security import hash_password, verify_password
from app.modules.auth.models import KycLevel, Session, User, UserRole
from app.modules.auth.services.jwt_service import JWTService
from app.modules.auth.services.otp_service import OTPService, SMSProvider

settings = get_settings()


class AuthService:
    """Authentication service with OTP and JWT."""

    def __init__(
        self,
        db: AsyncSession,
        redis_client: redis.Redis,
    ):
        self.db = db
        self.redis = redis_client
        self.otp_service = OTPService(redis_client)
        self.jwt_service = JWTService(redis_client)
        self.sms_provider = SMSProvider()

    # =========================================================================
    # User operations
    # =========================================================================

    async def get_user_by_id(self, user_id: UUID) -> Optional[User]:
        """Get user by ID."""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_user_by_phone(self, phone: str) -> Optional[User]:
        """Get user by phone number."""
        result = await self.db.execute(
            select(User).where(User.phone == phone)
        )
        return result.scalar_one_or_none()

    async def create_user(
        self,
        phone: str,
        email: Optional[str] = None,
        password: Optional[str] = None,
        role: UserRole = UserRole.CLIENT,
    ) -> User:
        """Create a new user."""
        user = User(
            phone=phone,
            email=email,
            password_hash=hash_password(password) if password else None,
            role=role,
            phone_verified=True,  # Verified via OTP before registration
        )
        self.db.add(user)
        await self.db.flush()
        return user

    # =========================================================================
    # OTP operations
    # =========================================================================

    async def send_otp(
        self,
        phone: str,
        purpose: str = "verify",
    ) -> tuple[bool, str, int]:
        """
        Send OTP to phone number.

        Returns:
            Tuple of (success, message, wait_time)
        """
        # Check rate limit
        can_send, wait_time = await self.otp_service.can_send_otp(phone, purpose)
        if not can_send:
            return False, f"Veuillez attendre {wait_time} secondes", wait_time

        # Generate and store OTP
        code, success = await self.otp_service.generate_and_store(phone, purpose)
        if not success:
            return False, "Erreur lors de la génération du code", 0

        # Send SMS
        sms_sent = await self.sms_provider.send_otp(phone, code)
        if not sms_sent:
            return False, "Erreur lors de l'envoi du SMS", 0

        return True, "Code envoyé", 0

    async def verify_otp(
        self,
        phone: str,
        code: str,
        purpose: str = "verify",
    ) -> tuple[bool, str]:
        """
        Verify OTP code.

        Returns:
            Tuple of (success, error_message)
        """
        return await self.otp_service.verify(phone, code, purpose)

    # =========================================================================
    # Registration & Login
    # =========================================================================

    async def register(
        self,
        phone: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        email: Optional[str] = None,
        password: Optional[str] = None,
        referral_code: Optional[str] = None,
    ) -> tuple[User, str, str]:
        """
        Register a new user (phone must be verified via OTP first).

        Returns:
            Tuple of (user, access_token, refresh_token)
        """
        # Check if user already exists
        existing = await self.get_user_by_phone(phone)
        if existing:
            raise ValueError("Ce numéro de téléphone est déjà utilisé")

        # Create user
        user = await self.create_user(
            phone=phone,
            email=email,
            password=password,
        )

        # Create profile in users schema (via event or direct call)
        # This will be handled by the users module

        # Create tokens
        access_token, refresh_token = await self._create_session(user)

        return user, access_token, refresh_token

    async def login_with_otp(
        self,
        phone: str,
        device_id: Optional[str] = None,
        device_type: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> tuple[User, str, str]:
        """
        Login user after OTP verification.

        Returns:
            Tuple of (user, access_token, refresh_token)
        """
        user = await self.get_user_by_phone(phone)
        if not user:
            raise ValueError("Utilisateur non trouvé")

        if not user.is_active:
            raise ValueError("Compte désactivé")

        if user.is_blocked:
            raise ValueError(f"Compte bloqué: {user.blocked_reason or 'Contactez le support'}")

        # Update last login
        user.last_login_at = datetime.now(timezone.utc)
        user.failed_login_attempts = 0

        # Create session and tokens
        access_token, refresh_token = await self._create_session(
            user,
            device_id=device_id,
            device_type=device_type,
            ip_address=ip_address,
        )

        return user, access_token, refresh_token

    async def login_with_password(
        self,
        phone: str,
        password: str,
        device_id: Optional[str] = None,
        device_type: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> tuple[User, str, str]:
        """
        Login user with phone and password.

        Returns:
            Tuple of (user, access_token, refresh_token)
        """
        user = await self.get_user_by_phone(phone)
        if not user:
            raise ValueError("Identifiants invalides")

        # Check if locked
        if user.locked_until and user.locked_until > datetime.now(timezone.utc):
            raise ValueError("Compte temporairement verrouillé. Réessayez plus tard.")

        # Check password
        if not user.password_hash or not verify_password(password, user.password_hash):
            user.failed_login_attempts += 1

            # Lock after 5 failed attempts
            if user.failed_login_attempts >= 5:
                user.locked_until = datetime.now(timezone.utc) + timedelta(minutes=30)

            await self.db.flush()
            raise ValueError("Identifiants invalides")

        if not user.is_active:
            raise ValueError("Compte désactivé")

        if user.is_blocked:
            raise ValueError(f"Compte bloqué: {user.blocked_reason or 'Contactez le support'}")

        # Reset failed attempts and update last login
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login_at = datetime.now(timezone.utc)

        # Create session and tokens
        access_token, refresh_token = await self._create_session(
            user,
            device_id=device_id,
            device_type=device_type,
            ip_address=ip_address,
        )

        return user, access_token, refresh_token

    # =========================================================================
    # Token operations
    # =========================================================================

    async def refresh_tokens(
        self,
        refresh_token: str,
    ) -> tuple[str, str]:
        """
        Refresh access token using refresh token.

        Returns:
            Tuple of (new_access_token, new_refresh_token)
        """
        # Verify refresh token
        payload = self.jwt_service.verify_refresh_token(refresh_token)
        if not payload:
            raise ValueError("Token invalide")

        # Check if blacklisted
        if await self.jwt_service.is_blacklisted(refresh_token):
            raise ValueError("Token révoqué")

        user_id = UUID(payload["sub"])
        session_id = UUID(payload.get("sid")) if payload.get("sid") else None

        # Verify session exists and is active
        if session_id:
            result = await self.db.execute(
                select(Session).where(
                    Session.id == session_id,
                    Session.is_active == True,
                )
            )
            session = result.scalar_one_or_none()
            if not session:
                raise ValueError("Session expirée")

        # Get user
        user = await self.get_user_by_id(user_id)
        if not user or not user.is_active:
            raise ValueError("Utilisateur non trouvé")

        # Blacklist old refresh token
        await self.jwt_service.blacklist_token(refresh_token)

        # Create new tokens
        new_access_token = self.jwt_service.create_access_token(
            user_id=user.id,
            role=user.role.value,
        )
        new_refresh_token, _ = self.jwt_service.create_refresh_token(
            user_id=user.id,
            session_id=session_id,
        )

        return new_access_token, new_refresh_token

    async def logout(
        self,
        access_token: str,
        refresh_token: Optional[str] = None,
    ) -> None:
        """Logout user by blacklisting tokens."""
        # Blacklist access token
        await self.jwt_service.blacklist_token(access_token)

        # Blacklist refresh token if provided
        if refresh_token:
            await self.jwt_service.blacklist_token(refresh_token)

            # Deactivate session
            payload = self.jwt_service.verify_refresh_token(refresh_token)
            if payload and payload.get("sid"):
                session_id = UUID(payload["sid"])
                result = await self.db.execute(
                    select(Session).where(Session.id == session_id)
                )
                session = result.scalar_one_or_none()
                if session:
                    session.is_active = False

    async def logout_all(self, user_id: UUID) -> None:
        """Logout from all sessions."""
        # Blacklist all tokens for user
        await self.jwt_service.blacklist_user_tokens(user_id)

        # Deactivate all sessions
        result = await self.db.execute(
            select(Session).where(Session.user_id == user_id)
        )
        sessions = result.scalars().all()
        for session in sessions:
            session.is_active = False

    # =========================================================================
    # PIN operations
    # =========================================================================

    async def set_pin(self, user_id: UUID, pin: str) -> None:
        """Set user PIN."""
        user = await self.get_user_by_id(user_id)
        if not user:
            raise ValueError("Utilisateur non trouvé")

        user.pin_hash = hash_password(pin)

    async def verify_pin(self, user_id: UUID, pin: str) -> bool:
        """Verify user PIN."""
        user = await self.get_user_by_id(user_id)
        if not user or not user.pin_hash:
            return False

        return verify_password(pin, user.pin_hash)

    # =========================================================================
    # Private helpers
    # =========================================================================

    async def _create_session(
        self,
        user: User,
        device_id: Optional[str] = None,
        device_type: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> tuple[str, str]:
        """Create session and return tokens."""
        # Create session record
        refresh_token, expires_at = self.jwt_service.create_refresh_token(user.id)

        session = Session(
            user_id=user.id,
            refresh_token_hash=hash_password(refresh_token),
            device_id=device_id,
            device_type=device_type,
            ip_address=ip_address,
            expires_at=expires_at,
        )
        self.db.add(session)
        await self.db.flush()

        # Create access token
        access_token = self.jwt_service.create_access_token(
            user_id=user.id,
            role=user.role.value,
        )

        # Re-create refresh token with session ID
        refresh_token, _ = self.jwt_service.create_refresh_token(
            user_id=user.id,
            session_id=session.id,
        )

        # Update session with new hash
        session.refresh_token_hash = hash_password(refresh_token)

        return access_token, refresh_token

    def _generate_referral_code(self) -> str:
        """Generate unique referral code."""
        chars = string.ascii_uppercase + string.digits
        return "".join(secrets.choice(chars) for _ in range(8))
