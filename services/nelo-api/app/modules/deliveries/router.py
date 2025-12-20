"""Deliveries module API routes - Drivers and Deliveries."""

from typing import Annotated, Optional
from uuid import UUID

import redis.asyncio as redis
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.redis import get_redis
from app.modules.auth.dependencies import CurrentUser, require_role
from app.modules.deliveries.schemas import (
    DeliveryConfirmation,
    DeliveryListResponse,
    DeliveryOfferAction,
    DeliveryOfferResponse,
    DeliveryResponse,
    DeliveryStatusUpdate,
    DeliverySummary,
    DeliveryTrackingResponse,
    DriverAvailabilityCreate,
    DriverAvailabilityResponse,
    DriverDocumentCreate,
    DriverDocumentResponse,
    DriverEarningsResponse,
    DriverListResponse,
    DriverLocationUpdate,
    DriverRegister,
    DriverResponse,
    DriverStatusUpdate,
    DriverSummary,
    DriverUpdate,
    DriverVehicleUpdate,
)
from app.modules.deliveries.service import DeliveryService

router = APIRouter(tags=["Drivers & Deliveries"])


def get_delivery_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> DeliveryService:
    """Dependency to get delivery service."""
    return DeliveryService(db, redis_client)


DeliveryServiceDep = Annotated[DeliveryService, Depends(get_delivery_service)]


# =============================================================================
# Driver Registration & Profile
# =============================================================================


@router.post(
    "/drivers/register",
    response_model=DriverResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Inscription livreur",
    description="Inscrit un nouvel utilisateur comme livreur.",
)
async def register_driver(
    request: DriverRegister,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverResponse:
    """Register as a driver."""
    try:
        driver = await delivery_service.register_driver(
            user_id=current_user.id,
            first_name=request.first_name,
            last_name=request.last_name,
            phone=request.phone,
            email=request.email,
            city_id=request.city_id,
            zone_id=request.zone_id,
            vehicle_type=request.vehicle.type,
            vehicle_plate_number=request.vehicle.plate_number,
            vehicle_brand=request.vehicle.brand,
            vehicle_model=request.vehicle.model,
            vehicle_color=request.vehicle.color,
            vehicle_year=request.vehicle.year,
            id_number=request.id_number,
            license_number=request.license_number,
        )

        return DriverResponse.model_validate(driver)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "/drivers/me",
    response_model=DriverResponse,
    summary="Mon profil livreur",
    description="Retourne le profil du livreur connecte.",
)
async def get_my_driver_profile(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverResponse:
    """Get current driver profile."""
    driver = await delivery_service.get_driver_by_user_id(current_user.id)

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve. Veuillez vous inscrire.",
        )

    return DriverResponse.model_validate(driver)


@router.put(
    "/drivers/me",
    response_model=DriverResponse,
    summary="Modifier profil livreur",
    description="Modifie le profil du livreur connecte.",
)
async def update_my_driver_profile(
    request: DriverUpdate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverResponse:
    """Update driver profile."""
    driver = await delivery_service.update_driver(
        user_id=current_user.id,
        first_name=request.first_name,
        last_name=request.last_name,
        email=request.email,
        photo_url=request.photo_url,
        zone_id=request.zone_id,
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverResponse.model_validate(driver)


@router.put(
    "/drivers/me/vehicle",
    response_model=DriverResponse,
    summary="Modifier vehicule",
    description="Modifie les informations du vehicule.",
)
async def update_my_vehicle(
    request: DriverVehicleUpdate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverResponse:
    """Update driver vehicle."""
    driver = await delivery_service.update_driver_vehicle(
        user_id=current_user.id,
        vehicle_type=request.type,
        vehicle_plate_number=request.plate_number,
        vehicle_brand=request.brand,
        vehicle_model=request.model,
        vehicle_color=request.color,
        vehicle_year=request.year,
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverResponse.model_validate(driver)


# =============================================================================
# Driver Status & Location
# =============================================================================


@router.put(
    "/drivers/me/status",
    response_model=DriverResponse,
    summary="Changer statut",
    description="Passe le livreur en ligne ou hors ligne.",
)
async def update_driver_status(
    request: DriverStatusUpdate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverResponse:
    """Toggle driver online/offline status."""
    driver = await delivery_service.toggle_driver_online(
        user_id=current_user.id,
        is_online=request.is_online,
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverResponse.model_validate(driver)


@router.put(
    "/drivers/me/location",
    response_model=dict,
    summary="Mettre a jour position",
    description="Met a jour la position GPS du livreur.",
)
async def update_driver_location(
    request: DriverLocationUpdate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> dict:
    """Update driver GPS location."""
    success = await delivery_service.update_driver_location(
        user_id=current_user.id,
        latitude=float(request.latitude),
        longitude=float(request.longitude),
        heading=float(request.heading) if request.heading else None,
        speed=float(request.speed) if request.speed else None,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return {"status": "ok", "message": "Position mise a jour"}


# =============================================================================
# Driver Availability
# =============================================================================


@router.get(
    "/drivers/me/availability",
    response_model=list[DriverAvailabilityResponse],
    summary="Mes disponibilites",
    description="Retourne les horaires de disponibilite du livreur.",
)
async def get_my_availability(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> list[DriverAvailabilityResponse]:
    """Get driver availability schedules."""
    schedules = await delivery_service.get_driver_availability(current_user.id)
    return [DriverAvailabilityResponse.model_validate(s) for s in schedules]


@router.put(
    "/drivers/me/availability/{day_of_week}",
    response_model=DriverAvailabilityResponse,
    summary="Modifier disponibilite",
    description="Modifie la disponibilite pour un jour de la semaine.",
)
async def update_my_availability(
    day_of_week: int,
    request: DriverAvailabilityCreate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverAvailabilityResponse:
    """Update availability for a day."""
    if day_of_week < 0 or day_of_week > 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Jour invalide (0-6)",
        )

    schedule = await delivery_service.update_driver_availability(
        user_id=current_user.id,
        day_of_week=day_of_week,
        start_time=request.start_time,
        end_time=request.end_time,
        is_active=request.is_active,
    )

    if not schedule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverAvailabilityResponse.model_validate(schedule)


# =============================================================================
# Driver Documents
# =============================================================================


@router.get(
    "/drivers/me/documents",
    response_model=list[DriverDocumentResponse],
    summary="Mes documents",
    description="Retourne les documents KYC du livreur.",
)
async def get_my_documents(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> list[DriverDocumentResponse]:
    """Get driver documents."""
    documents = await delivery_service.get_driver_documents(current_user.id)
    return [DriverDocumentResponse.model_validate(d) for d in documents]


@router.post(
    "/drivers/me/documents",
    response_model=DriverDocumentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter document",
    description="Ajoute un document KYC.",
)
async def upload_document(
    request: DriverDocumentCreate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverDocumentResponse:
    """Upload a KYC document."""
    document = await delivery_service.add_driver_document(
        user_id=current_user.id,
        document_type=request.type,
        document_url=request.document_url,
        expiry_date=request.expiry_date,
    )

    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverDocumentResponse.model_validate(document)


# =============================================================================
# Driver Earnings
# =============================================================================


@router.get(
    "/drivers/me/earnings",
    response_model=DriverEarningsResponse,
    summary="Mes gains",
    description="Retourne le resume des gains du livreur.",
)
async def get_my_earnings(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DriverEarningsResponse:
    """Get driver earnings summary."""
    earnings = await delivery_service.get_driver_earnings(current_user.id)

    if not earnings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil livreur non trouve",
        )

    return DriverEarningsResponse(**earnings)


# =============================================================================
# Delivery Offers
# =============================================================================


@router.get(
    "/drivers/me/offers",
    response_model=list[DeliveryOfferResponse],
    summary="Courses disponibles",
    description="Retourne les offres de courses en attente.",
)
async def get_available_offers(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> list[DeliveryOfferResponse]:
    """Get available delivery offers for driver."""
    offers = await delivery_service.get_pending_offers(current_user.id)
    return [DeliveryOfferResponse.model_validate(o) for o in offers]


@router.post(
    "/drivers/me/offers/{offer_id}/accept",
    response_model=DeliveryResponse,
    summary="Accepter course",
    description="Accepte une offre de course.",
)
async def accept_offer(
    offer_id: UUID,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DeliveryResponse:
    """Accept a delivery offer."""
    try:
        delivery = await delivery_service.accept_offer(
            offer_id=offer_id,
            user_id=current_user.id,
        )

        return DeliveryResponse.model_validate(delivery)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post(
    "/drivers/me/offers/{offer_id}/reject",
    response_model=dict,
    summary="Refuser course",
    description="Refuse une offre de course.",
)
async def reject_offer(
    offer_id: UUID,
    request: DeliveryOfferAction,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> dict:
    """Reject a delivery offer."""
    try:
        await delivery_service.reject_offer(
            offer_id=offer_id,
            user_id=current_user.id,
            reason=request.reason,
        )

        return {"status": "ok", "message": "Offre refusee"}

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =============================================================================
# Driver Deliveries
# =============================================================================


@router.get(
    "/drivers/me/deliveries",
    response_model=DeliveryListResponse,
    summary="Mes livraisons",
    description="Retourne l'historique des livraisons du livreur.",
)
async def get_my_deliveries(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
    delivery_status: Optional[str] = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> DeliveryListResponse:
    """Get driver's delivery history."""
    deliveries, total = await delivery_service.get_driver_deliveries(
        user_id=current_user.id,
        status=delivery_status,
        page=page,
        page_size=page_size,
    )

    return DeliveryListResponse(
        deliveries=[DeliverySummary.model_validate(d) for d in deliveries],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


@router.get(
    "/drivers/me/deliveries/current",
    response_model=Optional[DeliveryResponse],
    summary="Livraison en cours",
    description="Retourne la livraison en cours du livreur.",
)
async def get_current_delivery(
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> Optional[DeliveryResponse]:
    """Get current active delivery."""
    delivery = await delivery_service.get_active_delivery(current_user.id)

    if not delivery:
        return None

    return DeliveryResponse.model_validate(delivery)


# =============================================================================
# Delivery Operations
# =============================================================================


@router.put(
    "/deliveries/{delivery_id}/status",
    response_model=DeliveryResponse,
    summary="Changer statut livraison",
    description="Change le statut d'une livraison.",
)
async def update_delivery_status(
    delivery_id: UUID,
    request: DeliveryStatusUpdate,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DeliveryResponse:
    """Update delivery status."""
    try:
        delivery = await delivery_service.update_delivery_status(
            delivery_id=delivery_id,
            user_id=current_user.id,
            new_status=request.status,
            notes=request.notes,
            latitude=float(request.latitude) if request.latitude else None,
            longitude=float(request.longitude) if request.longitude else None,
        )

        return DeliveryResponse.model_validate(delivery)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post(
    "/deliveries/{delivery_id}/confirm",
    response_model=DeliveryResponse,
    summary="Confirmer livraison",
    description="Confirme la livraison avec le code de confirmation.",
)
async def confirm_delivery(
    delivery_id: UUID,
    request: DeliveryConfirmation,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DeliveryResponse:
    """Confirm delivery with code."""
    try:
        delivery = await delivery_service.confirm_delivery(
            delivery_id=delivery_id,
            user_id=current_user.id,
            confirmation_code=request.confirmation_code,
            signature_url=request.signature_url,
            photo_url=request.photo_url,
        )

        return DeliveryResponse.model_validate(delivery)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "/deliveries/{delivery_id}/tracking",
    response_model=DeliveryTrackingResponse,
    summary="Suivi livraison",
    description="Retourne les informations de suivi d'une livraison.",
)
async def track_delivery(
    delivery_id: UUID,
    current_user: CurrentUser,
    delivery_service: DeliveryServiceDep,
) -> DeliveryTrackingResponse:
    """Get delivery tracking information."""
    tracking = await delivery_service.get_delivery_tracking(delivery_id)

    if not tracking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Livraison non trouvee",
        )

    return DeliveryTrackingResponse(**tracking)


# =============================================================================
# Admin: Driver Management
# =============================================================================


@router.get(
    "/admin/drivers",
    response_model=DriverListResponse,
    summary="Liste des livreurs",
    description="Liste tous les livreurs (admin uniquement).",
)
async def list_drivers(
    current_user: Annotated[CurrentUser, Depends(require_role("admin"))],
    delivery_service: DeliveryServiceDep,
    driver_status: Optional[str] = Query(None, alias="status"),
    city_id: Optional[UUID] = Query(None),
    is_online: Optional[bool] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> DriverListResponse:
    """List all drivers (admin only)."""
    drivers, total = await delivery_service.list_drivers(
        status=driver_status,
        city_id=city_id,
        is_online=is_online,
        page=page,
        page_size=page_size,
    )

    return DriverListResponse(
        drivers=[DriverSummary.model_validate(d) for d in drivers],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


@router.put(
    "/admin/drivers/{driver_id}/status",
    response_model=DriverResponse,
    summary="Changer statut livreur",
    description="Change le statut d'un livreur (admin uniquement).",
)
async def update_driver_admin_status(
    driver_id: UUID,
    new_status: str = Query(..., pattern="^(pending|active|suspended|deactivated)$"),
    current_user: Annotated[CurrentUser, Depends(require_role("admin"))] = None,
    delivery_service: DeliveryServiceDep = None,
) -> DriverResponse:
    """Update driver status (admin only)."""
    driver = await delivery_service.update_driver_status(driver_id, new_status)

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Livreur non trouve",
        )

    return DriverResponse.model_validate(driver)


@router.put(
    "/admin/drivers/{driver_id}/documents/{document_id}/verify",
    response_model=DriverDocumentResponse,
    summary="Verifier document",
    description="Verifie un document KYC (admin uniquement).",
)
async def verify_document(
    driver_id: UUID,
    document_id: UUID,
    approved: bool = Query(...),
    rejection_reason: Optional[str] = Query(None),
    current_user: Annotated[CurrentUser, Depends(require_role("admin"))] = None,
    delivery_service: DeliveryServiceDep = None,
) -> DriverDocumentResponse:
    """Verify driver document (admin only)."""
    document = await delivery_service.verify_document(
        driver_id=driver_id,
        document_id=document_id,
        approved=approved,
        rejection_reason=rejection_reason,
        verified_by_id=current_user.id,
    )

    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document non trouve",
        )

    return DriverDocumentResponse.model_validate(document)
