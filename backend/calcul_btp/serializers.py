import bleach
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Calcul, Devis, LigneDevis, Projet

User = get_user_model()


def clean_text(value: str) -> str:
    return bleach.clean(value or "", tags=[], strip=True)


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    nom = serializers.CharField(max_length=150, required=False, allow_blank=True)
    cgu_acceptees = serializers.BooleanField()

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Un compte existe déjà avec cet email.")
        return value.lower()

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate_cgu_acceptees(self, value):
        if not value:
            raise serializers.ValidationError("Les CGU doivent être acceptées.")
        return value

    def create(self, validated_data):
        email = validated_data["email"]
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data["password"],
            first_name=clean_text(validated_data.get("nom", "")),
            cgu_acceptees=True,
            cgu_date_acceptation=timezone.now(),
        )
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs["email"].lower()
        user = authenticate(
            username=email,
            password=attrs["password"],
        )
        if user is None:
            # Message générique — ne pas distinguer email / mot de passe.
            raise serializers.ValidationError(
                {
                    "status": "error",
                    "code": "IDENTIFIANTS_INCORRECTS",
                    "message": "Identifiants incorrects.",
                }
            )
        attrs["user"] = user
        return attrs


class ProjetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Projet
        fields = [
            "id",
            "nom",
            "adresse_chantier",
            "nom_client",
            "devise_code",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_nom(self, value):
        return clean_text(value)

    def validate_adresse_chantier(self, value):
        return clean_text(value)

    def validate_nom_client(self, value):
        return clean_text(value)


class CalculSerializer(serializers.ModelSerializer):
    class Meta:
        model = Calcul
        fields = [
            "id",
            "type_calcul",
            "phase",
            "parametres",
            "resultats",
            "reference_normative",
            "coefficient_perte",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class LigneDevisSerializer(serializers.ModelSerializer):
    total = serializers.DecimalField(
        max_digits=16, decimal_places=2, read_only=True
    )

    class Meta:
        model = LigneDevis
        fields = [
            "id",
            "calcul",
            "designation",
            "phase",
            "quantite",
            "unite",
            "prix_unitaire",
            "coefficient_perte",
            "ordre",
            "total",
        ]
        read_only_fields = ["id", "total"]

    def validate_designation(self, value):
        return clean_text(value)


class DevisSerializer(serializers.ModelSerializer):
    lignes = LigneDevisSerializer(many=True, required=False)

    class Meta:
        model = Devis
        fields = [
            "id",
            "intitule",
            "date_devis",
            "devise_code",
            "taux_conversion",
            "statut",
            "lignes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def create(self, validated_data):
        lignes_data = validated_data.pop("lignes", [])
        devis = Devis.objects.create(**validated_data)
        for i, ligne in enumerate(lignes_data):
            ordre = ligne.pop("ordre", i + 1)
            LigneDevis.objects.create(devis=devis, ordre=ordre, **ligne)
        return devis


def tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": {
            "id": str(user.id),
            "email": user.email,
            "nom": user.first_name,
            "est_abonne": user.abonnement_actif(),
        },
    }
