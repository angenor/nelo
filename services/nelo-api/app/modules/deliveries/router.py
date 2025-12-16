"""Deliveries module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/drivers", tags=["Deliveries"])


# Endpoints will be implemented in M4
# POST /register - Inscription livreur
# PUT /me/status - Online/Offline
# PUT /me/location - MAJ position
# GET /offers - Courses disponibles
# POST /offers/:id/accept - Accepter course
# POST /offers/:id/reject - Refuser course
