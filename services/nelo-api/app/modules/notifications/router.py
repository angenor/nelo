"""Notifications module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["Notifications"])


# Endpoints will be implemented later
# GET / - Liste des notifications
# PUT /:id/read - Marquer comme lu
