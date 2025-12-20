"""Orders API routes."""

from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.modules.auth.dependencies import CurrentUser
from app.modules.orders.schemas import (
    OrderCreate,
    OrderListResponse,
    OrderRatingCreate,
    OrderRatingResponse,
    OrderResponse,
    OrderStatusUpdate,
    OrderSummary,
    OrderTrackingResponse,
)
from app.modules.orders.service import OrderService

router = APIRouter(prefix="/orders", tags=["Orders"])


def get_order_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> OrderService:
    """Dependency to get order service."""
    return OrderService(db)


OrderServiceDep = Annotated[OrderService, Depends(get_order_service)]


# =============================================================================
# Order Creation & List
# =============================================================================


@router.post(
    "",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Creer une commande",
    description="Cree une nouvelle commande avec les articles du panier.",
)
async def create_order(
    request: OrderCreate,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
) -> OrderResponse:
    """Create a new order."""
    try:
        # Build items list
        items = [
            {
                "product_id": str(item.product_id),
                "quantity": item.quantity,
                "unit_price": item.unit_price,
                "special_instructions": item.special_instructions,
                "options": [
                    {
                        "option_id": str(opt.option_id),
                        "option_item_id": str(opt.option_item_id),
                        "name": opt.name,
                        "value": opt.value,
                        "price_adjustment": opt.price_adjustment,
                    }
                    for opt in item.options
                ],
            }
            for item in request.items
        ]

        # Build delivery address
        delivery_address = request.delivery_address_snapshot or {}

        order = await order_service.create_order(
            user_id=current_user.id,
            provider_id=request.provider_id,
            items=items,
            delivery_address=delivery_address,
            payment_method=request.payment_method,
            special_instructions=request.special_instructions,
            promotion_code=request.promo_code,
            is_scheduled=request.scheduled_for is not None,
            scheduled_for=request.scheduled_for,
        )

        return await _build_order_response(order, order_service)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "",
    response_model=OrderListResponse,
    summary="Mes commandes",
    description="Liste les commandes de l'utilisateur connecte.",
)
async def list_orders(
    current_user: CurrentUser,
    order_service: OrderServiceDep,
    order_status: Optional[str] = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> OrderListResponse:
    """List user's orders."""
    orders, total = await order_service.get_user_orders(
        user_id=current_user.id,
        status=order_status,
        page=page,
        page_size=page_size,
    )

    return OrderListResponse(
        orders=[
            OrderSummary(
                id=o.id,
                reference=o.reference,
                provider_id=o.provider_id,
                provider_name=o.provider_name or "Prestataire",
                provider_logo_url=o.provider_logo_url,
                status=o.status.value if hasattr(o.status, "value") else o.status,
                subtotal=o.subtotal,
                delivery_fee=o.delivery_fee,
                total_amount=o.total_amount,
                item_count=len(o.items) if o.items else 0,
                created_at=o.created_at,
                estimated_delivery_time=o.estimated_delivery_time,
            )
            for o in orders
        ],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


# =============================================================================
# Order Detail & Status
# =============================================================================


@router.get(
    "/{order_id}",
    response_model=OrderResponse,
    summary="Detail commande",
    description="Retourne les details complets d'une commande.",
)
async def get_order(
    order_id: UUID,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
) -> OrderResponse:
    """Get order details."""
    order = await order_service.get_order(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commande non trouvee",
        )

    # Check ownership
    if order.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acces non autorise",
        )

    return await _build_order_response(order, order_service)


@router.get(
    "/{order_id}/tracking",
    response_model=OrderTrackingResponse,
    summary="Suivi commande",
    description="Retourne les informations de suivi d'une commande.",
)
async def track_order(
    order_id: UUID,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
) -> OrderTrackingResponse:
    """Get order tracking information."""
    tracking = await order_service.get_order_tracking(order_id)

    if not tracking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commande non trouvee",
        )

    # Verify ownership
    order = await order_service.get_order(order_id)
    if order and order.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acces non autorise",
        )

    return OrderTrackingResponse(**tracking)


@router.put(
    "/{order_id}/status",
    response_model=OrderResponse,
    summary="Changer statut commande",
    description="Change le statut d'une commande (prestataire/admin).",
)
async def update_order_status(
    order_id: UUID,
    request: OrderStatusUpdate,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
) -> OrderResponse:
    """Update order status."""
    order = await order_service.get_order(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commande non trouvee",
        )

    # Check authorization (provider owner, driver, or admin)
    # TODO: Add proper authorization check

    try:
        updated_order = await order_service.update_order_status(
            order_id=order_id,
            new_status=request.status,
            changed_by_id=current_user.id,
            notes=request.notes,
            cancellation_reason=request.cancellation_reason,
        )

        return await _build_order_response(updated_order, order_service)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post(
    "/{order_id}/cancel",
    response_model=OrderResponse,
    summary="Annuler commande",
    description="Annule une commande (si possible).",
)
async def cancel_order(
    order_id: UUID,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
    reason: Optional[str] = Query(None, max_length=500),
) -> OrderResponse:
    """Cancel an order."""
    order = await order_service.get_order(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commande non trouvee",
        )

    # Check ownership
    if order.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acces non autorise",
        )

    try:
        cancelled_order = await order_service.update_order_status(
            order_id=order_id,
            new_status="cancelled",
            changed_by_id=current_user.id,
            cancellation_reason=reason or "Annulee par le client",
        )

        return await _build_order_response(cancelled_order, order_service)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =============================================================================
# Order Rating
# =============================================================================


@router.post(
    "/{order_id}/rating",
    response_model=OrderRatingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Noter une commande",
    description="Ajoute une note a une commande livree.",
)
async def rate_order(
    order_id: UUID,
    request: OrderRatingCreate,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
) -> OrderRatingResponse:
    """Rate an order."""
    order = await order_service.get_order(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Commande non trouvee",
        )

    # Check ownership
    if order.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acces non autorise",
        )

    # Check if order is delivered
    status_value = order.status.value if hasattr(order.status, "value") else order.status
    if status_value != "delivered":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Seules les commandes livrees peuvent etre notees",
        )

    try:
        rating = await order_service.rate_order(
            order_id=order_id,
            user_id=current_user.id,
            overall_rating=request.overall_rating,
            food_rating=request.food_rating,
            delivery_rating=request.delivery_rating,
            comment=request.comment,
        )

        return OrderRatingResponse.model_validate(rating)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =============================================================================
# Provider Orders (for provider dashboard)
# =============================================================================


@router.get(
    "/provider/{provider_id}",
    response_model=OrderListResponse,
    summary="Commandes du prestataire",
    description="Liste les commandes d'un prestataire (proprietaire uniquement).",
)
async def list_provider_orders(
    provider_id: UUID,
    current_user: CurrentUser,
    order_service: OrderServiceDep,
    order_status: Optional[str] = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
) -> OrderListResponse:
    """List orders for a provider."""
    # TODO: Verify provider ownership

    orders, total = await order_service.get_provider_orders(
        provider_id=provider_id,
        status=order_status,
        page=page,
        page_size=page_size,
    )

    return OrderListResponse(
        orders=[
            OrderSummary(
                id=o.id,
                reference=o.reference,
                provider_id=o.provider_id,
                provider_name=o.provider_name or "Prestataire",
                provider_logo_url=o.provider_logo_url,
                status=o.status.value if hasattr(o.status, "value") else o.status,
                subtotal=o.subtotal,
                delivery_fee=o.delivery_fee,
                total_amount=o.total_amount,
                item_count=len(o.items) if o.items else 0,
                created_at=o.created_at,
                estimated_delivery_time=o.estimated_delivery_time,
            )
            for o in orders
        ],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    )


# =============================================================================
# Helper Functions
# =============================================================================


async def _build_order_response(
    order, order_service: OrderService
) -> OrderResponse:
    """Build OrderResponse from order model."""
    from app.modules.orders.schemas import (
        OrderItemOptionResponse,
        OrderItemResponse,
        OrderStatusHistoryResponse,
    )

    # Get status history
    status_history = await order_service.get_order_status_history(order.id)

    return OrderResponse(
        id=order.id,
        reference=order.reference,
        user_id=order.user_id,
        provider_id=order.provider_id,
        provider_name=order.provider_name or "Prestataire",
        provider_phone=order.provider_phone,
        provider_logo_url=order.provider_logo_url,
        status=order.status.value if hasattr(order.status, "value") else order.status,
        payment_status=order.payment_status,
        payment_method=order.payment_method,
        subtotal=order.subtotal,
        delivery_fee=order.delivery_fee,
        service_fee=order.service_fee,
        discount_amount=order.discount_amount,
        total_amount=order.total_amount,
        promo_code=order.promo_code,
        special_instructions=order.special_instructions,
        delivery_address_snapshot=order.delivery_address_snapshot,
        scheduled_for=order.scheduled_for,
        estimated_delivery_time=order.estimated_delivery_time,
        confirmed_at=order.confirmed_at,
        preparing_at=order.preparing_at,
        ready_at=order.ready_at,
        picked_up_at=order.picked_up_at,
        delivered_at=order.delivered_at,
        cancelled_at=order.cancelled_at,
        cancellation_reason=order.cancellation_reason,
        created_at=order.created_at,
        updated_at=order.updated_at,
        items=[
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                product_name=item.product_name,
                product_image_url=item.product_image_url,
                quantity=item.quantity,
                unit_price=item.unit_price,
                total_price=item.total_price,
                special_instructions=item.special_instructions,
                options=[
                    OrderItemOptionResponse(
                        option_id=opt.get("option_id"),
                        option_item_id=opt.get("option_item_id"),
                        name=opt.get("name", ""),
                        value=opt.get("value", ""),
                        price_adjustment=opt.get("price_adjustment", 0),
                    )
                    for opt in (item.options_snapshot or [])
                ],
            )
            for item in (order.items or [])
        ],
        status_history=[
            OrderStatusHistoryResponse(
                status=h.get("status", ""),
                notes=h.get("notes"),
                changed_by_id=h.get("changed_by_id"),
                created_at=h.get("created_at"),
            )
            for h in status_history
        ],
    )
