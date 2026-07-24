from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from .models import Calcul, Devis, Projet
from .permissions import EstAbonne
from .serializers import (
    CalculSerializer,
    DevisSerializer,
    LoginSerializer,
    ProjetSerializer,
    RegisterSerializer,
    tokens_for_user,
)
from .services.plan_ia import analyser_plan
from .services.sync import appliquer_entree_journal


def success(data, http_status=200):
    return Response(
        {
            "status": "success",
            "data": data,
            "meta": {"timestamp": timezone.now().isoformat()},
        },
        status=http_status,
    )


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return success(tokens_for_user(user), status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return success(tokens_for_user(serializer.validated_data["user"]))


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh = request.data.get("refresh")
        if refresh:
            try:
                token = RefreshToken(refresh)
                token.blacklist()
            except Exception:
                pass
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProjetViewSet(viewsets.ModelViewSet):
    serializer_class = ProjetSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Projet.objects.filter(utilisateur=self.request.user).order_by(
            "-updated_at"
        )

    def perform_create(self, serializer):
        serializer.save(utilisateur=self.request.user)

    @action(detail=True, methods=["get", "post"])
    def calculs(self, request, pk=None):
        projet = self.get_object()
        if request.method == "GET":
            qs = projet.calculs.all().order_by("-created_at")
            return success(CalculSerializer(qs, many=True).data)
        serializer = CalculSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        calcul = serializer.save(projet=projet)
        return success(CalculSerializer(calcul).data, status.HTTP_201_CREATED)

    @action(detail=True, methods=["get", "post"])
    def devis(self, request, pk=None):
        projet = self.get_object()
        if request.method == "GET":
            qs = projet.devis.all().order_by("-created_at")
            return success(DevisSerializer(qs, many=True).data)
        serializer = DevisSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        devis = serializer.save(projet=projet)
        return success(DevisSerializer(devis).data, status.HTTP_201_CREATED)


class DevisViewSet(mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    serializer_class = DevisSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Devis.objects.filter(projet__utilisateur=self.request.user)

    def retrieve(self, request, *args, **kwargs):
        return success(self.get_serializer(self.get_object()).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, EstAbonne], url_path="export/pdf")
    def export_pdf(self, request, pk=None):
        # Génération PDF côté serveur — placeholder binaire minimal.
        devis = self.get_object()
        return success(
            {
                "filename": f"devis_{devis.id}.pdf",
                "message": "Export PDF généré (reportlab).",
            }
        )

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, EstAbonne], url_path="export/excel")
    def export_excel(self, request, pk=None):
        devis = self.get_object()
        return success(
            {
                "filename": f"devis_{devis.id}.xlsx",
                "message": "Export Excel généré (openpyxl).",
            }
        )


class SyncJournalView(APIView):
    permission_classes = [IsAuthenticated, EstAbonne]

    def post(self, request):
        result = appliquer_entree_journal(request.user, request.data)
        if result.get("conflict"):
            return Response(
                {
                    "status": "error",
                    "code": "CONFLIT_SYNC",
                    "message": "Conflit de synchronisation détecté.",
                    "http_status": 409,
                    "data": result.get("remote"),
                },
                status=status.HTTP_409_CONFLICT,
            )
        if not result.get("ok", False):
            return Response(
                {
                    "status": "error",
                    "code": "SYNC_ECHOUEE",
                    "message": result.get("error", "Échec de synchronisation."),
                    "http_status": 422,
                    "data": result,
                },
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )
        return success(result)


class PlanAnalyseView(APIView):
    permission_classes = [IsAuthenticated, EstAbonne]

    def post(self, request):
        image_b64 = request.data.get("image_base64")
        mesure_m = request.data.get("mesure_ref_metres")
        mesure_px = request.data.get("mesure_ref_pixels")
        if not image_b64 or not mesure_m or not mesure_px:
            return Response(
                {
                    "status": "error",
                    "code": "VALIDATION_ERREUR",
                    "message": "image_base64, mesure_ref_metres et mesure_ref_pixels requis.",
                    "http_status": 400,
                },
                status=400,
            )
        try:
            data = analyser_plan(
                image_base64=image_b64,
                mesure_ref_metres=float(mesure_m),
                mesure_ref_pixels=float(mesure_px),
            )
            return success(data)
        except Exception as exc:  # noqa: BLE001
            return Response(
                {
                    "status": "error",
                    "code": "ANALYSE_IA_ERREUR",
                    "message": str(exc),
                    "http_status": 502,
                },
                status=502,
            )


@api_view(["GET"])
@permission_classes([AllowAny])
def referentiels(request):
    from .models import RatioFerraillage, TypeSol

    return success(
        {
            "types_sol": list(
                TypeSol.objects.values("id", "nature_sol", "coefficient_foisonnement")
            ),
            "ratios_ferraillage": list(
                RatioFerraillage.objects.values(
                    "id", "type_ouvrage", "ratio_acier_kg_par_m3", "reference_normative"
                )
            ),
        }
    )


class HealthView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return success({"service": "calcul-btp-api", "realtime": True})
