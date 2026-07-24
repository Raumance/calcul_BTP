from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied


class EstAbonne(BasePermission):
    """Fonctionnalités avancées réservées aux abonnés actifs."""

    message = "ABONNEMENT_REQUIS"

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if not user.abonnement_actif():
            raise PermissionDenied(
                detail={
                    "status": "error",
                    "code": "ABONNEMENT_REQUIS",
                    "message": "Cette fonctionnalité nécessite un abonnement actif.",
                    "http_status": 403,
                }
            )
        return True
