"""Providers API routes."""

from decimal import Decimal
from typing import Annotated, Optional
from uuid import UUID

import redis.asyncio as redis
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.redis import get_redis
from app.modules.auth.dependencies import CurrentUser, require_role
from app.modules.orders.schemas import (
    CityResponse,
    NearbyProviderRequest,
    ProviderCreate,
    ProviderListResponse,
    ProviderMenuResponse,
    ProviderResponse,
    ProviderScheduleCreate,
    ProviderScheduleResponse,
    ProviderSummary,
    ProviderUpdate,
    ZoneResponse,
)
from app.modules.orders.services.provider_service import ProviderService

router = APIRouter(prefix="/providers", tags=["Providers"])


def get_provider_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> ProviderService:
    """Dependency to get provider service."""
    return ProviderService(db, redis_client)


ProviderServiceDep = Annotated[ProviderService, Depends(get_provider_service)]


# =============================================================================
# Geographic Endpoints
# =============================================================================


@router.get(
    "/cities",
    response_model=list[CityResponse],
    summary="Liste des villes",
    description="Retourne la liste des villes disponibles.",
)
async def list_cities(
    provider_service: ProviderServiceDep,
    is_active_only: bool = Query(True, description="Filtrer les villes actives"),
) -> list[CityResponse]:
    """Get all available cities."""
    cities = await provider_service.get_cities(is_active_only)
    return [CityResponse.model_validate(city) for city in cities]


@router.get(
    "/cities/{city_id}",
    response_model=CityResponse,
    summary="Detail ville",
    description="Retourne les details d'une ville.",
)
async def get_city(
    city_id: UUID,
    provider_service: ProviderServiceDep,
) -> CityResponse:
    """Get city details."""
    city = await provider_service.get_city(city_id)
    if not city:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ville non trouvee",
        )
    return CityResponse.model_validate(city)


@router.get(
    "/cities/{city_id}/zones",
    response_model=list[ZoneResponse],
    summary="Zones d'une ville",
    description="Retourne les zones de livraison d'une ville.",
)
async def list_zones(
    city_id: UUID,
    provider_service: ProviderServiceDep,
    is_active_only: bool = Query(True, description="Filtrer les zones actives"),
) -> list[ZoneResponse]:
    """Get zones for a city."""
    zones = await provider_service.get_zones(city_id, is_active_only)
    return [ZoneResponse.model_validate(zone) for zone in zones]


# =============================================================================
# Provider List & Search Endpoints
# =============================================================================


@router.get(
    "",
    response_model=ProviderListResponse,
    summary="Liste des prestataires",
    description="Liste les prestataires avec filtres et pagination.",
)
async def list_providers(
    provider_service: ProviderServiceDep,
    city_id: UUID = Query(..., description="ID de la ville"),
    provider_type: Optional[str] = Query(None, description="Type de prestataire"),
    is_open_only: bool = Query(False, description="Seulement les prestataires ouverts"),
    is_featured_only: bool = Query(False, description="Seulement les prestataires en vedette"),
    search: Optional[str] = Query(None, description="Recherche par nom"),
    page: int = Query(1, ge=1, description="Numero de page"),
    page_size: int = Query(20, ge=1, le=100, description="Taille de la page"),
) -> ProviderListResponse:
    """List providers with filters and pagination."""
    providers, total = await provider_service.list_providers(
        city_id=city_id,
        provider_type=provider_type,
        is_open_only=is_open_only,
        is_featured_only=is_featured_only,
        search=search,
        page=page,
        page_size=page_size,
    )

    return ProviderListResponse(
        providers=[
            ProviderSummary(
                id=p.id,
                name=p.name,
                slug=p.slug,
                type=p.type,
                logo_url=p.logo_url,
                cover_image_url=p.cover_image_url,
                address_line1=p.address_line1,
                average_rating=p.average_rating,
                rating_count=p.rating_count,
                min_order_amount=p.min_order_amount,
                average_prep_time=p.average_prep_time,
                is_open=p.is_open,
                is_featured=p.is_featured,
            )
            for p in providers
        ],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


@router.post(
    "/nearby",
    response_model=list[ProviderSummary],
    summary="Prestataires a proximite",
    description="Trouve les prestataires dans un rayon donne avec recherche geospatiale.",
)
async def find_nearby_providers(
    request: NearbyProviderRequest,
    provider_service: ProviderServiceDep,
) -> list[ProviderSummary]:
    """Find providers within radius using geospatial search."""
    results = await provider_service.find_nearby_providers(
        latitude=request.latitude,
        longitude=request.longitude,
        radius_km=request.radius_km,
        provider_type=request.provider_type,
        is_open_only=request.is_open_only,
    )

    return [
        ProviderSummary(
            id=r["provider"].id,
            name=r["provider"].name,
            slug=r["provider"].slug,
            type=r["provider"].type,
            logo_url=r["provider"].logo_url,
            cover_image_url=r["provider"].cover_image_url,
            address_line1=r["provider"].address_line1,
            average_rating=r["provider"].average_rating,
            rating_count=r["provider"].rating_count,
            min_order_amount=r["provider"].min_order_amount,
            average_prep_time=r["provider"].average_prep_time,
            is_open=r["provider"].is_open,
            is_featured=r["provider"].is_featured,
            distance_km=r["distance_km"],
        )
        for r in results
    ]


# =============================================================================
# Provider Detail Endpoints
# =============================================================================


@router.get(
    "/{provider_id}",
    response_model=ProviderResponse,
    summary="Detail prestataire",
    description="Retourne les details complets d'un prestataire.",
)
async def get_provider(
    provider_id: UUID,
    provider_service: ProviderServiceDep,
) -> ProviderResponse:
    """Get provider details."""
    provider = await provider_service.get_provider(provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve",
        )
    return ProviderResponse.model_validate(provider)


@router.get(
    "/{provider_id}/menu",
    response_model=ProviderMenuResponse,
    summary="Menu du prestataire",
    description="Retourne le menu complet avec categories et produits.",
)
async def get_provider_menu(
    provider_id: UUID,
    provider_service: ProviderServiceDep,
) -> ProviderMenuResponse:
    """Get provider's full menu."""
    menu = await provider_service.get_provider_menu(provider_id)
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve",
        )
    return ProviderMenuResponse(**menu)


@router.get(
    "/{provider_id}/schedules",
    response_model=list[ProviderScheduleResponse],
    summary="Horaires du prestataire",
    description="Retourne les horaires d'ouverture du prestataire.",
)
async def get_provider_schedules(
    provider_id: UUID,
    provider_service: ProviderServiceDep,
) -> list[ProviderScheduleResponse]:
    """Get provider schedules."""
    provider = await provider_service.get_provider(provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve",
        )
    schedules = await provider_service.get_schedules(provider_id)
    return [ProviderScheduleResponse.model_validate(s) for s in schedules]


# =============================================================================
# Provider Management Endpoints (Authenticated)
# =============================================================================


@router.post(
    "",
    response_model=ProviderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Creer un prestataire",
    description="Cree un nouveau prestataire (necessite authentification).",
)
async def create_provider(
    request: ProviderCreate,
    current_user: CurrentUser,
    provider_service: ProviderServiceDep,
) -> ProviderResponse:
    """Create a new provider."""
    # Convert schedules to dict format
    schedules_data = None
    if request.schedules:
        schedules_data = [
            {
                "day_of_week": s.day_of_week,
                "open_time": s.open_time,
                "close_time": s.close_time,
                "is_closed": s.is_closed,
            }
            for s in request.schedules
        ]

    provider = await provider_service.create_provider(
        user_id=current_user.id,
        name=request.name,
        description=request.description,
        provider_type=request.type,
        phone=request.phone,
        email=request.email,
        whatsapp=request.whatsapp,
        address_line1=request.address_line1,
        landmark=request.landmark,
        city_id=request.city_id,
        zone_id=request.zone_id,
        latitude=request.latitude,
        longitude=request.longitude,
        logo_url=request.logo_url,
        cover_image_url=request.cover_image_url,
        min_order_amount=request.min_order_amount,
        average_prep_time=request.average_prep_time,
        delivery_radius_km=request.delivery_radius_km,
        schedules=schedules_data,
    )

    return ProviderResponse.model_validate(provider)


@router.put(
    "/{provider_id}",
    response_model=ProviderResponse,
    summary="Modifier un prestataire",
    description="Modifie les informations d'un prestataire (proprietaire uniquement).",
)
async def update_provider(
    provider_id: UUID,
    request: ProviderUpdate,
    current_user: CurrentUser,
    provider_service: ProviderServiceDep,
) -> ProviderResponse:
    """Update provider (owner only)."""
    provider = await provider_service.update_provider(
        provider_id=provider_id,
        user_id=current_user.id,
        name=request.name,
        description=request.description,
        phone=request.phone,
        email=request.email,
        whatsapp=request.whatsapp,
        address_line1=request.address_line1,
        landmark=request.landmark,
        zone_id=request.zone_id,
        latitude=float(request.latitude) if request.latitude else None,
        longitude=float(request.longitude) if request.longitude else None,
        logo_url=request.logo_url,
        cover_image_url=request.cover_image_url,
        min_order_amount=request.min_order_amount,
        average_prep_time=request.average_prep_time,
        delivery_radius_km=float(request.delivery_radius_km) if request.delivery_radius_km else None,
        is_open=request.is_open,
        is_featured=request.is_featured,
    )

    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve ou non autorise",
        )

    return ProviderResponse.model_validate(provider)


@router.put(
    "/{provider_id}/status",
    response_model=ProviderResponse,
    summary="Changer statut prestataire",
    description="Change le statut d'un prestataire (admin uniquement).",
)
async def update_provider_status(
    provider_id: UUID,
    new_status: str = Query(..., pattern="^(pending|active|suspended|closed)$"),
    current_user: Annotated[CurrentUser, Depends(require_role("admin"))],
    provider_service: ProviderServiceDep,
) -> ProviderResponse:
    """Update provider status (admin only)."""
    provider = await provider_service.update_provider_status(provider_id, new_status)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve",
        )
    return ProviderResponse.model_validate(provider)


@router.put(
    "/{provider_id}/toggle-open",
    response_model=ProviderResponse,
    summary="Ouvrir/Fermer prestataire",
    description="Bascule l'etat ouvert/ferme du prestataire (proprietaire uniquement).",
)
async def toggle_provider_open(
    provider_id: UUID,
    is_open: bool = Query(..., description="Etat ouvert ou ferme"),
    current_user: CurrentUser,
    provider_service: ProviderServiceDep,
) -> ProviderResponse:
    """Toggle provider open/closed status."""
    provider = await provider_service.toggle_provider_open(
        provider_id, current_user.id, is_open
    )
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve ou non autorise",
        )
    return ProviderResponse.model_validate(provider)


@router.put(
    "/{provider_id}/schedules/{day_of_week}",
    response_model=ProviderScheduleResponse,
    summary="Modifier horaire",
    description="Modifie l'horaire d'un jour de la semaine.",
)
async def update_provider_schedule(
    provider_id: UUID,
    day_of_week: int,
    request: ProviderScheduleCreate,
    current_user: CurrentUser,
    provider_service: ProviderServiceDep,
) -> ProviderScheduleResponse:
    """Update schedule for a specific day."""
    # Verify ownership
    provider = await provider_service.get_provider(provider_id)
    if not provider or provider.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve ou non autorise",
        )

    schedule = await provider_service.update_schedule(
        provider_id=provider_id,
        day_of_week=day_of_week,
        open_time=request.open_time,
        close_time=request.close_time,
        is_closed=request.is_closed,
    )

    return ProviderScheduleResponse.model_validate(schedule)
