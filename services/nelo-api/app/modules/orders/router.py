"""Orders module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/orders", tags=["Orders"])


# Endpoints will be implemented in M4
# POST / - Creer commande
# GET / - Mes commandes
# GET /:id - Detail commande
# PUT /:id/cancel - Annuler commande
# GET /:id/tracking - Suivi commande
