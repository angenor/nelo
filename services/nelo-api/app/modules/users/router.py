"""Users module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["Users"])


# Endpoints will be implemented in M2
# GET /me - Profil courant
# PUT /me - Modifier profil
# GET /me/addresses - Lister adresses
# POST /me/addresses - Ajouter adresse
# PUT /me/addresses/:id - Modifier adresse
# DELETE /me/addresses/:id - Supprimer adresse
