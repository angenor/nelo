"""Users module API routes."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.modules.auth.dependencies import CurrentUser
from app.modules.users.schemas import (
    AddressCreate,
    AddressListResponse,
    AddressResponse,
    AddressUpdate,
    ProfileResponse,
    ProfileUpdate,
)
from app.modules.users.service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


def get_user_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> UserService:
    """Dependency to get user service."""
    return UserService(db)


UserServiceDep = Annotated[UserService, Depends(get_user_service)]


# =============================================================================
# Profile Endpoints
# =============================================================================

@router.get(
    "/me",
    response_model=ProfileResponse,
    summary="Profil courant",
    description="Récupère le profil de l'utilisateur connecté.",
)
async def get_my_profile(
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> ProfileResponse:
    """Get current user's profile."""
    profile = await user_service.get_profile(current_user.id)

    if not profile:
        # Create profile if it doesn't exist
        profile = await user_service.create_profile(
            user_id=current_user.id,
            phone=current_user.phone,
            email=current_user.email,
        )

    return ProfileResponse.model_validate(profile)


@router.put(
    "/me",
    response_model=ProfileResponse,
    summary="Modifier profil",
    description="Modifie le profil de l'utilisateur connecté.",
)
async def update_my_profile(
    request: ProfileUpdate,
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> ProfileResponse:
    """Update current user's profile."""
    # Ensure profile exists
    profile = await user_service.get_profile(current_user.id)
    if not profile:
        profile = await user_service.create_profile(
            user_id=current_user.id,
            phone=current_user.phone,
            email=current_user.email,
        )

    # Update profile
    profile = await user_service.update_profile(
        user_id=current_user.id,
        first_name=request.first_name,
        last_name=request.last_name,
        display_name=request.display_name,
        email=request.email,
        preferred_language=request.preferred_language,
        default_city_id=request.default_city_id,
        default_zone_id=request.default_zone_id,
        notification_settings=request.notification_settings,
    )

    return ProfileResponse.model_validate(profile)


# =============================================================================
# Address Endpoints
# =============================================================================

@router.get(
    "/me/addresses",
    response_model=AddressListResponse,
    summary="Lister adresses",
    description="Liste toutes les adresses de l'utilisateur connecté.",
)
async def get_my_addresses(
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> AddressListResponse:
    """Get all addresses for current user."""
    addresses = await user_service.get_addresses(current_user.id)
    return AddressListResponse(
        addresses=[AddressResponse.model_validate(a) for a in addresses],
        total=len(addresses),
    )


@router.post(
    "/me/addresses",
    response_model=AddressResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter adresse",
    description="Ajoute une nouvelle adresse pour l'utilisateur connecté.",
)
async def create_address(
    request: AddressCreate,
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> AddressResponse:
    """Create a new address."""
    # Ensure profile exists
    profile = await user_service.get_profile(current_user.id)
    if not profile:
        await user_service.create_profile(
            user_id=current_user.id,
            phone=current_user.phone,
            email=current_user.email,
        )

    address = await user_service.create_address(
        user_id=current_user.id,
        label=request.label,
        name=request.name,
        address_line1=request.address_line1,
        address_line2=request.address_line2,
        landmark=request.landmark,
        city_id=request.city_id,
        zone_id=request.zone_id,
        latitude=float(request.latitude),
        longitude=float(request.longitude),
        contact_phone=request.contact_phone,
        is_default=request.is_default,
    )

    return AddressResponse.model_validate(address)


@router.get(
    "/me/addresses/{address_id}",
    response_model=AddressResponse,
    summary="Détail adresse",
    description="Récupère une adresse spécifique.",
)
async def get_address(
    address_id: UUID,
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> AddressResponse:
    """Get a specific address."""
    address = await user_service.get_address(current_user.id, address_id)
    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Adresse non trouvée",
        )
    return AddressResponse.model_validate(address)


@router.put(
    "/me/addresses/{address_id}",
    response_model=AddressResponse,
    summary="Modifier adresse",
    description="Modifie une adresse existante.",
)
async def update_address(
    address_id: UUID,
    request: AddressUpdate,
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> AddressResponse:
    """Update an address."""
    address = await user_service.update_address(
        user_id=current_user.id,
        address_id=address_id,
        label=request.label,
        name=request.name,
        address_line1=request.address_line1,
        address_line2=request.address_line2,
        landmark=request.landmark,
        city_id=request.city_id,
        zone_id=request.zone_id,
        latitude=float(request.latitude) if request.latitude else None,
        longitude=float(request.longitude) if request.longitude else None,
        contact_phone=request.contact_phone,
        is_default=request.is_default,
    )

    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Adresse non trouvée",
        )

    return AddressResponse.model_validate(address)


@router.delete(
    "/me/addresses/{address_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Supprimer adresse",
    description="Supprime une adresse.",
)
async def delete_address(
    address_id: UUID,
    current_user: CurrentUser,
    user_service: UserServiceDep,
) -> None:
    """Delete an address."""
    success = await user_service.delete_address(current_user.id, address_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Adresse non trouvée",
        )
