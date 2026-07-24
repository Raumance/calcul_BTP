# Calculs BTP

Application multiplateforme de **quantitatifs et devis** pour le bâtiment.

**Dépôt :** [github.com/Raumance/calcul_BTP](https://github.com/Raumance/calcul_BTP)

## Architecture

| Couche | Techno |
|--------|--------|
| Client | Flutter (Android, iOS, Windows, Linux, macOS) · Riverpod · Dio · WebSocket |
| API | Django REST + SimpleJWT + Channels (Daphne) |
| Données | PostgreSQL · Redis |
| Calculs | Moteur Dart offline (&lt; 200 ms) + sync multi-appareils |
| Prod | Docker Compose (image Chainguard) |

## Démarrage rapide

### Client Flutter

```bash
flutter pub get
flutter test
flutter run -d windows   # ou android / chrome
```

Compte démo (si seed local) : voir la doc d’équipe — ne pas committer de mots de passe.

### Backend

```bash
cd backend
python -m venv .venv
.\.venv\Scripts\activate          # Windows
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py seed_referentiels
python manage.py test calcul_btp.tests
python -m daphne -b 127.0.0.1 -p 8000 config.asgi:application
```

Health : `GET http://127.0.0.1:8000/api/health/`

PostgreSQL Docker (port hôte **55432**) :

```bash
docker compose up -d db redis
```

### Stack Docker complète

```bash
docker compose up --build
```

API `:8000` · Postgres `:55432` · Redis `:6379`

## Temps réel & sync

- WebSocket : `ws://host/ws/sync/<projet_id>/?token=<JWT>`
- Journal offline : `POST /api/sync/journal/` (abonnement requis)
- Conflits : HTTP 409 · échecs métier : HTTP 422

## Modules

- [x] Terrassement, gros œuvre, cloisons, finitions, électricité NF C 15-100
- [x] Devis multi-phases / multi-devises (FCFA / EUR) + exports PDF / Excel / CSV
- [x] Auth JWT, offline local, sync, analyse de plan
- [x] UI responsive (mobile bottom nav / desktop sidebar)
- [x] CGU + garde-fous production (`SECRET_KEY`)

## Avertissement

Les résultats sont **indicatifs** (quantitatifs estimatifs). Ils ne constituent pas un dimensionnement structurel certifié.
