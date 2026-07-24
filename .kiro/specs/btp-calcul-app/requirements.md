# Document d'Exigences — btp-calcul-app

## Introduction

L'application **btp-calcul-app** est une application Flutter multiplateforme destinée aux professionnels et techniciens du bâtiment et des travaux publics (BTP). Elle permet de calculer des quantitatifs de matériaux, d'établir des devis chiffrés, d'analyser des plans par image et de gérer des projets de construction. L'application fonctionne selon un modèle freemium : les calculs de base sont accessibles sans compte, tandis que les fonctionnalités avancées (IA, synchronisation, export PDF/Excel, module plan par image) requièrent un compte connecté avec abonnement. L'application cible les marchés d'Afrique francophone (FCFA) et d'Europe (EUR) et doit respecter les normes NF C 15-100 (électricité), DTU et règles BAEL/Eurocodes (béton et ferraillage).

---

## Glossaire

- **Application** : L'application Flutter btp-calcul-app déployée sur Android, iOS, Windows, Linux et macOS.
- **Système** : L'ensemble composé de l'application Flutter et du backend Django/PostgreSQL.
- **Backend** : Le serveur Django REST Framework connecté à la base de données PostgreSQL.
- **Moteur de calcul** : Le composant de l'Application qui effectue les calculs de quantitatifs.
- **Module Devis** : Le composant de l'Application permettant de créer, éditer et exporter des devis.
- **Module Plan** : Le composant de l'Application permettant d'importer, analyser et éditer des plans par image.
- **Module IA** : Le composant côté Backend qui analyse les images de plans via une API multimodale (Claude ou équivalent).
- **Stockage local** : La base de données SQLite gérée par Drift, embarquée dans l'Application.
- **Utilisateur anonyme** : Un utilisateur qui utilise l'Application sans compte créé.
- **Utilisateur connecté** : Un utilisateur authentifié avec un compte valide.
- **Utilisateur abonné** : Un utilisateur connecté disposant d'un abonnement actif permettant l'accès aux fonctionnalités avancées.
- **Projet** : Une entité regroupant des calculs, plans et devis liés à un chantier ou client.
- **Calcul** : Le résultat d'une opération de quantitatif produit par le Moteur de calcul.
- **Devis** : Un document chiffré regroupant des lignes de matériaux et de prestations, structuré par phases.
- **LigneDevis** : Une ligne individuelle d'un Devis comprenant désignation, quantité, unité, prix unitaire et total.
- **Matériau** : Un matériau de construction référencé dans la base de prix de l'Application.
- **RatioFerraillage** : Un ratio acier/béton de référence selon le type d'élément structurel (fondation, poteau, poutre, dalle).
- **TypeSol** : Une nature de sol avec son coefficient de foisonnement associé.
- **Devise** : Une monnaie supportée (FCFA ou EUR) avec son taux de conversion configurable.
- **Plan** : Une image de plan importée ou capturée associée à un Projet et une phase de construction.
- **ElementPlan** : Un élément détecté ou tracé sur un Plan (mur, ouverture, cote, etc.).
- **Étalonnage** : La mesure de référence réelle saisie par l'utilisateur pour calibrer les dimensions d'un Plan.
- **Coefficient de perte** : Un pourcentage de surconsommation appliqué aux quantités calculées pour tenir compte des chutes et déchets.
- **Phase** : Une étape du chantier : terrassement, fondation, gros œuvre, ou finition.
- **JWT** : JSON Web Token, mécanisme d'authentification sécurisé.
- **DTU** : Document Technique Unifié, référentiel français de règles de construction.
- **BAEL/Eurocodes** : Règles de calcul des ouvrages en béton armé (Béton Armé aux États Limites) et normes européennes associées.
- **NF C 15-100** : Norme française régissant les installations électriques basse tension dans les bâtiments.
- **FCFA** : Franc CFA, monnaie utilisée en Afrique francophone.
- **EUR** : Euro, monnaie utilisée en Europe.
- **Riverpod** : Framework de gestion d'état Flutter utilisé dans l'Application.
- **Drift** : Bibliothèque Flutter de gestion de base de données SQLite locale.

---

## Exigences

---

### Exigence 1 — Calculs de terrassement

**User Story :** En tant que technicien BTP, je veux calculer les volumes de déblais et remblais avec les coefficients de foisonnement appropriés, afin d'estimer précisément les mouvements de terres d'un chantier.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL calculer le volume de déblais en appliquant la formule V_déblai = longueur × largeur × profondeur à partir des dimensions saisies par l'utilisateur.
2. THE Moteur de calcul SHALL calculer le volume de remblais en appliquant la formule V_remblai = longueur × largeur × hauteur à partir des dimensions saisies par l'utilisateur.
3. THE Moteur de calcul SHALL appliquer le coefficient de foisonnement correspondant au TypeSol sélectionné pour convertir le volume en place en volume foisonné.
4. THE Moteur de calcul SHALL proposer au moins les types de sol suivants avec leurs coefficients de foisonnement : terre végétale (1.25), argile (1.30), sable (1.10), roche (1.50).
5. WHEN un résultat de calcul de terrassement est affiché, THE Application SHALL afficher le référentiel normatif appliqué (DTU) avec le résultat.
6. WHEN l'utilisateur modifie le coefficient de foisonnement d'un TypeSol, THE Application SHALL recalculer immédiatement les volumes avec la valeur modifiée.
7. WHEN un calcul de terrassement est complété, THE Application SHALL proposer à l'utilisateur d'ajouter le résultat au Devis actif.
8. THE Moteur de calcul SHALL produire les résultats de calcul de terrassement en moins de 200 ms sans appel réseau.

---

### Exigence 2 — Calculs de gros œuvre (béton, parpaings, mortier, ferraillage)

**User Story :** En tant que conducteur de travaux, je veux calculer les quantités de béton, parpaings, mortier et acier pour les éléments structurels, afin de préparer les commandes de matériaux en conformité avec les normes DTU et BAEL/Eurocodes.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL calculer le volume de béton d'une dalle en appliquant la formule V = longueur × largeur × épaisseur à partir des dimensions saisies.
2. THE Moteur de calcul SHALL calculer le nombre de parpaings nécessaires en divisant la surface de mur par la surface unitaire d'un parpaing, puis en appliquant le Coefficient de perte parpaing (valeur par défaut : 5%, modifiable par l'utilisateur entre 1% et 20%).
3. THE Moteur de calcul SHALL calculer le volume de mortier de pose nécessaire à partir du nombre de parpaings et des dimensions des joints.
4. THE Moteur de calcul SHALL calculer la quantité d'acier nécessaire (en kg) pour les éléments suivants en appliquant les RatioFerraillage correspondants : fondation superficielle, poteau, poutre, dalle.
5. THE Moteur de calcul SHALL appliquer un Coefficient de perte béton de 3% par défaut, modifiable par l'utilisateur entre 1% et 10%.
6. WHEN l'utilisateur sélectionne un type d'élément structurel, THE Application SHALL afficher le RatioFerraillage de référence conforme aux règles BAEL/Eurocodes avec la source normative.
7. WHEN un résultat de calcul de gros œuvre est affiché, THE Application SHALL afficher les références normatives DTU et BAEL/Eurocodes appliquées.
8. WHEN un calcul de gros œuvre est complété, THE Application SHALL proposer à l'utilisateur d'ajouter le résultat au Devis actif.
9. THE Moteur de calcul SHALL produire les résultats de calcul de gros œuvre en moins de 200 ms sans appel réseau.

---

### Exigence 3 — Calculs de cloisons, doublages et plafonds

**User Story :** En tant qu'artisan, je veux calculer les surfaces et quantités de matériaux pour les cloisons, doublages et plafonds, afin de dimensionner correctement mes commandes.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL calculer la surface de pose de cloisons en plaque de plâtre (Placomûr, carreaux de plâtre, cloisons alvéolaires) à partir des dimensions de la pièce saisies par l'utilisateur.
2. THE Moteur de calcul SHALL calculer la surface de doublage isolant à partir des dimensions des parois à isoler saisies par l'utilisateur.
3. THE Moteur de calcul SHALL calculer la surface de plafond à revêtir à partir des dimensions de la pièce saisies.
4. THE Moteur de calcul SHALL appliquer un Coefficient de perte pour les matériaux de cloison/plafond (valeur par défaut : 10%, modifiable par l'utilisateur entre 1% et 20%).
5. WHEN un résultat de calcul de cloison ou plafond est affiché, THE Application SHALL afficher le type de matériau sélectionné et la surface nette avec pertes.
6. WHEN un calcul de cloison ou plafond est complété, THE Application SHALL proposer à l'utilisateur d'ajouter le résultat au Devis actif.
7. THE Moteur de calcul SHALL produire les résultats de calcul de cloisons et plafonds en moins de 200 ms sans appel réseau.

---

### Exigence 4 — Calculs de finitions (peinture, carrelage, papier peint)

**User Story :** En tant qu'artisan, je veux calculer les quantités de peinture, carrelage et papier peint nécessaires, afin de préparer mes achats avec précision.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL calculer la surface à peindre à partir des dimensions des parois et plafonds saisis, en déduisant les ouvertures (portes, fenêtres) renseignées.
2. THE Moteur de calcul SHALL calculer le nombre de rouleaux de papier peint à partir de la surface à tapisser et des dimensions d'un rouleau standard (hauteur × laize) saisis.
3. THE Moteur de calcul SHALL calculer la surface de carrelage à partir des dimensions de la pièce saisies, en appliquant le Coefficient de perte carrelage (valeur par défaut : 10%, modifiable entre 1% et 20%).
4. WHEN l'utilisateur modifie le Coefficient de perte d'un matériau de finition, THE Application SHALL recalculer immédiatement les quantités avec la valeur modifiée.
5. WHEN un calcul de finition est complété, THE Application SHALL proposer à l'utilisateur d'ajouter le résultat au Devis actif.
6. THE Moteur de calcul SHALL produire les résultats de calcul de finitions en moins de 200 ms sans appel réseau.

---

### Exigence 5 — Calculs électriques (conforme NF C 15-100)

**User Story :** En tant qu'électricien, je veux calculer le bilan de puissance, la section des câbles et le dimensionnement du tableau électrique, afin de concevoir une installation conforme à la norme NF C 15-100.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL calculer le bilan de puissance totale d'une installation à partir de la liste des circuits et de leur puissance nominale saisie par l'utilisateur.
2. THE Moteur de calcul SHALL calculer la section minimale de câble requise (en mm²) pour un circuit à partir de la puissance, de la longueur du câble, de la tension nominale et du matériau conducteur (cuivre ou aluminium) saisis.
3. THE Moteur de calcul SHALL calculer le calibre minimal du disjoncteur de protection d'un circuit à partir de la puissance et de la tension nominale saisis, en respectant les exigences de la norme NF C 15-100.
4. THE Moteur de calcul SHALL calculer le nombre de points lumineux et de prises recommandés par pièce à partir du type et des dimensions de la pièce saisis, en respectant les prescriptions de la norme NF C 15-100.
5. WHEN un résultat de calcul électrique est affiché, THE Application SHALL afficher la référence normative NF C 15-100 applicable avec le résultat.
6. WHEN un calcul électrique est complété, THE Application SHALL proposer à l'utilisateur d'ajouter le résultat au Devis actif.
7. THE Moteur de calcul SHALL produire les résultats de calcul électrique en moins de 200 ms sans appel réseau.

---

### Exigence 6 — Avertissement et responsabilité

**User Story :** En tant qu'éditeur de l'Application, je veux afficher un avertissement clair sur la nature indicative des résultats, afin de limiter la responsabilité et d'informer les utilisateurs correctement.

#### Critères d'acceptation

1. WHEN un résultat de calcul est affiché, THE Application SHALL afficher un avertissement indiquant que les résultats sont fournis à titre indicatif et ne remplacent pas l'intervention d'un professionnel qualifié.
2. THE Application SHALL afficher les Conditions Générales d'Utilisation incluant une clause de non-responsabilité distinguant les quantitatifs estimatifs du dimensionnement structurel certifié lors de la première utilisation.
3. WHEN l'utilisateur accepte les CGU, THE Application SHALL enregistrer le consentement dans le Stockage local horodaté avec la date d'acceptation.

---

### Exigence 7 — Module Devis

**User Story :** En tant que chef de chantier, je veux créer des devis détaillés par phase, gérer les prix et exporter les documents, afin de présenter des offres professionnelles à mes clients.

#### Critères d'acceptation

1. THE Module Devis SHALL permettre la création d'un Devis associé à un Projet, avec un intitulé, une date et une Devise sélectionnée (FCFA ou EUR).
2. THE Module Devis SHALL permettre l'ajout de LignesDevis comportant : désignation, quantité (intégrant le Coefficient de perte), unité, prix unitaire et total calculé automatiquement.
3. THE Module Devis SHALL regrouper les LignesDevis par Phase (terrassement, fondation, gros œuvre, finition) et afficher les sous-totaux par Phase ainsi que le total général du Devis.
4. WHEN l'utilisateur valide l'ajout d'un résultat de calcul au Devis, THE Module Devis SHALL créer une LigneDevis avec la quantité calculée, incluant le Coefficient de perte appliqué lors du calcul.
5. THE Module Devis SHALL permettre la gestion d'une base de prix de Matériaux paramétrable par l'utilisateur, incluant désignation, unité et prix unitaire par Devise.
6. WHEN l'utilisateur modifie le taux de conversion entre FCFA et EUR, THE Module Devis SHALL recalculer tous les totaux du Devis actif en appliquant le nouveau taux.
7. WHILE un Utilisateur abonné est connecté, THE Module Devis SHALL permettre l'export du Devis au format PDF professionnel, CSV et Excel (.xlsx) avec formules conservées.
8. IF un Utilisateur anonyme ou non abonné tente d'exporter un Devis, THEN THE Application SHALL afficher un message invitant l'utilisateur à créer un compte et souscrire un abonnement.
9. THE Module Devis SHALL permettre de rattacher plusieurs Devis à un même Projet ou client.
10. THE Module Devis SHALL stocker les Devis dans le Stockage local et les synchroniser avec le Backend pour les Utilisateurs abonnés.

---

### Exigence 8 — Module Plan par image

**User Story :** En tant qu'ingénieur, je veux importer ou photographier un plan, le faire analyser par l'IA pour détecter les éléments et cotes, puis corriger manuellement le résultat, afin d'alimenter automatiquement les modules de calcul.

#### Critères d'acceptation

1. WHILE un Utilisateur abonné est connecté, THE Module Plan SHALL permettre l'import d'une image de plan depuis la galerie ou la capture depuis l'appareil photo.
2. IF un Utilisateur anonyme ou non abonné tente d'accéder au Module Plan, THEN THE Application SHALL afficher un message invitant l'utilisateur à créer un compte et souscrire un abonnement.
3. WHEN une image de Plan est importée, THE Application SHALL demander à l'utilisateur de saisir une mesure de référence (longueur réelle en mètres d'un segment identifiable) avant d'activer tout calcul basé sur ce Plan.
4. WHEN l'Étalonnage est validé par l'utilisateur, THE Module Plan SHALL transmettre l'image et la mesure de référence au Module IA côté Backend.
5. WHEN le Module IA retourne une analyse, THE Module Plan SHALL afficher les ElementsPlan détectés (murs, ouvertures, cotes) superposés sur l'image du Plan.
6. THE Module Plan SHALL permettre à l'utilisateur de corriger manuellement les ElementsPlan : déplacement de points, ajout et suppression de segments, correction des cotes détectées.
7. WHEN l'utilisateur valide les ElementsPlan d'un Plan associé à une Phase, THE Module Plan SHALL alimenter automatiquement le module de calcul correspondant à cette Phase avec les dimensions extraites.
8. THE Module Plan SHALL associer chaque Plan à une Phase parmi : terrassement, fondation, élévation/gros œuvre, finition.
9. WHEN le Backend retourne une erreur d'analyse IA, THE Application SHALL afficher un message d'erreur explicite et permettre à l'utilisateur de réessayer ou de saisir les données manuellement.

---

### Exigence 9 — Gestion de projets

**User Story :** En tant qu'utilisateur connecté, je veux organiser mes calculs, plans et devis dans des projets distincts, afin de retrouver facilement l'historique d'un chantier.

#### Critères d'acceptation

1. THE Application SHALL permettre la création d'un Projet avec les attributs suivants : nom du projet, adresse du chantier, nom du client, et Devise de facturation.
2. THE Application SHALL permettre d'associer des Calculs, des Plans et des Devis à un Projet existant.
3. THE Application SHALL afficher l'historique des Calculs, Plans et Devis rattachés à un Projet, triés par date décroissante.
4. WHILE un Utilisateur abonné est connecté et dispose d'une connexion réseau, THE Système SHALL synchroniser les données du Projet entre le Stockage local et le Backend dans un délai de 30 secondes suivant une modification.
5. WHILE un Utilisateur abonné est connecté sur plusieurs appareils, THE Système SHALL assurer la cohérence des données du Projet entre les appareils après synchronisation.
6. IF un conflit de synchronisation est détecté entre deux versions d'un même Projet, THEN THE Système SHALL notifier l'utilisateur et lui proposer de choisir la version à conserver.
7. THE Application SHALL permettre à un Utilisateur anonyme de créer et gérer des Projets stockés uniquement dans le Stockage local, sans synchronisation.

---

### Exigence 10 — Authentification et gestion des comptes

**User Story :** En tant qu'utilisateur, je veux créer un compte sécurisé et me connecter, afin d'accéder aux fonctionnalités avancées et à la synchronisation de mes données.

#### Critères d'acceptation

1. THE Backend SHALL authentifier les utilisateurs en émettant un JWT signé lors de la connexion réussie, avec une durée de validité d'au moins 1 heure.
2. THE Backend SHALL rafraîchir automatiquement le JWT avant son expiration sans nécessiter une reconnexion manuelle de l'utilisateur.
3. WHEN un utilisateur soumet des identifiants incorrects, THE Backend SHALL retourner un message d'erreur générique sans indiquer lequel des champs (identifiant ou mot de passe) est incorrect.
4. THE Application SHALL stocker le JWT exclusivement dans un stockage sécurisé du système d'exploitation (Keychain sur iOS, Keystore sur Android, équivalent sur desktop).
5. WHEN l'utilisateur se déconnecte, THE Application SHALL supprimer le JWT du stockage sécurisé et invalider la session côté Backend.
6. THE Backend SHALL exiger un mot de passe d'au moins 8 caractères incluant au moins une majuscule, une minuscule et un chiffre lors de la création de compte.
7. WHEN la session JWT expire et ne peut être rafraîchie, THE Application SHALL rediriger l'utilisateur vers l'écran de connexion et conserver les données locales intactes.

---

### Exigence 11 — Modèle freemium et contrôle d'accès

**User Story :** En tant qu'éditeur de l'Application, je veux que les calculs de base soient accessibles gratuitement et que les fonctionnalités avancées soient réservées aux abonnés, afin de monétiser l'Application.

#### Critères d'acceptation

1. THE Application SHALL rendre accessibles sans compte les modules de calcul suivants : terrassement, gros œuvre, cloisons/plafonds, finitions, et calculs électriques de base.
2. WHILE un Utilisateur anonyme utilise l'Application, THE Application SHALL afficher les résultats de calcul de base dans le Stockage local sans synchronisation avec le Backend.
3. WHILE un Utilisateur abonné est connecté, THE Application SHALL activer les fonctionnalités suivantes : Module Plan par image (analyse IA), synchronisation multi-appareils, export PDF/Excel, et accès complet au Module Devis avec export.
4. IF un Utilisateur anonyme tente d'accéder à une fonctionnalité réservée aux abonnés, THEN THE Application SHALL afficher un écran d'invitation à la création de compte et à la souscription d'un abonnement, sans bloquer l'accès aux fonctionnalités gratuites.
5. THE Backend SHALL vérifier le statut d'abonnement de l'utilisateur à chaque appel aux API des fonctionnalités avancées et retourner un code d'erreur HTTP 403 si l'abonnement est inactif ou expiré.
6. WHEN le statut d'abonnement d'un Utilisateur connecté expire, THE Application SHALL notifier l'utilisateur et restreindre l'accès aux fonctionnalités avancées sans effacer les données locales.

---

### Exigence 12 — Localisation et devises

**User Story :** En tant qu'utilisateur en Afrique francophone ou en Europe, je veux que l'Application s'adapte à ma devise locale et à mon contexte régional, afin d'obtenir des devis pertinents.

#### Critères d'acceptation

1. THE Application SHALL supporter les devises FCFA (XOF) et EUR dans toutes les interfaces de saisie de prix et d'affichage de totaux.
2. THE Application SHALL permettre à l'utilisateur de configurer le taux de conversion FCFA/EUR dans les paramètres de l'Application.
3. WHEN l'utilisateur change la Devise d'un Devis, THE Module Devis SHALL convertir tous les montants avec le taux de conversion configuré et afficher les totaux dans la nouvelle devise.
4. THE Application SHALL afficher l'interface en langue française pour tous les marchés cibles (Afrique francophone et Europe).
5. THE Application SHALL afficher les formats numériques adaptés à la locale de l'appareil (séparateur décimal et séparateur de milliers).

---

### Exigence 13 — Ergonomie chantier et accessibilité

**User Story :** En tant qu'utilisateur sur chantier, je veux une interface lisible en extérieur et utilisable avec des gants, afin de saisir des données confortablement sur site.

#### Critères d'acceptation

1. THE Application SHALL afficher tous les boutons d'action principaux avec une hauteur minimale de 48 dp et une largeur minimale de 48 dp, conformément aux recommandations WCAG 2.1 niveau AA.
2. THE Application SHALL utiliser un contraste de couleur d'au moins 4.5:1 entre le texte et le fond pour tous les éléments d'interface, conformément aux critères WCAG 2.1 niveau AA.
3. THE Application SHALL afficher les valeurs numériques et les résultats de calcul avec une taille de police minimale de 16 sp.
4. THE Application SHALL supporter l'orientation portrait et paysage sur les appareils mobiles sans perte de données saisies lors de la rotation.
5. THE Application SHALL fonctionner en mode hors-ligne pour tous les modules de calcul de base sans afficher d'erreur liée à l'absence de réseau.
6. WHEN l'Application passe du mode connecté au mode hors-ligne, THE Application SHALL notifier l'utilisateur de l'indisponibilité des fonctionnalités nécessitant une connexion, sans interrompre les calculs en cours.

---

### Exigence 14 — Performances et sécurité

**User Story :** En tant qu'utilisateur, je veux que l'Application réponde rapidement et protège mes données, afin d'avoir une expérience fiable et sécurisée.

#### Critères d'acceptation

1. THE Moteur de calcul SHALL produire tout résultat de calcul (hors appel réseau) en moins de 200 ms après la validation de la saisie par l'utilisateur.
2. THE Application SHALL communiquer avec le Backend exclusivement via HTTPS (TLS 1.2 minimum).
3. THE Backend SHALL stocker et utiliser la clé d'API du Module IA exclusivement côté serveur, sans l'exposer à l'Application cliente.
4. THE Backend SHALL valider et assainir toutes les entrées reçues des clients avant tout traitement ou persistance en base de données.
5. THE Application SHALL afficher l'écran principal en moins de 3 secondes après le lancement sur un appareil disposant d'au moins 2 Go de RAM.
6. WHILE l'Application est en cours d'utilisation, THE Application SHALL sauvegarder automatiquement les données de saisie en cours dans le Stockage local toutes les 30 secondes pour prévenir toute perte de données en cas de fermeture inattendue.

---

### Exigence 15 — Modèle de données et persistance

**User Story :** En tant qu'ingénieur logiciel, je veux que le modèle de données couvre toutes les entités métier de l'Application, afin de garantir la cohérence et l'extensibilité du système.

#### Critères d'acceptation

1. THE Stockage local SHALL persister les entités suivantes : Utilisateur (profil local), Projet, Calcul, Devis, LigneDevis, Matériau, RatioFerraillage, TypeSol, Devise, Plan, ElementPlan.
2. THE Backend SHALL persister les mêmes entités dans la base de données PostgreSQL pour les Utilisateurs connectés, avec une clé primaire UUID pour chaque entité.
3. THE Système SHALL associer chaque Calcul à un Projet, un type de calcul (terrassement, gros œuvre, cloison, finition, électricité) et une date de création.
4. THE Système SHALL associer chaque Plan à un Projet, une Phase et une liste ordonnée d'ElementsPlan.
5. THE Stockage local SHALL maintenir un journal des modifications locales non synchronisées pour permettre la réconciliation lors de la reprise de la connexion réseau.
