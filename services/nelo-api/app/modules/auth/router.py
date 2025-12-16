"""Auth module API routes."""

from fastapi import APIRouter

router = APIRouter(prefix="/auth", tags=["Auth"])


# Endpoints will be implemented in M2
# POST /register - Inscription par telephone
# POST /login - Connexion
# POST /send-otp - Envoi OTP
# POST /verify-otp - Verification OTP
# POST /refresh - Refresh token
# POST /logout - Deconnexion
