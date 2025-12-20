"""Notifications module service."""

import logging
from typing import Optional
from uuid import UUID

import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)


class NotificationService:
    """Service for sending notifications to users."""

    def __init__(self, db: AsyncSession, redis_client: redis.Redis):
        self.db = db
        self.redis = redis_client

    # =========================================================================
    # Push Notifications (Stub - to be integrated with FCM/APNs)
    # =========================================================================

    async def send_push(
        self,
        user_id: UUID,
        title: str,
        body: str,
        data: Optional[dict] = None,
        notification_type: str = "general",
    ) -> bool:
        """
        Send push notification to a user.

        In production, this will integrate with:
        - Firebase Cloud Messaging (FCM) for Android
        - Apple Push Notification Service (APNs) for iOS
        """
        logger.info(
            f"[PUSH] To user {user_id}: {title} - {body}",
            extra={"user_id": str(user_id), "type": notification_type, "data": data},
        )

        # Store notification in database for history
        await self._store_notification(
            user_id=user_id,
            title=title,
            body=body,
            notification_type=notification_type,
            data=data,
        )

        # TODO: Integrate with FCM/APNs
        # - Get user's device tokens from database
        # - Send push via Firebase Admin SDK or APNs
        return True

    # =========================================================================
    # SMS Notifications (Stub - to be integrated with Orange CI / Twilio)
    # =========================================================================

    async def send_sms(
        self,
        phone: str,
        message: str,
        sms_type: str = "transactional",
    ) -> bool:
        """
        Send SMS to a phone number.

        In production, this will integrate with:
        - Orange CI SMS API (primary for Côte d'Ivoire)
        - Twilio (backup)
        """
        logger.info(
            f"[SMS] To {phone}: {message}",
            extra={"phone": phone, "type": sms_type},
        )

        # TODO: Integrate with SMS provider
        # - Orange CI for local numbers
        # - Twilio for international
        return True

    # =========================================================================
    # Order Notifications
    # =========================================================================

    async def notify_order_created(
        self,
        user_id: UUID,
        order_reference: str,
        provider_name: str,
        total_amount: int,
    ) -> None:
        """Notify user that order was created."""
        await self.send_push(
            user_id=user_id,
            title="Commande créée",
            body=f"Votre commande {order_reference} chez {provider_name} a été créée. Total: {total_amount} FCFA",
            data={"order_reference": order_reference},
            notification_type="order_created",
        )

    async def notify_order_confirmed(
        self,
        user_id: UUID,
        order_reference: str,
        provider_name: str,
        estimated_time: Optional[int] = None,
    ) -> None:
        """Notify user that order was confirmed by provider."""
        time_text = f" Temps estimé: {estimated_time} min" if estimated_time else ""
        await self.send_push(
            user_id=user_id,
            title="Commande confirmée",
            body=f"{provider_name} a confirmé votre commande {order_reference}.{time_text}",
            data={"order_reference": order_reference},
            notification_type="order_confirmed",
        )

    async def notify_order_ready(
        self,
        user_id: UUID,
        order_reference: str,
        provider_name: str,
    ) -> None:
        """Notify user that order is ready for pickup."""
        await self.send_push(
            user_id=user_id,
            title="Commande prête",
            body=f"Votre commande {order_reference} est prête chez {provider_name}. Un livreur va bientôt la récupérer.",
            data={"order_reference": order_reference},
            notification_type="order_ready",
        )

    async def notify_order_cancelled(
        self,
        user_id: UUID,
        order_reference: str,
        reason: Optional[str] = None,
    ) -> None:
        """Notify user that order was cancelled."""
        reason_text = f" Raison: {reason}" if reason else ""
        await self.send_push(
            user_id=user_id,
            title="Commande annulée",
            body=f"Votre commande {order_reference} a été annulée.{reason_text}",
            data={"order_reference": order_reference},
            notification_type="order_cancelled",
        )

    # =========================================================================
    # Delivery Notifications
    # =========================================================================

    async def notify_driver_assigned(
        self,
        user_id: UUID,
        order_reference: str,
        driver_name: str,
        driver_phone: str,
    ) -> None:
        """Notify user that a driver has been assigned."""
        await self.send_push(
            user_id=user_id,
            title="Livreur assigné",
            body=f"{driver_name} va livrer votre commande {order_reference}. Tél: {driver_phone}",
            data={"order_reference": order_reference, "driver_phone": driver_phone},
            notification_type="driver_assigned",
        )

    async def notify_driver_picked_up(
        self,
        user_id: UUID,
        order_reference: str,
        estimated_arrival: Optional[int] = None,
    ) -> None:
        """Notify user that driver picked up the order."""
        time_text = f" Arrivée estimée: {estimated_arrival} min" if estimated_arrival else ""
        await self.send_push(
            user_id=user_id,
            title="Commande en route",
            body=f"Votre commande {order_reference} est en route vers vous.{time_text}",
            data={"order_reference": order_reference},
            notification_type="order_picked_up",
        )

    async def notify_driver_arriving(
        self,
        user_id: UUID,
        order_reference: str,
    ) -> None:
        """Notify user that driver is arriving."""
        await self.send_push(
            user_id=user_id,
            title="Livreur bientôt là",
            body=f"Le livreur arrive avec votre commande {order_reference}. Préparez-vous!",
            data={"order_reference": order_reference},
            notification_type="driver_arriving",
        )

    async def notify_order_delivered(
        self,
        user_id: UUID,
        order_reference: str,
    ) -> None:
        """Notify user that order was delivered."""
        await self.send_push(
            user_id=user_id,
            title="Commande livrée",
            body=f"Votre commande {order_reference} a été livrée. Bon appétit! N'oubliez pas de noter votre expérience.",
            data={"order_reference": order_reference},
            notification_type="order_delivered",
        )

    # =========================================================================
    # Driver Notifications
    # =========================================================================

    async def notify_new_delivery_offer(
        self,
        driver_user_id: UUID,
        pickup_address: str,
        delivery_address: str,
        earnings: int,
        distance_km: float,
    ) -> None:
        """Notify driver of new delivery offer."""
        await self.send_push(
            user_id=driver_user_id,
            title="Nouvelle course",
            body=f"Course disponible: {pickup_address} → {delivery_address}. {earnings} FCFA ({distance_km:.1f} km)",
            data={"type": "delivery_offer"},
            notification_type="delivery_offer",
        )

    async def notify_offer_expired(
        self,
        driver_user_id: UUID,
    ) -> None:
        """Notify driver that offer expired."""
        await self.send_push(
            user_id=driver_user_id,
            title="Offre expirée",
            body="L'offre de course a expiré. Restez disponible pour la prochaine!",
            notification_type="offer_expired",
        )

    # =========================================================================
    # Provider Notifications
    # =========================================================================

    async def notify_provider_new_order(
        self,
        provider_user_id: UUID,
        order_reference: str,
        customer_name: str,
        total_amount: int,
    ) -> None:
        """Notify provider of new order."""
        await self.send_push(
            user_id=provider_user_id,
            title="Nouvelle commande!",
            body=f"Commande {order_reference} de {customer_name}. Total: {total_amount} FCFA",
            data={"order_reference": order_reference},
            notification_type="new_order",
        )

        # Also send SMS for critical notification
        # await self.send_sms(...)

    # =========================================================================
    # Internal Storage
    # =========================================================================

    async def _store_notification(
        self,
        user_id: UUID,
        title: str,
        _body: str,
        notification_type: str,
        _data: Optional[dict] = None,
    ) -> None:
        """Store notification in database for history."""
        # TODO: Create notifications table and store
        # _body and _data will be used when implementing storage
        logger.debug(
            f"Storing notification for user {user_id}: {title}",
            extra={"type": notification_type},
        )

    async def get_user_notifications(
        self,
        _user_id: UUID,
        _page: int = 1,
        _page_size: int = 20,
    ) -> tuple[list[dict], int]:
        """Get user's notification history."""
        # TODO: Implement when notifications table is ready
        # Parameters prefixed with _ will be used in implementation
        return [], 0

    async def mark_as_read(
        self,
        _user_id: UUID,
        _notification_id: UUID,
    ) -> bool:
        """Mark a notification as read."""
        # TODO: Implement - parameters will be used
        return True

    async def mark_all_as_read(
        self,
        _user_id: UUID,
    ) -> int:
        """Mark all notifications as read for user."""
        # TODO: Implement - parameter will be used
        return 0
