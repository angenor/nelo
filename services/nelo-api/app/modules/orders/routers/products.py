"""Products API routes (nested under providers)."""

from typing import Annotated, Optional
from uuid import UUID

import redis.asyncio as redis
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.redis import get_redis
from app.modules.auth.dependencies import CurrentUser
from app.modules.orders.schemas import (
    GasProductCreate,
    GasProductListResponse,
    GasProductResponse,
    GasProductUpdate,
    ProductCategoryCreate,
    ProductCategoryResponse,
    ProductCategoryUpdate,
    ProductCreate,
    ProductListResponse,
    ProductOptionCreate,
    ProductOptionResponse,
    ProductResponse,
    ProductUpdate,
)
from app.modules.orders.services.product_service import ProductService
from app.modules.orders.services.provider_service import ProviderService

router = APIRouter(prefix="/providers/{provider_id}", tags=["Products"])


def get_product_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> ProductService:
    """Dependency to get product service."""
    return ProductService(db, redis_client)


def get_provider_service(
    db: Annotated[AsyncSession, Depends(get_db_session)],
    redis_client: Annotated[redis.Redis, Depends(get_redis)],
) -> ProviderService:
    """Dependency to get provider service."""
    return ProviderService(db, redis_client)


ProductServiceDep = Annotated[ProductService, Depends(get_product_service)]
ProviderServiceDep = Annotated[ProviderService, Depends(get_provider_service)]


async def verify_provider_ownership(
    provider_id: UUID,
    current_user: CurrentUser,
    provider_service: ProviderServiceDep,
) -> None:
    """Verify that current user owns the provider."""
    provider = await provider_service.get_provider(provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prestataire non trouve",
        )
    if provider.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Non autorise a modifier ce prestataire",
        )


# =============================================================================
# Product Category Endpoints
# =============================================================================


@router.get(
    "/categories",
    response_model=list[ProductCategoryResponse],
    summary="Liste des categories",
    description="Retourne les categories de produits d'un prestataire.",
)
async def list_categories(
    provider_id: UUID,
    product_service: ProductServiceDep,
) -> list[ProductCategoryResponse]:
    """Get all product categories for a provider."""
    categories = await product_service.get_categories(provider_id)
    return [ProductCategoryResponse.model_validate(c) for c in categories]


@router.post(
    "/categories",
    response_model=ProductCategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Creer une categorie",
    description="Cree une nouvelle categorie de produits.",
)
async def create_category(
    provider_id: UUID,
    request: ProductCategoryCreate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> ProductCategoryResponse:
    """Create a product category."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    category = await product_service.create_category(
        provider_id=provider_id,
        name=request.name,
        display_order=request.display_order,
        is_active=request.is_active,
    )

    return ProductCategoryResponse.model_validate(category)


@router.put(
    "/categories/{category_id}",
    response_model=ProductCategoryResponse,
    summary="Modifier une categorie",
    description="Modifie une categorie de produits.",
)
async def update_category(
    provider_id: UUID,
    category_id: UUID,
    request: ProductCategoryUpdate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> ProductCategoryResponse:
    """Update a product category."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    category = await product_service.update_category(
        provider_id=provider_id,
        category_id=category_id,
        name=request.name,
        display_order=request.display_order,
        is_active=request.is_active,
    )

    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Categorie non trouvee",
        )

    return ProductCategoryResponse.model_validate(category)


@router.delete(
    "/categories/{category_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Supprimer une categorie",
    description="Supprime une categorie (les produits seront decategorises).",
)
async def delete_category(
    provider_id: UUID,
    category_id: UUID,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> None:
    """Delete a product category."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    success = await product_service.delete_category(provider_id, category_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Categorie non trouvee",
        )


# =============================================================================
# Product Endpoints
# =============================================================================


@router.get(
    "/products",
    response_model=ProductListResponse,
    summary="Liste des produits",
    description="Retourne les produits d'un prestataire.",
)
async def list_products(
    provider_id: UUID,
    product_service: ProductServiceDep,
    category_id: Optional[UUID] = Query(None, description="Filtrer par categorie"),
    is_available_only: bool = Query(False, description="Seulement les produits disponibles"),
    is_featured_only: bool = Query(False, description="Seulement les produits en vedette"),
) -> ProductListResponse:
    """Get all products for a provider."""
    products = await product_service.get_products(
        provider_id=provider_id,
        category_id=category_id,
        is_available_only=is_available_only,
        is_featured_only=is_featured_only,
    )
    return ProductListResponse(
        products=[ProductResponse.model_validate(p) for p in products],
        total=len(products),
    )


@router.get(
    "/products/{product_id}",
    response_model=ProductResponse,
    summary="Detail produit",
    description="Retourne les details d'un produit.",
)
async def get_product(
    provider_id: UUID,
    product_id: UUID,
    product_service: ProductServiceDep,
) -> ProductResponse:
    """Get product details."""
    product = await product_service.get_product(provider_id, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouve",
        )
    return ProductResponse.model_validate(product)


@router.post(
    "/products",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Creer un produit",
    description="Cree un nouveau produit avec options optionnelles.",
)
async def create_product(
    provider_id: UUID,
    request: ProductCreate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> ProductResponse:
    """Create a new product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    # Convert options to dict format
    options_data = None
    if request.options:
        options_data = [
            {
                "name": opt.name,
                "type": opt.type,
                "is_required": opt.is_required,
                "max_selections": opt.max_selections,
                "items": [
                    {
                        "name": item.name,
                        "price_adjustment": item.price_adjustment,
                        "is_available": item.is_available,
                    }
                    for item in opt.items
                ],
            }
            for opt in request.options
        ]

    product = await product_service.create_product(
        provider_id=provider_id,
        category_id=request.category_id,
        name=request.name,
        description=request.description,
        image_url=request.image_url,
        price=request.price,
        compare_at_price=request.compare_at_price,
        is_available=request.is_available,
        is_featured=request.is_featured,
        is_vegetarian=request.is_vegetarian,
        is_spicy=request.is_spicy,
        prep_time=request.prep_time,
        display_order=request.display_order,
        options=options_data,
    )

    return ProductResponse.model_validate(product)


@router.put(
    "/products/{product_id}",
    response_model=ProductResponse,
    summary="Modifier un produit",
    description="Modifie les informations d'un produit.",
)
async def update_product(
    provider_id: UUID,
    product_id: UUID,
    request: ProductUpdate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> ProductResponse:
    """Update a product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    product = await product_service.update_product(
        provider_id=provider_id,
        product_id=product_id,
        category_id=request.category_id,
        name=request.name,
        description=request.description,
        image_url=request.image_url,
        price=request.price,
        compare_at_price=request.compare_at_price,
        is_available=request.is_available,
        is_featured=request.is_featured,
        is_vegetarian=request.is_vegetarian,
        is_spicy=request.is_spicy,
        prep_time=request.prep_time,
        display_order=request.display_order,
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouve",
        )

    return ProductResponse.model_validate(product)


@router.delete(
    "/products/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Supprimer un produit",
    description="Supprime un produit.",
)
async def delete_product(
    provider_id: UUID,
    product_id: UUID,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> None:
    """Delete a product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    success = await product_service.delete_product(provider_id, product_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouve",
        )


@router.put(
    "/products/{product_id}/availability",
    response_model=ProductResponse,
    summary="Changer disponibilite",
    description="Change la disponibilite d'un produit.",
)
async def toggle_product_availability(
    provider_id: UUID,
    product_id: UUID,
    is_available: bool = Query(..., description="Disponible ou non"),
    current_user: CurrentUser = None,
    product_service: ProductServiceDep = None,
    provider_service: ProviderServiceDep = None,
) -> ProductResponse:
    """Toggle product availability."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    product = await product_service.toggle_product_availability(
        provider_id, product_id, is_available
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouve",
        )

    return ProductResponse.model_validate(product)


# =============================================================================
# Product Options Endpoints
# =============================================================================


@router.post(
    "/products/{product_id}/options",
    response_model=ProductOptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter option",
    description="Ajoute une option a un produit.",
)
async def add_product_option(
    provider_id: UUID,
    product_id: UUID,
    request: ProductOptionCreate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> ProductOptionResponse:
    """Add an option to a product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    items_data = [
        {
            "name": item.name,
            "price_adjustment": item.price_adjustment,
            "is_available": item.is_available,
        }
        for item in request.items
    ]

    option = await product_service.add_product_option(
        provider_id=provider_id,
        product_id=product_id,
        name=request.name,
        option_type=request.type,
        is_required=request.is_required,
        max_selections=request.max_selections,
        items=items_data,
    )

    if not option:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouve",
        )

    return ProductOptionResponse.model_validate(option)


@router.delete(
    "/products/{product_id}/options/{option_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Supprimer option",
    description="Supprime une option d'un produit.",
)
async def delete_product_option(
    provider_id: UUID,
    product_id: UUID,
    option_id: UUID,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> None:
    """Delete a product option."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    success = await product_service.delete_product_option(
        provider_id, product_id, option_id
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Option non trouvee",
        )


# =============================================================================
# Gas Products Endpoints
# =============================================================================


@router.get(
    "/gas-products",
    response_model=GasProductListResponse,
    summary="Liste produits gaz",
    description="Retourne les produits gaz d'un depot.",
)
async def list_gas_products(
    provider_id: UUID,
    product_service: ProductServiceDep,
    is_available_only: bool = Query(False, description="Seulement les produits disponibles"),
) -> GasProductListResponse:
    """Get all gas products for a provider."""
    products = await product_service.get_gas_products(
        provider_id, is_available_only=is_available_only
    )
    return GasProductListResponse(
        products=[GasProductResponse.model_validate(p) for p in products],
        total=len(products),
    )


@router.get(
    "/gas-products/{gas_product_id}",
    response_model=GasProductResponse,
    summary="Detail produit gaz",
    description="Retourne les details d'un produit gaz.",
)
async def get_gas_product(
    provider_id: UUID,
    gas_product_id: UUID,
    product_service: ProductServiceDep,
) -> GasProductResponse:
    """Get gas product details."""
    product = await product_service.get_gas_product(provider_id, gas_product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit gaz non trouve",
        )
    return GasProductResponse.model_validate(product)


@router.post(
    "/gas-products",
    response_model=GasProductResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Creer produit gaz",
    description="Cree un nouveau produit gaz.",
)
async def create_gas_product(
    provider_id: UUID,
    request: GasProductCreate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> GasProductResponse:
    """Create a gas product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    product = await product_service.create_gas_product(
        provider_id=provider_id,
        brand=request.brand,
        bottle_size=request.bottle_size,
        refill_price=request.refill_price,
        exchange_price=request.exchange_price,
        quantity_available=request.quantity_available,
        is_available=request.is_available,
    )

    return GasProductResponse.model_validate(product)


@router.put(
    "/gas-products/{gas_product_id}",
    response_model=GasProductResponse,
    summary="Modifier produit gaz",
    description="Modifie un produit gaz.",
)
async def update_gas_product(
    provider_id: UUID,
    gas_product_id: UUID,
    request: GasProductUpdate,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> GasProductResponse:
    """Update a gas product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    product = await product_service.update_gas_product(
        provider_id=provider_id,
        gas_product_id=gas_product_id,
        brand=request.brand,
        bottle_size=request.bottle_size,
        refill_price=request.refill_price,
        exchange_price=request.exchange_price,
        quantity_available=request.quantity_available,
        is_available=request.is_available,
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit gaz non trouve",
        )

    return GasProductResponse.model_validate(product)


@router.delete(
    "/gas-products/{gas_product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Supprimer produit gaz",
    description="Supprime un produit gaz.",
)
async def delete_gas_product(
    provider_id: UUID,
    gas_product_id: UUID,
    current_user: CurrentUser,
    product_service: ProductServiceDep,
    provider_service: ProviderServiceDep,
) -> None:
    """Delete a gas product."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    success = await product_service.delete_gas_product(provider_id, gas_product_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit gaz non trouve",
        )


@router.put(
    "/gas-products/{gas_product_id}/stock",
    response_model=GasProductResponse,
    summary="Mettre a jour stock",
    description="Met a jour la quantite en stock d'un produit gaz.",
)
async def update_gas_stock(
    provider_id: UUID,
    gas_product_id: UUID,
    quantity: int = Query(..., ge=0, description="Nouvelle quantite en stock"),
    current_user: CurrentUser = None,
    product_service: ProductServiceDep = None,
    provider_service: ProviderServiceDep = None,
) -> GasProductResponse:
    """Update gas product stock."""
    await verify_provider_ownership(provider_id, current_user, provider_service)

    product = await product_service.update_gas_stock(
        provider_id, gas_product_id, quantity
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit gaz non trouve",
        )

    return GasProductResponse.model_validate(product)
