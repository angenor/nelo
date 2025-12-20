"""Deliveries module service with driver matching."""

import random
import string
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional
from uuid import UUID

from geoalchemy2.functions import ST_Distance, ST_DWithin, ST_SetSRID, ST_MakePoint, ST_Transform
from sqlalchemy import and_, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.deliveries.models import (
    Delivery,
    DeliveryLocationHistory,
    DeliveryOffer,
    DeliveryStatus,
    DeliveryStatusHistory,
    Driver,
    DriverDocument,
    OfferStatus,
)
from app.shared.events.event_bus import EventBus, Event


class DriverMatchingAlgorithm:
    """Algorithm for matching drivers to deliveries."""

    # Weights for matching score
    WEIGHT_PROXIMITY = 0.30
    WEIGHT_AVAILABILITY = 0.25
    WEIGHT_RATING = 0.20
    WEIGHT_VEHICLE = 0.15
    WEIGHT_HISTORY = 0.10

    @classmethod
    def calculate_score(
        cls,
        driver: Driver,
        distance_km: float,
        _order_value: int,
        required_vehicle: Optional[str] = None,
    ) -> float:
        """Calculate matching score for a driver."""
        # Proximity score (closer is better, max 5km)
        # Note: _order_value reserved for future scoring based on order size
        max_distance = 5.0
        proximity_score = max(0, 1 - (distance_km / max_distance))

        # Availability score (based on current orders)
        current_orders = 0  # TODO: Get from active deliveries
        availability_score = 1 - (current_orders / driver.max_orders)

        # Rating score (normalized 0-1)
        rating_score = (float(driver.average_rating or 3.0) - 1) / 4

        # Vehicle score (match required type)
        vehicle_score = 1.0
        if required_vehicle and driver.vehicle_type != required_vehicle:
            vehicle_score = 0.5

        # History score (based on completion rate)
        history_score = float(driver.completion_rate) / 100

        # Calculate weighted score
        score = (
            cls.WEIGHT_PROXIMITY * proximity_score +
            cls.WEIGHT_AVAILABILITY * availability_score +
            cls.WEIGHT_RATING * rating_score +
            cls.WEIGHT_VEHICLE * vehicle_score +
            cls.WEIGHT_HISTORY * history_score
        )

        return round(score * 100, 2)  # Return as percentage


class DeliveryService:
    """Service for delivery operations."""

    OFFER_EXPIRY_SECONDS = 60  # 1 minute to accept

    def __init__(self, db: AsyncSession):
        self.db = db
        self.matching = DriverMatchingAlgorithm()

    # =========================================================================
    # Driver Management
    # =========================================================================

    async def register_driver(
        self,
        user_id: UUID,
        first_name: str,
        last_name: str,
        phone: str,
        city_id: UUID,
        vehicle_type: str,
        vehicle_brand: Optional[str] = None,
        vehicle_model: Optional[str] = None,
        vehicle_plate: Optional[str] = None,
        avatar_url: Optional[str] = None,
    ) -> Driver:
        """Register a new driver."""
        # Check if driver already exists
        existing = await self.get_driver_by_user_id(user_id)
        if existing:
            raise ValueError("Ce compte est deja enregistre comme livreur")

        driver = Driver(
            user_id=user_id,
            first_name=first_name,
            last_name=last_name,
            display_name=f"{first_name} {last_name[0]}.",
            phone=phone,
            city_id=city_id,
            vehicle_type=vehicle_type,
            vehicle_brand=vehicle_brand,
            vehicle_model=vehicle_model,
            vehicle_plate=vehicle_plate,
            avatar_url=avatar_url,
            status="pending",
            is_available=False,
            is_online=False,
        )
        self.db.add(driver)
        await self.db.flush()

        return driver

    async def get_driver(self, driver_id: UUID) -> Optional[Driver]:
        """Get driver by ID."""
        result = await self.db.execute(
            select(Driver)
            .where(Driver.id == driver_id)
            .options(selectinload(Driver.city))
        )
        return result.scalar_one_or_none()

    async def get_driver_by_user_id(self, user_id: UUID) -> Optional[Driver]:
        """Get driver by user ID."""
        result = await self.db.execute(
            select(Driver)
            .where(Driver.user_id == user_id)
            .options(selectinload(Driver.city))
        )
        return result.scalar_one_or_none()

    async def update_driver_status(
        self, driver_id: UUID, status: str
    ) -> Optional[Driver]:
        """Update driver approval status (admin action)."""
        driver = await self.get_driver(driver_id)
        if not driver:
            return None

        driver.status = status
        if status == "active":
            driver.is_available = True
        elif status in ("suspended", "rejected"):
            driver.is_available = False
            driver.is_online = False

        await self.db.flush()
        return driver

    async def toggle_driver_online(
        self, user_id: UUID, is_online: bool
    ) -> Optional[Driver]:
        """Toggle driver online/offline status."""
        driver = await self.get_driver_by_user_id(user_id)
        if not driver:
            return None

        if driver.status != "active":
            raise ValueError("Compte livreur non active")

        driver.is_online = is_online
        if not is_online:
            driver.is_available = False

        await self.db.flush()
        return driver

    async def update_driver_location(
        self,
        user_id: UUID,
        latitude: Decimal,
        longitude: Decimal,
    ) -> Optional[Driver]:
        """Update driver's current location."""
        driver = await self.get_driver_by_user_id(user_id)
        if not driver:
            return None

        driver.current_latitude = latitude
        driver.current_longitude = longitude
        driver.location_updated_at = datetime.now(timezone.utc)

        # Update geometry (handled by trigger in DB, but also set here)
        await self.db.execute(
            text("""
                UPDATE deliveries.drivers
                SET current_location = ST_SetSRID(ST_MakePoint(:lon, :lat), 4326),
                    location_updated_at = NOW()
                WHERE id = :driver_id
            """),
            {"lon": float(longitude), "lat": float(latitude), "driver_id": driver.id}
        )

        await self.db.flush()
        return driver

    # =========================================================================
    # Driver Documents
    # =========================================================================

    async def add_driver_document(
        self,
        driver_id: UUID,
        document_type: str,
        front_image_url: str,
        document_number: Optional[str] = None,
        back_image_url: Optional[str] = None,
    ) -> DriverDocument:
        """Add a document for driver verification."""
        document = DriverDocument(
            driver_id=driver_id,
            document_type=document_type,
            document_number=document_number,
            front_image_url=front_image_url,
            back_image_url=back_image_url,
            status="pending",
        )
        self.db.add(document)
        await self.db.flush()
        return document

    async def verify_driver_document(
        self,
        document_id: UUID,
        verified_by: UUID,
        is_approved: bool,
    ) -> Optional[DriverDocument]:
        """Verify a driver document (admin action)."""
        result = await self.db.execute(
            select(DriverDocument).where(DriverDocument.id == document_id)
        )
        document = result.scalar_one_or_none()
        if not document:
            return None

        document.status = "approved" if is_approved else "rejected"
        document.verified_by = verified_by
        document.verified_at = datetime.now(timezone.utc)

        await self.db.flush()
        return document

    # =========================================================================
    # Delivery Creation & Assignment
    # =========================================================================

    async def create_delivery(
        self,
        order_id: UUID,
        order_reference: str,
        pickup_latitude: Decimal,
        pickup_longitude: Decimal,
        pickup_address: str,
        delivery_latitude: Decimal,
        delivery_longitude: Decimal,
        delivery_address: str,
        delivery_fee: int,
        pickup_contact_name: Optional[str] = None,
        pickup_contact_phone: Optional[str] = None,
        delivery_contact_name: Optional[str] = None,
        delivery_contact_phone: Optional[str] = None,
    ) -> Delivery:
        """Create a new delivery for an order."""
        reference = self._generate_reference()

        # Calculate distance
        distance_km = await self._calculate_distance(
            pickup_latitude, pickup_longitude,
            delivery_latitude, delivery_longitude
        )

        delivery = Delivery(
            reference=reference,
            order_id=order_id,
            order_reference=order_reference,
            status=DeliveryStatus.PENDING.value,
            pickup_latitude=pickup_latitude,
            pickup_longitude=pickup_longitude,
            pickup_address=pickup_address,
            pickup_contact_name=pickup_contact_name,
            pickup_contact_phone=pickup_contact_phone,
            delivery_latitude=delivery_latitude,
            delivery_longitude=delivery_longitude,
            delivery_address=delivery_address,
            delivery_contact_name=delivery_contact_name,
            delivery_contact_phone=delivery_contact_phone,
            distance_km=distance_km,
            delivery_fee=delivery_fee,
            delivery_code=self._generate_delivery_code(),
        )
        self.db.add(delivery)
        await self.db.flush()

        # Record initial status
        await self._record_status_change(
            delivery.id, None, DeliveryStatus.PENDING, None
        )

        # Publish event
        await EventBus.publish(Event(
            name="delivery.created",
            data={
                "delivery_id": str(delivery.id),
                "order_id": str(order_id),
                "reference": reference,
            }
        ))

        return delivery

    async def find_and_offer_drivers(
        self, delivery_id: UUID, order_value: int = 0
    ) -> list[DeliveryOffer]:
        """Find nearby available drivers and create offers."""
        delivery = await self.get_delivery(delivery_id)
        if not delivery:
            raise ValueError("Livraison non trouvee")

        # Find nearby available drivers
        drivers = await self._find_nearby_drivers(
            delivery.pickup_latitude,
            delivery.pickup_longitude,
            radius_km=5.0,
        )

        if not drivers:
            return []

        offers = []
        expires_at = datetime.now(timezone.utc) + timedelta(seconds=self.OFFER_EXPIRY_SECONDS)

        for driver_data in drivers[:5]:  # Limit to top 5 drivers
            driver = driver_data["driver"]
            distance_km = driver_data["distance_km"]

            # Calculate matching score
            score = self.matching.calculate_score(
                driver, distance_km, order_value
            )

            # Calculate estimated earnings
            driver_earnings = int(delivery.delivery_fee * (1 - float(driver.commission_rate)))

            # Create offer
            offer = DeliveryOffer(
                delivery_id=delivery_id,
                driver_id=driver.id,
                matching_score=score,
                distance_km=Decimal(str(distance_km)),
                estimated_earnings=driver_earnings,
                status=OfferStatus.PENDING.value,
                expires_at=expires_at,
            )
            self.db.add(offer)
            offers.append(offer)

        await self.db.flush()

        # Publish event
        await EventBus.publish(Event(
            name="delivery.offers_sent",
            data={
                "delivery_id": str(delivery_id),
                "offer_count": len(offers),
            }
        ))

        return offers

    async def accept_offer(
        self, offer_id: UUID, driver_user_id: UUID
    ) -> Optional[Delivery]:
        """Accept a delivery offer."""
        # Get driver
        driver = await self.get_driver_by_user_id(driver_user_id)
        if not driver:
            raise ValueError("Livreur non trouve")

        # Get offer
        result = await self.db.execute(
            select(DeliveryOffer)
            .where(
                DeliveryOffer.id == offer_id,
                DeliveryOffer.driver_id == driver.id,
            )
        )
        offer = result.scalar_one_or_none()
        if not offer:
            raise ValueError("Offre non trouvee")

        # Check if expired
        if datetime.now(timezone.utc) > offer.expires_at:
            offer.status = OfferStatus.EXPIRED.value
            await self.db.flush()
            raise ValueError("Offre expiree")

        # Check if already accepted
        if offer.status != OfferStatus.PENDING.value:
            raise ValueError("Offre deja traitee")

        # Accept this offer
        offer.status = OfferStatus.ACCEPTED.value

        # Reject all other offers for this delivery
        await self.db.execute(
            text("""
                UPDATE deliveries.delivery_offers
                SET status = 'rejected'
                WHERE delivery_id = :delivery_id AND id != :offer_id
            """),
            {"delivery_id": offer.delivery_id, "offer_id": offer_id}
        )

        # Assign driver to delivery
        delivery = await self.get_delivery(offer.delivery_id)
        if delivery:
            delivery.driver_id = driver.id
            delivery.status = DeliveryStatus.ACCEPTED.value
            delivery.assigned_at = datetime.now(timezone.utc)
            delivery.matching_score = offer.matching_score
            delivery.driver_earnings = offer.estimated_earnings

            # Calculate ETA (rough estimate: 5 min/km + 10 min pickup)
            distance = float(offer.distance_km or 0)
            eta_minutes = int(distance * 5 + 10)
            delivery.eta_minutes = eta_minutes

            # Record status change
            await self._record_status_change(
                delivery.id,
                DeliveryStatus.PENDING,
                DeliveryStatus.ACCEPTED,
                driver.id,
            )

        # Update driver availability
        driver.is_available = False

        await self.db.flush()

        # Publish event
        await EventBus.publish(Event(
            name="delivery.assigned",
            data={
                "delivery_id": str(delivery.id),
                "driver_id": str(driver.id),
                "order_id": str(delivery.order_id),
            }
        ))

        return delivery

    async def reject_offer(
        self, offer_id: UUID, driver_user_id: UUID
    ) -> bool:
        """Reject a delivery offer."""
        driver = await self.get_driver_by_user_id(driver_user_id)
        if not driver:
            return False

        result = await self.db.execute(
            select(DeliveryOffer)
            .where(
                DeliveryOffer.id == offer_id,
                DeliveryOffer.driver_id == driver.id,
            )
        )
        offer = result.scalar_one_or_none()
        if not offer:
            return False

        offer.status = OfferStatus.REJECTED.value
        await self.db.flush()
        return True

    # =========================================================================
    # Delivery Status Management
    # =========================================================================

    async def update_delivery_status(
        self,
        delivery_id: UUID,
        new_status: DeliveryStatus,
        driver_user_id: UUID,
        latitude: Optional[Decimal] = None,
        longitude: Optional[Decimal] = None,
    ) -> Optional[Delivery]:
        """Update delivery status."""
        delivery = await self.get_delivery(delivery_id)
        if not delivery:
            return None

        # Verify driver
        driver = await self.get_driver_by_user_id(driver_user_id)
        if not driver or delivery.driver_id != driver.id:
            raise ValueError("Non autorise")

        current_status = DeliveryStatus(delivery.status)

        # Validate transition
        valid_transitions = {
            DeliveryStatus.ACCEPTED: [DeliveryStatus.PICKING_UP],
            DeliveryStatus.PICKING_UP: [DeliveryStatus.PICKED_UP],
            DeliveryStatus.PICKED_UP: [DeliveryStatus.DELIVERING],
            DeliveryStatus.DELIVERING: [DeliveryStatus.DELIVERED, DeliveryStatus.FAILED],
        }

        if new_status not in valid_transitions.get(current_status, []):
            raise ValueError(f"Transition invalide: {current_status.value} -> {new_status.value}")

        # Update status
        delivery.status = new_status.value
        now = datetime.now(timezone.utc)

        if new_status == DeliveryStatus.PICKED_UP:
            delivery.picked_up_at = now
        elif new_status == DeliveryStatus.DELIVERED:
            delivery.delivered_at = now
            # Make driver available again
            driver.is_available = True
            driver.total_deliveries += 1

        await self.db.flush()

        # Record status change
        await self._record_status_change(
            delivery_id, current_status, new_status, driver.id, latitude, longitude
        )

        # Publish event
        await EventBus.publish(Event(
            name=f"delivery.{new_status.value}",
            data={
                "delivery_id": str(delivery_id),
                "order_id": str(delivery.order_id),
                "driver_id": str(driver.id),
            }
        ))

        return delivery

    async def confirm_delivery(
        self,
        delivery_id: UUID,
        driver_user_id: UUID,
        delivery_code: str,
        photo_url: Optional[str] = None,
    ) -> Optional[Delivery]:
        """Confirm delivery with code verification."""
        delivery = await self.get_delivery(delivery_id)
        if not delivery:
            return None

        # Verify code
        if delivery.delivery_code != delivery_code:
            raise ValueError("Code de livraison invalide")

        # Save photo if provided
        if photo_url:
            delivery.delivery_photo_url = photo_url

        # Update to delivered
        return await self.update_delivery_status(
            delivery_id,
            DeliveryStatus.DELIVERED,
            driver_user_id,
        )

    # =========================================================================
    # Delivery Tracking
    # =========================================================================

    async def record_location(
        self,
        delivery_id: UUID,
        driver_id: UUID,
        latitude: Decimal,
        longitude: Decimal,
        speed: Optional[Decimal] = None,
    ) -> DeliveryLocationHistory:
        """Record driver location for tracking."""
        location = DeliveryLocationHistory(
            delivery_id=delivery_id,
            driver_id=driver_id,
            latitude=latitude,
            longitude=longitude,
            speed=speed,
        )
        self.db.add(location)
        await self.db.flush()
        return location

    async def get_delivery_tracking(self, delivery_id: UUID) -> dict:
        """Get delivery tracking information."""
        delivery = await self.get_delivery(delivery_id)
        if not delivery:
            raise ValueError("Livraison non trouvee")

        # Get driver info
        driver_info = None
        if delivery.driver:
            driver_info = {
                "id": str(delivery.driver.id),
                "name": delivery.driver.display_name or f"{delivery.driver.first_name} {delivery.driver.last_name}",
                "phone": delivery.driver.phone,
                "avatar_url": delivery.driver.avatar_url,
                "vehicle_type": delivery.driver.vehicle_type,
                "vehicle_plate": delivery.driver.vehicle_plate,
                "current_location": {
                    "latitude": float(delivery.driver.current_latitude) if delivery.driver.current_latitude else None,
                    "longitude": float(delivery.driver.current_longitude) if delivery.driver.current_longitude else None,
                } if delivery.driver.current_latitude else None,
            }

        # Get location history
        result = await self.db.execute(
            select(DeliveryLocationHistory)
            .where(DeliveryLocationHistory.delivery_id == delivery_id)
            .order_by(DeliveryLocationHistory.recorded_at.desc())
            .limit(50)
        )
        locations = list(result.scalars().all())

        return {
            "delivery_id": str(delivery.id),
            "reference": delivery.reference,
            "status": delivery.status,
            "eta_minutes": delivery.eta_minutes,
            "pickup": {
                "address": delivery.pickup_address,
                "latitude": float(delivery.pickup_latitude),
                "longitude": float(delivery.pickup_longitude),
            },
            "destination": {
                "address": delivery.delivery_address,
                "latitude": float(delivery.delivery_latitude),
                "longitude": float(delivery.delivery_longitude),
            },
            "driver": driver_info,
            "timestamps": {
                "assigned_at": delivery.assigned_at.isoformat() if delivery.assigned_at else None,
                "picked_up_at": delivery.picked_up_at.isoformat() if delivery.picked_up_at else None,
                "delivered_at": delivery.delivered_at.isoformat() if delivery.delivered_at else None,
            },
            "location_history": [
                {
                    "latitude": float(loc.latitude),
                    "longitude": float(loc.longitude),
                    "speed": float(loc.speed) if loc.speed else None,
                    "recorded_at": loc.recorded_at.isoformat(),
                }
                for loc in locations
            ],
        }

    # =========================================================================
    # Driver Offers & Queries
    # =========================================================================

    async def get_driver_offers(
        self, driver_user_id: UUID, status: Optional[str] = None
    ) -> list[DeliveryOffer]:
        """Get offers for a driver."""
        driver = await self.get_driver_by_user_id(driver_user_id)
        if not driver:
            return []

        query = (
            select(DeliveryOffer)
            .where(DeliveryOffer.driver_id == driver.id)
            .options(selectinload(DeliveryOffer.delivery))
        )

        if status:
            query = query.where(DeliveryOffer.status == status)
        else:
            # Default to pending and not expired
            query = query.where(
                DeliveryOffer.status == OfferStatus.PENDING.value,
                DeliveryOffer.expires_at > datetime.now(timezone.utc),
            )

        query = query.order_by(DeliveryOffer.created_at.desc())

        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_delivery(self, delivery_id: UUID) -> Optional[Delivery]:
        """Get delivery by ID."""
        result = await self.db.execute(
            select(Delivery)
            .where(Delivery.id == delivery_id)
            .options(selectinload(Delivery.driver))
        )
        return result.scalar_one_or_none()

    async def get_driver_active_deliveries(
        self, driver_user_id: UUID
    ) -> list[Delivery]:
        """Get active deliveries for a driver."""
        driver = await self.get_driver_by_user_id(driver_user_id)
        if not driver:
            return []

        active_statuses = [
            DeliveryStatus.ACCEPTED.value,
            DeliveryStatus.PICKING_UP.value,
            DeliveryStatus.PICKED_UP.value,
            DeliveryStatus.DELIVERING.value,
        ]

        result = await self.db.execute(
            select(Delivery)
            .where(
                Delivery.driver_id == driver.id,
                Delivery.status.in_(active_statuses),
            )
            .order_by(Delivery.created_at.desc())
        )
        return list(result.scalars().all())

    # =========================================================================
    # Private Helpers
    # =========================================================================

    async def _find_nearby_drivers(
        self,
        latitude: Decimal,
        longitude: Decimal,
        radius_km: float = 5.0,
    ) -> list[dict]:
        """Find available drivers within radius."""
        radius_meters = radius_km * 1000

        point = func.ST_SetSRID(
            func.ST_MakePoint(float(longitude), float(latitude)), 4326
        )

        distance = (
            func.ST_Distance(
                func.ST_Transform(Driver.current_location, 3857),
                func.ST_Transform(point, 3857),
            )
            / 1000
        ).label("distance_km")

        result = await self.db.execute(
            select(Driver, distance)
            .where(
                Driver.status == "active",
                Driver.is_online == True,
                Driver.is_available == True,
                Driver.current_location.isnot(None),
                func.ST_DWithin(
                    func.ST_Transform(Driver.current_location, 3857),
                    func.ST_Transform(point, 3857),
                    radius_meters,
                ),
            )
            .order_by(distance)
            .limit(10)
        )

        return [
            {"driver": driver, "distance_km": round(dist, 2) if dist else 0}
            for driver, dist in result.all()
        ]

    async def _calculate_distance(
        self,
        lat1: Decimal,
        lon1: Decimal,
        lat2: Decimal,
        lon2: Decimal,
    ) -> Decimal:
        """Calculate distance between two points in km."""
        result = await self.db.execute(
            text("""
                SELECT ST_Distance(
                    ST_Transform(ST_SetSRID(ST_MakePoint(:lon1, :lat1), 4326), 3857),
                    ST_Transform(ST_SetSRID(ST_MakePoint(:lon2, :lat2), 4326), 3857)
                ) / 1000 AS distance_km
            """),
            {"lon1": float(lon1), "lat1": float(lat1), "lon2": float(lon2), "lat2": float(lat2)}
        )
        row = result.fetchone()
        return Decimal(str(round(row.distance_km, 2))) if row else Decimal("0")

    async def _record_status_change(
        self,
        delivery_id: UUID,
        from_status: Optional[DeliveryStatus],
        to_status: DeliveryStatus,
        changed_by: Optional[UUID],
        latitude: Optional[Decimal] = None,
        longitude: Optional[Decimal] = None,
    ) -> None:
        """Record delivery status change."""
        history = DeliveryStatusHistory(
            delivery_id=delivery_id,
            from_status=from_status.value if from_status else None,
            to_status=to_status.value,
            changed_by=changed_by,
            latitude=latitude,
            longitude=longitude,
        )
        self.db.add(history)
        await self.db.flush()

    def _generate_reference(self) -> str:
        """Generate unique delivery reference."""
        chars = string.ascii_uppercase + string.digits
        suffix = "".join(random.choices(chars, k=8))
        return f"DEL-{suffix}"

    def _generate_delivery_code(self) -> str:
        """Generate 6-digit delivery confirmation code."""
        return "".join(random.choices(string.digits, k=6))
