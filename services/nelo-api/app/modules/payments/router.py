"""Payments module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/wallet", tags=["Payments"])


# Endpoints will be implemented in M5
# GET / - Solde
# GET /transactions - Historique
# POST /topup - Recharger
# POST /transfer - Transfert P2P
