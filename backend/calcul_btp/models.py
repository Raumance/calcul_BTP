import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


class Utilisateur(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    est_abonne = models.BooleanField(default=False)
    abonnement_expiration = models.DateTimeField(null=True, blank=True)
    cgu_acceptees = models.BooleanField(default=False)
    cgu_date_acceptation = models.DateTimeField(null=True, blank=True)

    def abonnement_actif(self) -> bool:
        if not self.est_abonne:
            return False
        if self.abonnement_expiration is None:
            return True
        from django.utils import timezone

        return self.abonnement_expiration >= timezone.now()


class Devise(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=3, unique=True)
    symbole = models.CharField(max_length=10)
    taux_conversion = models.DecimalField(max_digits=14, decimal_places=6, default=1)

    def __str__(self):
        return self.code


class TypeSol(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nature_sol = models.CharField(max_length=100)
    coefficient_foisonnement = models.FloatField()

    def __str__(self):
        return self.nature_sol


class RatioFerraillage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_ouvrage = models.CharField(max_length=50)
    ratio_acier_kg_par_m3 = models.FloatField()
    reference_normative = models.CharField(max_length=200)

    def __str__(self):
        return self.type_ouvrage


class Materiau(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    designation = models.CharField(max_length=200)
    unite = models.CharField(max_length=20)
    prix_unitaire_defaut = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    coefficient_perte_defaut = models.DecimalField(max_digits=5, decimal_places=4, default=0)

    def __str__(self):
        return self.designation


class Projet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    utilisateur = models.ForeignKey(
        Utilisateur, on_delete=models.CASCADE, related_name="projets"
    )
    nom = models.CharField(max_length=200)
    adresse_chantier = models.TextField(blank=True)
    nom_client = models.CharField(max_length=200, blank=True)
    devise_code = models.CharField(max_length=3, default="XOF")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["utilisateur", "-updated_at"]),
        ]

    def __str__(self):
        return self.nom


class Calcul(models.Model):
    TYPE_CHOICES = [
        ("terrassement", "Terrassement"),
        ("gros_oeuvre", "Gros œuvre"),
        ("cloison", "Cloison"),
        ("finition", "Finition"),
        ("electricite", "Électricité"),
    ]
    PHASE_CHOICES = [
        ("terrassement", "Terrassement"),
        ("fondation", "Fondation"),
        ("gros_oeuvre", "Gros œuvre"),
        ("finition", "Finition"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name="calculs")
    type_calcul = models.CharField(max_length=30, choices=TYPE_CHOICES)
    phase = models.CharField(max_length=30, choices=PHASE_CHOICES)
    parametres = models.JSONField()
    resultats = models.JSONField()
    reference_normative = models.CharField(max_length=200, blank=True)
    coefficient_perte = models.DecimalField(
        max_digits=5, decimal_places=4, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["projet", "-created_at"])]


class Devis(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name="devis")
    intitule = models.CharField(max_length=200)
    date_devis = models.DateField()
    devise_code = models.CharField(max_length=3)
    taux_conversion = models.DecimalField(max_digits=12, decimal_places=4, default=1)
    statut = models.CharField(max_length=30, default="brouillon")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class LigneDevis(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    devis = models.ForeignKey(Devis, on_delete=models.CASCADE, related_name="lignes")
    calcul = models.ForeignKey(
        Calcul, on_delete=models.SET_NULL, null=True, blank=True
    )
    designation = models.CharField(max_length=300)
    phase = models.CharField(max_length=30, choices=Calcul.PHASE_CHOICES)
    quantite = models.DecimalField(max_digits=14, decimal_places=4)
    unite = models.CharField(max_length=20)
    prix_unitaire = models.DecimalField(max_digits=14, decimal_places=2)
    coefficient_perte = models.DecimalField(max_digits=5, decimal_places=4, default=0)
    ordre = models.PositiveIntegerField()

    @property
    def total(self):
        return self.quantite * self.prix_unitaire


class Plan(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    projet = models.ForeignKey(Projet, on_delete=models.CASCADE, related_name="plans")
    phase = models.CharField(max_length=30, choices=Calcul.PHASE_CHOICES)
    image = models.ImageField(upload_to="plans/", blank=True)
    image_url = models.URLField(blank=True)
    echelle_metres_par_pixel = models.FloatField(null=True, blank=True)
    etalonnage_valide = models.BooleanField(default=False)
    analyse_ia_done = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class ElementPlan(models.Model):
    TYPE_CHOICES = [
        ("mur", "Mur"),
        ("ouverture", "Ouverture"),
        ("cote", "Cote"),
        ("surface", "Surface"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(Plan, on_delete=models.CASCADE, related_name="elements")
    type_element = models.CharField(max_length=20, choices=TYPE_CHOICES)
    geometrie = models.JSONField()
    valeur_metres = models.FloatField(null=True, blank=True)
    label = models.CharField(max_length=100, blank=True)
    ordre = models.PositiveIntegerField(default=0)
    est_valide = models.BooleanField(default=True)
    statut_validation = models.CharField(max_length=30, default="propose")
