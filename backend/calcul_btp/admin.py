from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import (
    Calcul,
    Devis,
    ElementPlan,
    LigneDevis,
    Materiau,
    Plan,
    Projet,
    RatioFerraillage,
    TypeSol,
    Utilisateur,
)


@admin.register(Utilisateur)
class UtilisateurAdmin(UserAdmin):
    list_display = ("email", "first_name", "est_abonne", "is_staff")
    fieldsets = UserAdmin.fieldsets + (
        (
            "Abonnement",
            {"fields": ("est_abonne", "abonnement_expiration", "cgu_acceptees")},
        ),
    )


@admin.register(Materiau)
class MateriauAdmin(admin.ModelAdmin):
    list_display = ("designation", "unite", "prix_unitaire_defaut")
    search_fields = ("designation",)


admin.site.register(Projet)
admin.site.register(Calcul)
admin.site.register(Devis)
admin.site.register(LigneDevis)
admin.site.register(Plan)
admin.site.register(ElementPlan)
admin.site.register(TypeSol)
admin.site.register(RatioFerraillage)
