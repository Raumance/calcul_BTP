# Plan d'Implémentation : btp-calcul-app

## Vue d'ensemble

Implémentation d'une application Flutter multiplateforme BTP (Android, iOS, Windows, Linux, macOS) avec backend Django + PostgreSQL. L'application couvre les calculs de quantitatifs (terrassement, gros œuvre, cloisons, finitions, électricité NF C 15-100), la gestion de devis, l'analyse de plans par IA, la synchronisation offline/online et un modèle freemium.

Stack : Flutter/Dart + Riverpod + Drift + Django DRF + PostgreSQL

---

## Tâches

- [ ] 1. Mise en place du projet et de la structure de base
  - [ ] 1.1 Configurer les dépendances Flutter (pubspec.yaml)
    - Ajouter : `flutter_riverpod`, `riverpod_annotation`, `drift`, `drift_flutter`, `flutter_secure_storage`, `dio`, `go_router`, `intl`, `image_picker`, `pdf`, `excel`, `uuid`, `connectivity_plus`, `json_annotation`, `freezed_annotation`
    - Ajouter en dev : `build_runner`, `drift_dev`, `riverpod_generator`, `freezed`, `json_serializable`
    - _Exigences : 14.2, 10.4, 13.5_

  - [ ] 1.2 Créer la structure de dossiers Flutter selon le design
    - Créer les dossiers `lib/core/`, `lib/features/`, `lib/shared/` avec sous-dossiers par feature (auth, calcul, devis, plan, projet, settings)
    - Créer `lib/core/constants/app_colors.dart`, `app_typography.dart`, `normative_refs.dart`
    - Créer `lib/core/errors/failures.dart`, `exceptions.dart`
    - _Exigences : 13.1, 13.2, 13.3_

  - [ ] 1.3 Initialiser la base de données Drift avec toutes les tables
    - Créer les tables : `Utilisateurs`, `Projets`, `Calculs`, `Devis`, `LignesDevis`, `Materiaux`, `Plans`, `ElementsPlan`, `JournalSync`, `TypesSol`, `RatiosFerraillage`
    - Créer `lib/shared/database/app_database.dart` avec `@DriftDatabase` incluant toutes les tables
    - Créer `lib/shared/database/sync_journal.dart`
    - _Exigences : 15.1, 15.5_

  - [ ]* 1.4 Écrire les tests unitaires de la base de données Drift (round-trip)
    - **Property 11 : Persistance locale round-trip**
    - **Validates : Exigences 15.1, 7.10, 9.3**

  - [ ] 1.5 Implémenter le client HTTP avec intercepteur JWT
    - Créer `lib/core/network/api_client.dart` avec `Dio` + `JwtInterceptor`
    - Implémenter le refresh automatique du token et la gestion des erreurs (401, 403, 409, 502)
    - Créer `lib/core/network/connectivity_service.dart`
    - _Exigences : 14.2, 10.1, 10.2, 10.7_

  - [ ] 1.6 Implémenter les utilitaires core (formatage, validateurs, freemium guard)
    - Créer `lib/core/utils/number_formatter.dart` (FCFA/EUR, locale)
    - Créer `lib/core/utils/validators.dart`
    - Créer `lib/core/utils/freemium_guard.dart`
    - _Exigences : 12.1, 12.5, 11.4_

- [ ] 2. Backend Django — Modèles, migrations et authentification
  - [ ] 2.1 Initialiser le projet Django avec les dépendances backend
    - Créer le projet Django `backend/`, installer : `djangorestframework`, `djangorestframework-simplejwt`, `django-argon2`, `psycopg2-binary`, `python-decouple`, `bleach`, `Pillow`, `openpyxl`, `reportlab`
    - Configurer `settings.py` : PostgreSQL, CORS, JWT (access 1h, refresh 7j), argon2 password hasher
    - _Exigences : 10.1, 10.2, 14.3, 14.4_

  - [ ] 2.2 Créer les modèles Django et migrations PostgreSQL
    - Implémenter `Utilisateur`, `Projet`, `Calcul`, `Devis`, `LigneDevis`, `Plan`, `ElementPlan` dans `backend/calcul_btp/models.py`
    - Générer et appliquer les migrations, ajouter les indexes sur `projet_id`, `created_at`
    - _Exigences : 15.2, 15.3, 15.4_

  - [ ] 2.3 Implémenter l'authentification JWT (register, login, refresh, logout)
    - Créer les views `RegisterView`, `LoginView` (avec message d'erreur générique), logout avec blacklist du refresh token
    - Configurer les URLs `/api/auth/register/`, `/api/auth/login/`, `/api/auth/token/refresh/`, `/api/auth/logout/`
    - Implémenter la validation du mot de passe (≥ 8 chars, 1 maj, 1 min, 1 chiffre)
    - _Exigences : 10.1, 10.2, 10.3, 10.5, 10.6_

  - [ ]* 2.4 Écrire les tests unitaires backend — authentification et validation mot de passe
    - **Property 14 : Validation du mot de passe à la création de compte**
    - **Validates : Exigences 10.6**

  - [ ] 2.5 Créer les serializers DRF et les API projets/calculs
    - Créer les serializers pour `Projet`, `Calcul`, `Devis`, `LigneDevis`, `Plan`, `ElementPlan`
    - Implémenter les ViewSets pour `/api/projets/`, `/api/projets/{id}/calculs/`, `/api/projets/{id}/devis/`
    - Valider et assainir toutes les entrées avec `bleach`
    - _Exigences : 14.4, 15.2, 9.1, 9.2_

  - [ ] 2.6 Implémenter la permission `EstAbonne` et les endpoints avancés
    - Créer `backend/calcul_btp/permissions.py` avec `EstAbonne`
    - Appliquer la permission sur : `/api/plans/analyse/`, `/api/devis/{id}/export/pdf/`, `/api/devis/{id}/export/excel/`, `/api/sync/journal/`
    - Retourner HTTP 403 avec code `ABONNEMENT_REQUIS` si abonnement inactif/expiré
    - _Exigences : 11.5, 11.6_

  - [ ]* 2.7 Écrire les tests unitaires backend — contrôle d'accès freemium
    - **Property 13 : Contrôle d'accès freemium côté backend**
    - **Validates : Exigences 11.5**

- [ ] 3. Checkpoint — Structure de base
  - Vérifier que la base Drift se crée sans erreur, que le client HTTP se connecte au backend, que le JWT s'obtient et se rafraîchit correctement. Demander à l'utilisateur s'il a des questions.

- [ ] 4. Moteur de calcul Dart — Terrassement et Gros Œuvre
  - [ ] 4.1 Implémenter les modèles domaine du moteur de calcul
    - Créer `lib/features/calcul/domain/models/calcul_result.dart` (classe `CalculResult` avec `valeurPrincipale`, `unite`, `details`, `referenceNormative`, `avertissement`)
    - Créer `lib/features/calcul/domain/models/type_sol.dart` avec les 4 types par défaut (terreVegetale 1.25, argile 1.30, sable 1.10, roche 1.50)
    - Créer `lib/features/calcul/domain/models/ratio_ferraillage.dart`
    - _Exigences : 1.4, 2.4, 6.1_

  - [ ] 4.2 Implémenter `TerrassementEngine` (déblai, remblai)
    - Créer `lib/features/calcul/domain/moteur/terrassement_engine.dart`
    - Implémenter `deblai()` et `remblai()` avec formule V = L × l × h × coeff_foisonnement, référence DTU 12.1
    - _Exigences : 1.1, 1.2, 1.3, 1.5, 1.8_

  - [ ]* 4.3 Écrire les tests de propriété pour TerrassementEngine
    - **Property 1 : Formule de volume terrassement**
    - **Validates : Exigences 1.1, 1.2, 1.3**
    - **Property 2 : Cohérence du coefficient de foisonnement à la mise à jour**
    - **Validates : Exigences 1.6**

  - [ ] 4.4 Implémenter `GrosOeuvreEngine` (béton, parpaings, mortier, acier)
    - Créer `lib/features/calcul/domain/moteur/gros_oeuvre_engine.dart`
    - Implémenter `volumeBeton()`, `nombreParpaings()`, `volumeMortier()`, `quantiteAcier()`
    - Références : DTU 21, BAEL 91 / Eurocode 2
    - _Exigences : 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 2.9_

  - [ ]* 4.5 Écrire les tests de propriété pour GrosOeuvreEngine
    - **Property 3 : Formule de volume béton avec perte**
    - **Validates : Exigences 2.1, 2.5**
    - **Property 4 : Nombre de parpaings avec perte borné**
    - **Validates : Exigences 2.2**
    - **Property 5 : Quantité d'acier proportionnelle au volume**
    - **Validates : Exigences 2.4**

  - [ ] 4.6 Implémenter `CloisonsEngine` (cloisons, doublages, plafonds)
    - Créer `lib/features/calcul/domain/moteur/cloisons_engine.dart`
    - Implémenter `surfaceCloison()`, `surfaceDoublage()`, `surfacePlafond()` avec coefficient de perte 10% par défaut
    - Références : DTU 25.41, DTU 58.1
    - _Exigences : 3.1, 3.2, 3.3, 3.4, 3.7_

  - [ ] 4.7 Implémenter `FinitionsEngine` (peinture, papier peint, carrelage)
    - Créer `lib/features/calcul/domain/moteur/finitions_engine.dart`
    - Implémenter `surfacePeinture()` avec déduction ouvertures, `nombreRouleaux()`, `surfaceCarrelage()`
    - Références : DTU 59.1, DTU 59.4, DTU 52.1
    - _Exigences : 4.1, 4.2, 4.3, 4.6_

  - [ ]* 4.8 Écrire les tests de propriété pour FinitionsEngine
    - **Property 15 : Surface à peindre = surface totale − déduction ouvertures**
    - **Validates : Exigences 4.1**

  - [ ] 4.9 Implémenter `ElectriciteEngine` (bilan puissance, section câble, calibre disjoncteur)
    - Créer `lib/features/calcul/domain/moteur/electricite_engine.dart`
    - Implémenter `bilanPuissance()`, `sectionCable()` (formule chute de tension 3%), `calibreDisjoncteur()`, `pointsLumineux()`
    - Sections câbles normalisées : {1.5, 2.5, 4.0, 6.0, 10.0, 16.0, 25.0} mm²
    - Calibres normalisés : {10, 16, 20, 25, 32, 40, 63} A
    - Référence : NF C 15-100
    - _Exigences : 5.1, 5.2, 5.3, 5.4, 5.5, 5.7_

  - [ ]* 4.10 Écrire les tests de propriété pour ElectriciteEngine
    - **Property 7 : Bilan de puissance électrique = somme des circuits**
    - **Validates : Exigences 5.1**
    - **Property 8 : Section de câble normalisée ≥ section calculée**
    - **Validates : Exigences 5.2, 5.3**

  - [ ]* 4.11 Écrire les tests de propriété — référence normative présente dans tous les résultats
    - **Property 6 : Référence normative toujours présente dans les résultats**
    - **Validates : Exigences 1.5, 2.7, 5.5, 6.1**

- [ ] 5. Moteur de calcul Python (backend Django)
  - [ ] 5.1 Implémenter le moteur Python terrassement et gros œuvre
    - Créer `backend/calcul_btp/moteur/terrassement.py` et `gros_oeuvre.py`
    - Implémenter les mêmes formules qu'en Dart pour validation de cohérence
    - _Exigences : 1.1, 1.2, 1.3, 2.1, 2.2, 2.4_

  - [ ] 5.2 Implémenter le moteur Python électricité et finitions
    - Créer `backend/calcul_btp/moteur/electricite.py`, `finitions.py`, `cloisons.py`
    - _Exigences : 5.1, 5.2, 4.1, 3.1_

  - [ ]* 5.3 Écrire les tests unitaires du moteur Python
    - Tester chaque moteur avec les mêmes cas que les tests Dart (parité des résultats)
    - _Exigences : 1.8, 2.9, 3.7, 4.6, 5.7_

- [ ] 6. Checkpoint — Moteur de calcul
  - Vérifier que tous les moteurs Dart et Python produisent des résultats cohérents sur les mêmes entrées, que les tests passent, et que chaque résultat contient la référence normative. Demander à l'utilisateur s'il a des questions.

- [ ] 7. Gestion d'état Riverpod et repositories calcul
  - [ ] 7.1 Implémenter les providers Riverpod du module calcul
    - Créer `lib/features/calcul/presentation/providers/calcul_providers.dart`
    - Implémenter `TerrassementNotifier`, `GrosOeuvreNotifier`, `CloisonsNotifier`, `FinitionsNotifier`, `ElectriciteNotifier` comme `StateNotifierProvider`
    - Implémenter `connectivityProvider` et `authStateProvider`
    - _Exigences : 1.6, 13.6_

  - [ ] 7.2 Implémenter le repository calcul (persistance Drift + sync journal)
    - Créer `lib/features/calcul/data/calcul_repository_impl.dart`
    - Persister chaque calcul dans la table `Calculs` avec `projetId`, `typeCalcul`, `phase`, `parametresJson`, `resultatsJson`
    - Enregistrer chaque sauvegarde dans `JournalSync`
    - _Exigences : 15.3, 15.5, 9.2_

  - [ ]* 7.3 Écrire les tests unitaires des providers calcul
    - Tester que les notifiers produisent les états attendus (loading, data, error)
    - _Exigences : 1.8, 14.1_

- [ ] 8. UI — Écrans de calcul (terrassement, gros œuvre, cloisons, finitions, électricité)
  - [ ] 8.1 Créer les widgets partagés (NormativeBadge, DisclaimerBanner, boutons 48dp)
    - Créer `lib/shared/widgets/normative_badge.dart`
    - Créer `lib/shared/widgets/disclaimer_banner.dart`
    - Respecter les contraintes WCAG 2.1 AA : hauteur/largeur ≥ 48dp, contraste ≥ 4.5:1, police résultats ≥ 16sp
    - _Exigences : 6.1, 13.1, 13.2, 13.3_

  - [ ] 8.2 Créer l'écran de calcul terrassement
    - Formulaire de saisie (longueur, largeur, profondeur, sélection TypeSol)
    - Recalcul immédiat à la modification du coefficient de foisonnement
    - Affichage résultat avec `NormativeBadge` (DTU 12.1) et `DisclaimerBanner`
    - Bouton "Ajouter au devis"
    - _Exigences : 1.1, 1.2, 1.3, 1.5, 1.6, 1.7_

  - [ ] 8.3 Créer l'écran de calcul gros œuvre
    - Formulaire multi-sections (béton dalle, parpaings, mortier, ferraillage)
    - Affichage `RatioFerraillage` de référence BAEL/Eurocodes à la sélection du type d'élément
    - Coefficients de perte modifiables (béton 3%, parpaings 5%)
    - _Exigences : 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [ ] 8.4 Créer les écrans de calcul cloisons/plafonds et finitions
    - Écran cloisons : formulaire dimensions pièce, type matériau, coefficient de perte (10%)
    - Écran finitions : formulaire peinture (avec liste ouvertures), papier peint, carrelage
    - Recalcul immédiat à la modification du coefficient de perte
    - _Exigences : 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ] 8.5 Créer l'écran de calcul électrique NF C 15-100
    - Formulaire : liste circuits (désignation, puissance, longueur), tension, conducteur
    - Affichage bilan puissance, section câble, calibre disjoncteur, points lumineux recommandés
    - Badge NF C 15-100 sur chaque résultat
    - _Exigences : 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9. Module Devis — Modèle, logique et export
  - [ ] 9.1 Implémenter les modèles domaine du module Devis
    - Créer `lib/features/devis/domain/models/devis.dart` (`DevisModel`, `LigneDevisModel`)
    - Implémenter `lignesParPhase`, `sousTotauxParPhase`, `totalGeneral`, `convertir()`
    - Créer `lib/features/devis/domain/models/materiau.dart`
    - _Exigences : 7.1, 7.2, 7.3, 7.5_

  - [ ]* 9.2 Écrire les tests de propriété pour les totaux de Devis
    - **Property 9 : Invariant de cohérence des totaux de devis**
    - **Validates : Exigences 7.2, 7.3**
    - **Property 10 : Conversion de devise préserve les proportions**
    - **Validates : Exigences 7.6, 12.3**

  - [ ] 9.3 Implémenter le repository Devis (CRUD Drift + journal de sync)
    - Créer `lib/features/devis/data/` avec repository qui persiste `Devis` et `LignesDevis` dans Drift
    - Ajouter chaque modification au `JournalSync`
    - _Exigences : 7.10, 15.1, 15.5_

  - [ ] 9.4 Implémenter les providers Riverpod du module Devis
    - Providers : liste devis, devis actif, ajout de ligne depuis résultat calcul, modification taux de conversion
    - Recalcul immédiat des totaux lors du changement de devise
    - _Exigences : 7.2, 7.4, 7.6_

  - [ ] 9.5 Implémenter `DevisExportService` (PDF + Excel)
    - Créer `lib/features/devis/domain/services/devis_export_service.dart`
    - PDF : entête, tableau lignes par phase, sous-totaux, total général, clause de non-responsabilité
    - Excel : formules conservées, feuille de calcul avec SUM
    - Vérification `FreemiumGuard` avant export
    - _Exigences : 7.7, 7.8, 11.3, 11.4_

  - [ ] 9.6 Créer les écrans UI du module Devis
    - Écran liste devis d'un projet, écran création/édition devis
    - Vue lignes groupées par phase avec sous-totaux
    - Sélecteur devise (FCFA/EUR) avec conversion dynamique
    - Boutons export PDF/Excel (avec dialog invitation si non abonné)
    - _Exigences : 7.1, 7.2, 7.3, 7.6, 7.7, 7.8, 7.9_

  - [ ] 9.7 Implémenter les endpoints Django export PDF et Excel
    - `POST /api/devis/{id}/export/pdf/` et `POST /api/devis/{id}/export/excel/`
    - Protégés par `EstAbonne`, génération avec `reportlab` (PDF) et `openpyxl` (Excel)
    - _Exigences : 7.7, 11.5_

- [ ] 10. Checkpoint — Module Devis
  - Vérifier la création, l'édition, les totaux par phase, la conversion de devise et l'export PDF/Excel. Tester le blocage de l'export pour les utilisateurs non abonnés. Demander à l'utilisateur s'il a des questions.

- [ ] 11. Module Projet — Gestion et synchronisation
  - [ ] 11.1 Implémenter le modèle domaine et le repository Projet
    - Créer les modèles Projet dans `lib/features/projet/domain/`
    - Repository : CRUD Drift, journal de sync, chargement de l'historique (calculs, plans, devis) trié par date décroissante
    - _Exigences : 9.1, 9.2, 9.3, 9.7_

  - [ ] 11.2 Implémenter le `SyncService` (journal offline/online)
    - Créer `lib/shared/database/sync_journal.dart` avec `enregistrer()` et `synchroniser()`
    - Synchronisation dans les 30 secondes après modification pour les utilisateurs abonnés
    - Gestion des conflits HTTP 409 : conserver version locale, stocker version distante, déclencher `ConflitProvider`
    - _Exigences : 9.4, 9.5, 9.6, 15.5_

  - [ ]* 11.3 Écrire les tests de propriété pour le journal de synchronisation
    - **Property 12 : Journal de synchronisation exhaustif**
    - **Validates : Exigences 15.5**

  - [ ] 11.4 Implémenter les providers Riverpod du module Projet
    - Providers : liste projets, projet actif, état de synchronisation, gestion des conflits
    - _Exigences : 9.1, 9.4, 9.6_

  - [ ] 11.5 Créer les écrans UI du module Projet
    - Écran liste projets, écran création/édition projet (nom, adresse, client, devise)
    - Écran historique d'un projet (onglets : calculs, plans, devis)
    - Indicateur de statut sync, dialog de résolution de conflit
    - _Exigences : 9.1, 9.2, 9.3, 9.6_

  - [ ] 11.6 Implémenter le endpoint `/api/sync/journal/` Django
    - ViewSet qui accepte les entrées du journal, applique les opérations en base, détecte et retourne les conflits (409)
    - _Exigences : 9.4, 9.5_

- [ ] 12. Module Plan par image — IA, CustomPainter, correction manuelle
  - [ ] 12.1 Implémenter les modèles domaine Plan et ElementPlan
    - Créer `lib/features/plan/domain/models/plan.dart` et `element_plan.dart`
    - Modèle `ElementPlan` avec `typeElement`, `geometrieJson`, `valeurMetres`, `label`, `estValide`
    - _Exigences : 15.4, 8.8_

  - [ ]* 12.2 Écrire les tests unitaires — invariant de structure des éléments de plan
    - **Property 16 : Invariant de structure des éléments de plan**
    - **Validates : Exigences 15.4, 8.8**

  - [ ] 12.3 Implémenter l'import d'image et l'étalonnage
    - Intégrer `image_picker` pour import galerie et capture caméra (réservé abonnés)
    - Écran d'étalonnage : saisie mesure de référence (longueur réelle en mètres), calcul `echelleMetresParPixel`
    - _Exigences : 8.1, 8.2, 8.3_

  - [ ] 12.4 Implémenter le `PlanPainter` (CustomPainter)
    - Créer `lib/features/plan/presentation/widgets/plan_painter.dart`
    - Rendu des `ElementPlan` superposés sur l'image (mur=bleu, ouverture=orange, cote=vert)
    - Affichage des labels à mi-segment
    - Optimisation `shouldRepaint` : retourne `false` si liste inchangée
    - _Exigences : 8.5, 14.1_

  - [ ] 12.5 Implémenter la correction manuelle des éléments de plan
    - Gestes : déplacement de points (drag), ajout de segments, suppression
    - Mise à jour des `valeurMetres` après chaque modification via l'échelle d'étalonnage
    - _Exigences : 8.6_

  - [ ] 12.6 Implémenter l'endpoint Django d'analyse IA `/api/plans/analyse/`
    - Accepter `image_base64`, `mesure_ref_metres`, `mesure_ref_pixels`
    - Appel API Claude (multimodal) avec prompt structuré, clé stockée en variable d'environnement
    - Retourner le JSON `{segments: [...], echelle_metres_par_pixel, confiance}`
    - Gestion erreur 502 si l'API IA échoue
    - _Exigences : 8.4, 14.3, 8.9_

  - [ ] 12.7 Connecter l'analyse IA et alimenter le moteur de calcul
    - Après validation des `ElementPlan`, extraire les dimensions et pré-remplir le formulaire de calcul de la phase correspondante
    - _Exigences : 8.4, 8.5, 8.7_

- [ ] 13. Authentification Flutter — UI et stockage sécurisé
  - [ ] 13.1 Implémenter `SecureTokenStorage` et `AuthRepository`
    - Créer `lib/features/auth/data/secure_token_storage.dart` avec `flutter_secure_storage`
    - Stocker `access_token` et `refresh_token` dans Keychain/Keystore/Credential Locker selon la plateforme
    - _Exigences : 10.4, 10.5_

  - [ ] 13.2 Implémenter `AuthNotifier` et le provider d'authentification
    - Créer `lib/features/auth/presentation/providers/auth_provider.dart`
    - États : non connecté, en cours, connecté (abonné / non abonné), erreur
    - Gestion de l'expiration de session : redirection vers login, données locales intactes
    - _Exigences : 10.7, 11.6_

  - [ ] 13.3 Créer les écrans UI d'authentification
    - Écrans : inscription, connexion, CGU (avec case à cocher et horodatage du consentement)
    - Message d'erreur générique sur identifiants incorrects
    - Écran d'invitation à l'abonnement pour les fonctionnalités avancées
    - _Exigences : 6.2, 6.3, 10.3, 11.4_

- [ ] 14. Checkpoint — Modules Projet, Plan et Authentification
  - Vérifier le flux complet : création projet → ajout calcul → création devis → export. Tester le module plan avec un plan de test. Vérifier l'accès freemium. Demander à l'utilisateur s'il a des questions.

- [ ] 15. UI/UX — Navigation, ergonomie chantier et localisation
  - [ ] 15.1 Implémenter le routage avec `go_router`
    - Configurer les routes : `/`, `/projets`, `/projets/:id`, `/calcul/:type`, `/devis/:id`, `/plan/:id`, `/auth/login`, `/auth/register`, `/settings`
    - Garde de navigation : rediriger vers `/auth/login` si session expirée
    - _Exigences : 10.7, 11.4_

  - [ ] 15.2 Implémenter `app.dart` avec `MaterialApp` et thème WCAG
    - Configurer la palette `app_colors.dart` (contraste ≥ 4.5:1)
    - Configurer `app_typography.dart` (résultats ≥ 16sp)
    - Support portrait et paysage sans perte de données (sauvegarde automatique état Riverpod)
    - _Exigences : 13.1, 13.2, 13.3, 13.4_

  - [ ] 15.3 Implémenter la sauvegarde automatique des brouillons
    - `Timer.periodic(30s)` dans les formulaires de calcul actifs → persiste dans Drift
    - _Exigences : 14.6_

  - [ ] 15.4 Implémenter la gestion de la connectivité et le mode hors-ligne
    - `connectivityProvider` surveille l'état réseau via `connectivity_plus`
    - Bannière de notification lors du passage offline/online
    - Désactiver les features nécessitant le réseau sans interrompre les calculs
    - _Exigences : 13.5, 13.6_

  - [ ] 15.5 Implémenter l'écran Paramètres (devise, taux de conversion, TypesSol)
    - Sélecteur devise FCFA/EUR avec taux de conversion modifiable
    - Gestion des TypesSol (modification des coefficients de foisonnement)
    - _Exigences : 12.1, 12.2, 1.6_

  - [ ] 15.6 Implémenter `NumberFormatter` et localisation FCFA/EUR
    - Intégrer dans tous les écrans d'affichage de montants et de quantités
    - Formats numériques adaptés à la locale de l'appareil
    - _Exigences : 12.1, 12.4, 12.5_

- [ ] 16. Performances et optimisations
  - [ ] 16.1 Implémenter le démarrage optimisé
    - `main.dart` : initialisation Drift et providers Riverpod lazy, chargement en parallèle avec `Future.wait` (profil utilisateur + liste projets)
    - Écran principal affiché en moins de 3 secondes sur appareil ≥ 2 Go RAM
    - _Exigences : 14.5_

  - [ ] 16.2 Vérifier et optimiser les performances du moteur de calcul
    - Mesurer le temps de chaque engine (objectif < 200 ms)
    - Vérifier que `PlanPainter.shouldRepaint` évite les re-renders inutiles
    - _Exigences : 14.1, 1.8, 2.9, 3.7, 4.6, 5.7_

- [ ] 17. Tests d'intégration et validation multiplateforme
  - [ ]* 17.1 Écrire les tests d'intégration Flutter (calcul → devis → export)
    - Tester le flux complet : saisie d'un calcul, ajout au devis, export PDF
    - _Exigences : 1.7, 2.8, 7.4, 7.7_

  - [ ]* 17.2 Écrire les tests d'intégration backend (auth + sync + freemium)
    - Tester le flux JWT complet, la synchronisation journal, le contrôle d'accès
    - _Exigences : 10.1, 10.2, 9.4, 11.5_

  - [ ]* 17.3 Valider l'interface sur les plateformes cibles
    - Tester sur Android et Windows (principales cibles de développement)
    - Vérifier orientation portrait/paysage, taille boutons 48dp, contraste, police ≥ 16sp
    - _Exigences : 13.1, 13.2, 13.3, 13.4_

- [ ] 18. Checkpoint final — Validation complète
  - Vérifier que tous les tests passent, que le build Android et Windows réussit, que le backend Django répond correctement. Demander à l'utilisateur s'il a des questions avant la mise en production.

---

## Notes

- Les tâches marquées `*` sont optionnelles et peuvent être ignorées pour un MVP rapide, mais sont fortement recommandées pour une application de production conforme aux normes BTP.
- Chaque tâche référence les exigences spécifiques pour la traçabilité.
- Les checkpoints permettent de valider les acquis avant de passer à la couche suivante.
- Les tests de propriété (PBT) valident les invariants mathématiques du moteur de calcul — critiques pour une application normative.
- Le moteur Dart et le moteur Python doivent produire des résultats identiques sur les mêmes entrées.
- La clé API IA (Claude) ne doit jamais quitter le serveur Django.

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "2.1"] },
    { "id": 1, "tasks": ["1.3", "1.5", "1.6", "2.2"] },
    { "id": 2, "tasks": ["1.4", "2.3", "4.1"] },
    { "id": 3, "tasks": ["2.4", "2.5", "4.2", "4.6", "4.7", "4.9"] },
    { "id": 4, "tasks": ["2.6", "4.3", "4.5", "4.8", "4.10", "4.11", "7.1"] },
    { "id": 5, "tasks": ["2.7", "5.1", "7.2", "9.1"] },
    { "id": 6, "tasks": ["5.2", "7.3", "9.2", "9.3", "11.1", "12.1"] },
    { "id": 7, "tasks": ["5.3", "8.1", "9.4", "11.2", "12.2"] },
    { "id": 8, "tasks": ["8.2", "8.3", "8.4", "8.5", "9.5", "11.3", "11.4", "12.3"] },
    { "id": 9, "tasks": ["9.6", "9.7", "11.5", "11.6", "12.4", "13.1"] },
    { "id": 10, "tasks": ["12.5", "12.6", "13.2"] },
    { "id": 11, "tasks": ["12.7", "13.3", "15.1"] },
    { "id": 12, "tasks": ["15.2", "15.3", "15.4", "15.5", "15.6"] },
    { "id": 13, "tasks": ["16.1", "16.2"] },
    { "id": 14, "tasks": ["17.1", "17.2", "17.3"] }
  ]
}
```
