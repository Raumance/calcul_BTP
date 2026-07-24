from dataclasses import dataclass
from typing import Literal

SECTIONS_NORMALISEES = [1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0]
CALIBRES_NORMALISES = [10, 16, 20, 25, 32, 40, 63]
RHO = {"cuivre": 0.0225, "aluminium": 0.036}


@dataclass(frozen=True)
class ResultatCalcul:
    valeur_principale: float
    unite: str
    details: dict
    reference_normative: str
    avertissement: str = (
        "Résultats fournis à titre indicatif. "
        "Ne remplacent pas l'avis d'un professionnel qualifié."
    )


def calculer_section_cable(
    puissance_w: float,
    longueur_m: float,
    tension_v: float,
    conducteur: Literal["cuivre", "aluminium"],
    facteur_puissance: float = 0.8,
    chute_admissible: float = 0.03,
) -> ResultatCalcul:
    rho = RHO[conducteur]
    intensite = puissance_w / (tension_v * facteur_puissance)
    chute_max = chute_admissible * tension_v
    section_calc = (2 * rho * longueur_m * intensite) / chute_max
    section_norm = next(
        (s for s in SECTIONS_NORMALISEES if s >= section_calc),
        SECTIONS_NORMALISEES[-1],
    )
    return ResultatCalcul(
        valeur_principale=section_norm,
        unite="mm²",
        details={
            "section_calculee": section_calc,
            "intensite_A": intensite,
            "conducteur": conducteur,
        },
        reference_normative="NF C 15-100",
    )
