from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    DevisViewSet,
    HealthView,
    LoginView,
    LogoutView,
    PlanAnalyseView,
    ProjetViewSet,
    RegisterView,
    SyncJournalView,
    referentiels,
)

router = DefaultRouter()
router.register("projets", ProjetViewSet, basename="projet")
router.register("devis", DevisViewSet, basename="devis")

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("sync/journal/", SyncJournalView.as_view(), name="sync_journal"),
    path("plans/analyse/", PlanAnalyseView.as_view(), name="plan_analyse"),
    path("referentiels/", referentiels, name="referentiels"),
    path("", include(router.urls)),
]
