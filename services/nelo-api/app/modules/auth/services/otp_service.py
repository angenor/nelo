"""OTP (One-Time Password) service for phone/email verification."""

import hashlib
import logging
import secrets
from datetime import timedelta

import redis.asyncio as redis

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# OTP Configuration
OTP_LENGTH = 6
OTP_TTL_SECONDS = 300  # 5 minutes
OTP_MAX_ATTEMPTS = 3
OTP_RATE_LIMIT_SECONDS = 60  # 1 minute between requests


class OTPService:
    """Service for generating and verifying OTP codes."""

    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    def _generate_code(self) -> str:
        """Generate a random 6-digit OTP code."""
        return "".join(secrets.choice("0123456789") for _ in range(OTP_LENGTH))

    def _hash_code(self, code: str) -> str:
        """Hash the OTP code for secure storage."""
        return hashlib.sha256(code.encode()).hexdigest()

    def _get_otp_key(self, phone: str, purpose: str) -> str:
        """Generate Redis key for OTP storage."""
        return f"otp:{purpose}:{phone}"

    def _get_attempts_key(self, phone: str, purpose: str) -> str:
        """Generate Redis key for attempts tracking."""
        return f"otp_attempts:{purpose}:{phone}"

    def _get_rate_limit_key(self, phone: str, purpose: str) -> str:
        """Generate Redis key for rate limiting."""
        return f"otp_rate:{purpose}:{phone}"

    async def can_send_otp(self, phone: str, purpose: str = "verify") -> tuple[bool, int]:
        """
        Check if we can send a new OTP (rate limiting).

        Returns:
            Tuple of (can_send, seconds_until_retry)
        """
        rate_key = self._get_rate_limit_key(phone, purpose)
        ttl = await self.redis.ttl(rate_key)

        if ttl > 0:
            return False, ttl

        return True, 0

    async def generate_and_store(
        self,
        phone: str,
        purpose: str = "verify",
    ) -> tuple[str, bool]:
        """
        Generate OTP and store in Redis.

        Args:
            phone: Phone number
            purpose: Purpose of OTP (verify, login, reset_pin)

        Returns:
            Tuple of (otp_code, success)
        """
        # Check rate limit
        can_send, wait_time = await self.can_send_otp(phone, purpose)
        if not can_send:
            logger.warning(f"OTP rate limited for {phone}, wait {wait_time}s")
            return "", False

        # Generate code
        code = self._generate_code()
        code_hash = self._hash_code(code)

        # Store in Redis
        otp_key = self._get_otp_key(phone, purpose)
        attempts_key = self._get_attempts_key(phone, purpose)
        rate_key = self._get_rate_limit_key(phone, purpose)

        # Use pipeline for atomic operations
        async with self.redis.pipeline() as pipe:
            # Store OTP hash
            pipe.setex(otp_key, OTP_TTL_SECONDS, code_hash)
            # Reset attempts
            pipe.setex(attempts_key, OTP_TTL_SECONDS, "0")
            # Set rate limit
            pipe.setex(rate_key, OTP_RATE_LIMIT_SECONDS, "1")
            await pipe.execute()

        logger.info(f"OTP generated for {phone} (purpose: {purpose})")
        return code, True

    async def verify(
        self,
        phone: str,
        code: str,
        purpose: str = "verify",
    ) -> tuple[bool, str]:
        """
        Verify OTP code.

        Args:
            phone: Phone number
            code: OTP code to verify
            purpose: Purpose of OTP

        Returns:
            Tuple of (success, error_message)
        """
        otp_key = self._get_otp_key(phone, purpose)
        attempts_key = self._get_attempts_key(phone, purpose)

        # Get stored hash
        stored_hash = await self.redis.get(otp_key)
        if not stored_hash:
            return False, "Code expiré ou invalide"

        # Check attempts
        attempts = await self.redis.get(attempts_key)
        attempts = int(attempts) if attempts else 0

        if attempts >= OTP_MAX_ATTEMPTS:
            # Delete OTP after max attempts
            await self.redis.delete(otp_key, attempts_key)
            return False, "Nombre maximum de tentatives atteint"

        # Verify code
        code_hash = self._hash_code(code)
        if code_hash != stored_hash:
            # Increment attempts
            await self.redis.incr(attempts_key)
            remaining = OTP_MAX_ATTEMPTS - attempts - 1
            return False, f"Code incorrect. {remaining} tentative(s) restante(s)"

        # Success - delete OTP
        await self.redis.delete(otp_key, attempts_key)
        logger.info(f"OTP verified for {phone} (purpose: {purpose})")
        return True, ""

    async def invalidate(self, phone: str, purpose: str = "verify") -> None:
        """Invalidate any existing OTP for a phone number."""
        otp_key = self._get_otp_key(phone, purpose)
        attempts_key = self._get_attempts_key(phone, purpose)
        await self.redis.delete(otp_key, attempts_key)


class SMSProvider:
    """
    SMS provider interface for sending OTP codes.
    In MVP, this is a stub - integrate Orange CI or Twilio later.
    """

    async def send_otp(self, phone: str, code: str) -> bool:
        """
        Send OTP via SMS.

        In development mode, just logs the code.
        In production, integrate with real SMS provider.
        """
        settings = get_settings()

        if settings.environment == "development":
            # In development, log the code (don't actually send SMS)
            logger.info(f"[DEV] SMS to {phone}: Votre code NELO est {code}")
            print(f"\n{'='*50}")
            print(f"  OTP for {phone}: {code}")
            print(f"{'='*50}\n")
            return True

        # TODO: Integrate with Orange CI or Twilio
        # Example for Twilio:
        # from twilio.rest import Client
        # client = Client(settings.twilio_sid, settings.twilio_token)
        # message = client.messages.create(
        #     body=f"Votre code NELO est {code}",
        #     from_=settings.twilio_phone,
        #     to=phone
        # )
        # return message.status == "queued"

        logger.warning(f"SMS provider not configured, OTP not sent to {phone}")
        return False
