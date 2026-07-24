from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def root(_request):
    """Évite un 404 trompeur sur / — l'API vit sous /api/."""
    return JsonResponse(
        {
            "service": "calcul-btp-api",
            "docs": {
                "health": "/api/health/",
                "admin": "/admin/",
                "auth_login": "/api/auth/login/",
            },
        }
    )


urlpatterns = [
    path("", root, name="root"),
    path("admin/", admin.site.urls),
    path("api/", include("calcul_btp.urls")),
]
