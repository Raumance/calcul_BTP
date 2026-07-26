"""Analyse de plan via modèle multimodal — clé API côté serveur uniquement."""

from __future__ import annotations

import hashlib
import json
from typing import Any

from django.conf import settings
from django.core.cache import cache


def analyser_plan(
    *,
    image_base64: str,
    mesure_ref_metres: float,
    mesure_ref_pixels: float,
) -> dict[str, Any]:
    if mesure_ref_pixels <= 0 or mesure_ref_metres <= 0:
        raise ValueError("Mesure de référence invalide.")

    # 1. Calcul de l'empreinte de l'image pour le cache
    # Cela évite de payer et d'attendre une analyse IA pour la même image.
    image_hash = hashlib.md5(image_base64.encode()).hexdigest()
    cache_key = f"plan_ia_analysis_{image_hash}"

    cached_data = cache.get(cache_key)
    if cached_data:
        # Si trouvé en cache, on recalcule seulement l'échelle car
        # l'utilisateur peut avoir changé son étalonnage sur la même image.
        echelle = mesure_ref_metres / mesure_ref_pixels
        cached_data["echelle_metres_par_pixel"] = echelle
        # On met à jour la valeur_metres des segments en fonction de la nouvelle échelle
        for seg in cached_data.get("segments", []):
            if seg.get("x1") is not None and seg.get("x2") is not None:
                dist_px = ((seg["x2"] - seg["x1"])**2 + (seg["y2"] - seg["y1"])**2)**0.5
                seg["valeur_metres"] = round(dist_px * echelle, 2)

        cached_data["mode"] = f"{cached_data.get('mode', 'api')}_cache_hit"
        return cached_data

    echelle = mesure_ref_metres / mesure_ref_pixels

    # Sans clé API : proposition de démo pour développement local.
    if not settings.ANTHROPIC_API_KEY:
        result = {
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
        # On ne cache pas forcément la démo, mais on peut le faire pour tester le mécanisme
        cache.set(cache_key, result, timeout=3600)  # Cache 1h pour la démo
        return result

    # Intégration réelle : appeler l'API multimodale avec retour JSON strict.
    try:
        import httpx

        prompt = (
            "Analyse ce plan de bâtiment. Retourne UNIQUEMENT un JSON "
            '{"segments":[{"type":"mur|ouverture|cote|surface","x1":0,"y1":0,'
            '"x2":0,"y2":0,"valeur_metres":null,"label":""}],'
            '"confiance":0.0}. Coordonnées en pixels image.'
        )

        # Simulation d'appel IA (à remplacer par l'appel réel au provider)
        # result = call_multimodal_api(prompt, image_base64)

        result = {
            "segments": [],
            "echelle_metres_par_pixel": echelle,
            "confiance": 0.0,
            "mode": "api_configuree",
            "message": "Branchez le provider multimodal (Claude/Gemini) ici.",
        }

        # Mise en cache du résultat réel (24h)
        if result["segments"]:
            cache.set(cache_key, result, timeout=86400)

        return result
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(f"Échec analyse IA: {exc}") from exc
