from django.utils import timezone
from datetime import date, datetime

from ..models import Calcul, Devis, LigneDevis, Plan, Projet


def _parse_date(value) -> date:
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, str) and value:
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).date()
        except ValueError:
            pass
    return timezone.now().date()


def appliquer_entree_journal(user, data: dict) -> dict:
    """Applique une entrée du journal offline. Détecte les conflits 409."""
    entite_type = data.get("entite_type")
    entite_id = data.get("entite_id")
    operation = data.get("operation")
    payload = data.get("payload") or {}
    resolution = data.get("resolution")  # local | remote

    if entite_type == "Projet":
        return _sync_projet(user, entite_id, operation, payload, resolution)
    if entite_type == "Calcul":
        return _sync_calcul(user, entite_id, operation, payload, resolution)
    if entite_type == "Devis":
        return _sync_devis(user, entite_id, operation, payload, resolution)
    if entite_type == "Plan":
        return _sync_plan(user, entite_id, operation, payload)
    return {"ok": False, "error": "entite_inconnue"}


def _sync_projet(user, entite_id, operation, payload, resolution):
    existing = Projet.objects.filter(id=entite_id, utilisateur=user).first()
    client_updated = payload.get("updated_at")

    if operation == "DELETE":
        if existing:
            existing.delete()
        return {"ok": True}

    if existing and client_updated:
        remote_ts = existing.updated_at.isoformat()
        if client_updated < remote_ts and resolution != "local":
            return {
                "conflict": True,
                "remote": {
                    "id": str(existing.id),
                    "nom": existing.nom,
                    "updated_at": remote_ts,
                },
            }

    defaults = {
        "nom": payload.get("nom", "Projet"),
        "adresse_chantier": payload.get("adresse_chantier")
        or payload.get("adresse", ""),
        "nom_client": payload.get("nom_client") or payload.get("client", ""),
        "devise_code": payload.get("devise_code", "XOF"),
    }
    if existing:
        for k, v in defaults.items():
            setattr(existing, k, v)
        existing.save()
        return {"ok": True, "id": str(existing.id)}

    projet = Projet.objects.create(id=entite_id, utilisateur=user, **defaults)
    return {"ok": True, "id": str(projet.id)}


def _sync_calcul(user, entite_id, operation, payload, resolution):
    projet_id = payload.get("projet_id")
    projet = Projet.objects.filter(id=projet_id, utilisateur=user).first()
    if not projet:
        return {"ok": False, "error": "projet_introuvable"}

    existing = Calcul.objects.filter(id=entite_id, projet=projet).first()
    if operation == "DELETE":
        if existing:
            existing.delete()
        return {"ok": True}

    defaults = {
        "type_calcul": payload.get("type_calcul", "gros_oeuvre"),
        "phase": payload.get("phase", "gros_oeuvre"),
        "parametres": payload.get("parametres", {}),
        "resultats": payload.get("resultats", {}),
        "reference_normative": payload.get("reference_normative", ""),
    }
    if existing:
        for k, v in defaults.items():
            setattr(existing, k, v)
        existing.save()
        return {"ok": True, "id": str(existing.id)}

    calcul = Calcul.objects.create(id=entite_id, projet=projet, **defaults)
    return {"ok": True, "id": str(calcul.id)}


def _sync_devis(user, entite_id, operation, payload, resolution):
    projet_id = payload.get("projet_id")
    projet = Projet.objects.filter(id=projet_id, utilisateur=user).first()
    if not projet:
        return {"ok": False, "error": "projet_introuvable"}

    existing = Devis.objects.filter(id=entite_id, projet=projet).first()
    if operation == "DELETE":
        if existing:
            existing.delete()
        return {"ok": True}

    if existing and resolution != "local":
        remote_ts = existing.updated_at.isoformat()
        client_ts = payload.get("updated_at")
        if client_ts and client_ts < remote_ts:
            return {
                "conflict": True,
                "remote": {
                    "id": str(existing.id),
                    "intitule": existing.intitule,
                    "updated_at": remote_ts,
                },
            }

    defaults = {
        "intitule": payload.get("intitule", "Devis"),
        "date_devis": _parse_date(payload.get("date_devis")),
        "devise_code": payload.get("devise_code", "XOF"),
        "taux_conversion": payload.get("taux_conversion", 1),
        "statut": payload.get("statut", "brouillon"),
    }
    if existing:
        for k, v in defaults.items():
            setattr(existing, k, v)
        existing.save()
        devis = existing
    else:
        devis = Devis.objects.create(id=entite_id, projet=projet, **defaults)

    lignes = payload.get("lignes") or []
    if lignes:
        devis.lignes.all().delete()
        for i, ligne in enumerate(lignes):
            LigneDevis.objects.create(
                devis=devis,
                designation=ligne.get("designation", ""),
                phase=ligne.get("phase", "finition"),
                quantite=ligne.get("quantite", 0),
                unite=ligne.get("unite", ""),
                prix_unitaire=ligne.get("prix_unitaire", 0),
                coefficient_perte=ligne.get("coefficient_perte", 0),
                ordre=ligne.get("ordre", i + 1),
            )
    return {"ok": True, "id": str(devis.id)}


def _sync_plan(user, entite_id, operation, payload):
    projet_id = payload.get("projet_id")
    projet = Projet.objects.filter(id=projet_id, utilisateur=user).first()
    if not projet:
        return {"ok": False, "error": "projet_introuvable"}

    existing = Plan.objects.filter(id=entite_id, projet=projet).first()
    if operation == "DELETE":
        if existing:
            existing.delete()
        return {"ok": True}

    phase = payload.get("phase", "gros_oeuvre")
    echelle = payload.get("echelle") or payload.get("echelle_metres_par_pixel")
    defaults = {
        "phase": phase,
        "image_url": payload.get("image_path") or payload.get("image_url") or "",
        "echelle_metres_par_pixel": echelle,
        "etalonnage_valide": True if echelle else False,
        "analyse_ia_done": bool(payload.get("segments")),
    }
    if existing:
        for k, v in defaults.items():
            setattr(existing, k, v)
        existing.save()
        return {"ok": True, "id": str(existing.id)}

    plan = Plan.objects.create(id=entite_id, projet=projet, **defaults)
    return {"ok": True, "id": str(plan.id)}
