"""Auth module API routes."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_db_session
from app.core.redis import get_redis
from app.modules.auth.schemas import (
    AuthResponse,
    LoginRequest,
    MessageResponse,
    OTPSentResponse,
    RefreshTokenRequest,
    RegisterRequest,
    SendOTPRequest,
    SetPINRequest,
    TokenResponse,
    UserResponse,
    VerifyOTPRequest,
    VerifyPINRequest,
)
from app.modules.auth.service import AuthService

router = APIRouter(prefix="/auth", tags=["Auth"])
settings = get_settings()


def get_auth_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> AuthService:
    """Dependency to get auth service."""
    return AuthService(db, redis_client)


AuthServiceDep = Annotated[AuthService, Depends(get_auth_service)]


# =============================================================================
# OTP Endpoints
# =============================================================================

@router.post(
    "/send-otp",
    response_model=OTPSentResponse,
    summary="Envoyer un code OTP",
    description="Envoie un code OTP par SMS au numéro de téléphone fourni.",
)
async def send_otp(
    request: SendOTPRequest,
    auth_service: AuthServiceDep,
) -> OTPSentResponse:
    """Send OTP to phone number."""
    success, message, wait_time = await auth_service.send_otp(
        phone=request.phone,
        purpose=request.purpose,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS if wait_time > 0 else status.HTTP_400_BAD_REQUEST,
            detail=message,
        )

    return OTPSentResponse(message=message, expires_in=300)


@router.post(
    "/verify-otp",
    response_model=MessageResponse,
    summary="Vérifier un code OTP",
    description="Vérifie le code OTP envoyé par SMS.",
)
async def verify_otp(
    request: VerifyOTPRequest,
    auth_service: AuthServiceDep,
) -> MessageResponse:
    """Verify OTP code."""
    success, error = await auth_service.verify_otp(
        phone=request.phone,
        code=request.code,
        purpose=request.purpose,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    return MessageResponse(message="Code vérifié")


# =============================================================================
# Registration & Login
# =============================================================================

@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Inscription",
    description="Crée un nouveau compte utilisateur. Le numéro doit être vérifié via OTP au préalable.",
)
async def register(
    request: RegisterRequest,
    auth_service: AuthServiceDep,
) -> AuthResponse:
    """Register a new user."""
    try:
        user, access_token, refresh_token = await auth_service.register(
            phone=request.phone,
            first_name=request.first_name,
            last_name=request.last_name,
            email=request.email,
            password=request.password,
            referral_code=request.referral_code,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.access_token_expire_minutes * 60,
        ),
    )


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Connexion",
    description="Connecte un utilisateur avec téléphone + OTP ou téléphone + mot de passe.",
)
async def login(
    request: LoginRequest,
    auth_service: AuthServiceDep,
    http_request: Request,
    x_device_id: Annotated[str | None, Header()] = None,
    x_device_type: Annotated[str | None, Header()] = None,
) -> AuthResponse:
    """Login user."""
    # Get client IP
    ip_address = http_request.client.host if http_request.client else None

    try:
        if request.otp_code:
            # First verify OTP
            success, error = await auth_service.verify_otp(
                phone=request.phone,
                code=request.otp_code,
                purpose="login",
            )
            if not success:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=error,
                )

            # Then login
            user, access_token, refresh_token = await auth_service.login_with_otp(
                phone=request.phone,
                device_id=x_device_id,
                device_type=x_device_type,
                ip_address=ip_address,
            )
        elif request.password:
            user, access_token, refresh_token = await auth_service.login_with_password(
                phone=request.phone,
                password=request.password,
                device_id=x_device_id,
                device_type=x_device_type,
                ip_address=ip_address,
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Code OTP ou mot de passe requis",
            )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.access_token_expire_minutes * 60,
        ),
    )


# =============================================================================
# Token Management
# =============================================================================

@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Rafraîchir les tokens",
    description="Obtient de nouveaux tokens en utilisant le refresh token.",
)
async def refresh_tokens(
    request: RefreshTokenRequest,
    auth_service: AuthServiceDep,
) -> TokenResponse:
    """Refresh access token."""
    try:
        access_token, refresh_token = await auth_service.refresh_tokens(
            refresh_token=request.refresh_token,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post(
    "/logout",
    response_model=MessageResponse,
    summary="Déconnexion",
    description="Déconnecte l'utilisateur et invalide les tokens.",
)
async def logout(
    auth_service: AuthServiceDep,
    authorization: Annotated[str, Header()],
    refresh_token: str | None = None,
) -> MessageResponse:
    """Logout user."""
    # Extract access token from header
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    access_token = authorization[7:]

    await auth_service.logout(
        access_token=access_token,
        refresh_token=refresh_token,
    )

    return MessageResponse(message="Déconnexion réussie")


# =============================================================================
# PIN Management
# =============================================================================

@router.post(
    "/pin",
    response_model=MessageResponse,
    summary="Définir le PIN",
    description="Définit ou modifie le code PIN de l'utilisateur.",
)
async def set_pin(
    request: SetPINRequest,
    auth_service: AuthServiceDep,
    authorization: Annotated[str, Header()],
) -> MessageResponse:
    """Set user PIN."""
    from app.modules.auth.dependencies import get_current_user_id

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    access_token = authorization[7:]
    user_id = await get_current_user_id(access_token, auth_service.redis)

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    try:
        await auth_service.set_pin(user_id, request.pin)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    return MessageResponse(message="PIN défini avec succès")


@router.post(
    "/verify-pin",
    response_model=MessageResponse,
    summary="Vérifier le PIN",
    description="Vérifie le code PIN de l'utilisateur.",
)
async def verify_pin(
    request: VerifyPINRequest,
    auth_service: AuthServiceDep,
    authorization: Annotated[str, Header()],
) -> MessageResponse:
    """Verify user PIN."""
    from app.modules.auth.dependencies import get_current_user_id

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    access_token = authorization[7:]
    user_id = await get_current_user_id(access_token, auth_service.redis)

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    valid = await auth_service.verify_pin(user_id, request.pin)

    if not valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="PIN incorrect",
        )

    return MessageResponse(message="PIN vérifié")
