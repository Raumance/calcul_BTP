from dataclasses import dataclass


DISCLAIMER = (
    "Résultats fournis à titre indicatif. "
    "Ne remplacent pas l'avis d'un professionnel qualifié."
)

COEFFICIENTS_FOISONNEMENT = {
    "terre_vegetale": 1.25,
    "argile": 1.30,
    "sable": 1.10,
    "roche": 1.50,
}


@dataclass(frozen=True)
class ResultatCalcul:
    valeur_principale: float
    unite: str
    details: dict
    reference_normative: str
    avertissement: str = DISCLAIMER


def calculer_deblai(
    longueur: float,
    largeur: float,
    profondeur: float,
    type_sol: str,
) -> ResultatCalcul:
    assert longueur > 0 and largeur > 0 and profondeur > 0
    coeff = COEFFICIENTS_FOISONNEMENT[type_sol]
    volume_en_place = longueur * largeur * profondeur
    return ResultatCalcul(
        valeur_principale=volume_en_place * coeff,
        unite="m³",
        details={
            "volume_en_place": volume_en_place,
            "coefficient_foisonnement": coeff,
            "type_sol": type_sol,
        },
        reference_normative="DTU 12.1",
    )


def volume_beton(
    longueur: float,
    largeur: float,
    epaisseur: float,
    coefficient_perte: float = 0.03,
) -> ResultatCalcul:
    assert longueur > 0 and largeur > 0 and epaisseur > 0
    volume_net = longueur * largeur * epaisseur
    return ResultatCalcul(
        valeur_principale=volume_net * (1 + coefficient_perte),
        unite="m³",
        details={"volume_net": volume_net, "coefficient_perte": coefficient_perte},
        reference_normative="DTU 21, BAEL 91 rev. 99 / Eurocode 2",
    )
