from django.core.management.base import BaseCommand

from calcul_btp.models import Materiau, RatioFerraillage, TypeSol


class Command(BaseCommand):
    help = "Charge les référentiels BTP (sols, ferraillage, matériaux)."

    def handle(self, *args, **options):
        sols = [
            ("Terre végétale", 1.25),
            ("Argile", 1.30),
            ("Sable", 1.10),
            ("Roche", 1.50),
        ]
        for libelle, coeff in sols:
            TypeSol.objects.get_or_create(
                nature_sol=libelle,
                defaults={"coefficient_foisonnement": coeff},
            )

        ratios = [
            ("fondation_superficielle", 60, "BAEL 91 / EC2 — fondations"),
            ("poteau", 120, "BAEL 91 / EC2 — poteaux"),
            ("poutre", 100, "BAEL 91 / EC2 — poutres"),
            ("dalle", 80, "BAEL 91 / EC2 — dalles"),
        ]
        for typ, val, ref in ratios:
            RatioFerraillage.objects.get_or_create(
                type_ouvrage=typ,
                defaults={
                    "ratio_acier_kg_par_m3": val,
                    "reference_normative": ref,
                },
            )

        materiaux = [
            ("Béton C25/30", "m³", 85000, 0.03),
            ("Parpaing 20×20×50", "unités", 450, 0.05),
            ("Mortier", "m³", 65000, 0.05),
            ("Acier HA", "kg", 800, 0),
            ("Peinture acrylique", "m²", 2500, 0.10),
            ("Carrelage sol", "m²", 12000, 0.10),
        ]
        for des, unite, prix, perte in materiaux:
            Materiau.objects.get_or_create(
                designation=des,
                defaults={
                    "unite": unite,
                    "prix_unitaire_defaut": prix,
                    "coefficient_perte_defaut": perte,
                },
            )

        self.stdout.write(self.style.SUCCESS("Référentiels chargés."))
