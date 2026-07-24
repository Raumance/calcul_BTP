"""Analyse de plan via modèle multimodal — clé API côté serveur uniquement."""

from __future__ import annotations

import json
from typing import Any

from django.conf import settings


def analyser_plan(
    *,
    image_base64: str,
    mesure_ref_metres: float,
    mesure_ref_pixels: float,
) -> dict[str, Any]:
    if mesure_ref_pixels <= 0 or mesure_ref_metres <= 0:
        raise ValueError("Mesure de référence invalide.")

    echelle = mesure_ref_metres / mesure_ref_pixels

    # Sans clé API : proposition de démo pour développement local.
    if not settings.ANTHROPIC_API_KEY:
        return {
            "segments": [
                {
                    "type": "mur",
                    "x1": 80,
                    "y1": 120,
                    "x2": 80 + mesure_ref_pixels,
                    "y2": 120,
                    "valeur_metres": mesure_ref_metres,
                    "label": "Référence",
                },
                {
                    "type": "mur",
                    "x1": 80,
                    "y1": 120,
                    "x2": 80,
                    "y2": 320,
                    "valeur_metres": round(200 * echelle, 2),
                    "label": "Mur Est",
                },
            ],
            "echelle_metres_par_pixel": echelle,
            "confiance": 0.5,
            "mode": "demo_sans_cle_ia",
        }

    # Intégration réelle : appeler l'API multimodale avec retour JSON strict.
    # La clé ne quitte jamais le serveur.
    try:
        import httpx

        prompt = (
            "Analyse ce plan de bâtiment. Retourne UNIQUEMENT un JSON "
            '{"segments":[{"type":"mur|ouverture|cote|surface","x1":0,"y1":0,'
            '"x2":0,"y2":0,"valeur_metres":null,"label":""}],'
            '"confiance":0.0}. Coordonnées en pixels image.'
        )
        # Placeholder structure — à brancher sur le provider choisi.
        _ = (httpx, prompt, image_base64, json)
        return {
            "segments": [],
            "echelle_metres_par_pixel": echelle,
            "confiance": 0.0,
            "mode": "api_configuree",
            "message": "Branchez le provider multimodal (Claude/Gemini) ici.",
        }
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(f"Échec analyse IA: {exc}") from exc
