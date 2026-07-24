import 'package:calcul_projet/core/providers/core_providers.dart';
import 'package:calcul_projet/features/auth/presentation/providers/auth_provider.dart';
import 'package:calcul_projet/features/calcul/domain/models/calcul_result.dart';
import 'package:calcul_projet/features/devis/domain/models/devis.dart';
import 'package:calcul_projet/shared/database/local_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ProjetModel {
  const ProjetModel({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.client = '',
    this.deviseCode = 'XOF',
    required this.createdAt,
  });

  final String id;
  final String nom;
  final String adresse;
  final String client;
  final String deviseCode;
  final DateTime createdAt;

  ProjetModel copyWith({
    String? nom,
    String? adresse,
    String? client,
    String? deviseCode,
  }) =>
      ProjetModel(
        id: id,
        nom: nom ?? this.nom,
        adresse: adresse ?? this.adresse,
        client: client ?? this.client,
        deviseCode: deviseCode ?? this.deviseCode,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'adresse': adresse,
        'adresse_chantier': adresse,
        'client': client,
        'nom_client': client,
        'devise_code': deviseCode,
        'created_at': createdAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory ProjetModel.fromJson(Map<String, dynamic> json) => ProjetModel(
        id: json['id'] as String,
        nom: json['nom'] as String? ?? '',
        adresse: json['adresse'] as String? ?? '',
        client: json['client'] as String? ?? '',
        deviseCode: json['devise_code'] as String? ?? 'XOF',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class AppSession {
  const AppSession({
    this.projets = const [],
    this.devis = const [],
    this.projetActifId,
    this.devisActifId,
    this.isOnline = true,
    this.estConnecte = false,
    this.estAbonne = false,
    this.cguAcceptees = false,
    this.syncing = false,
    this.hydrated = false,
  });

  final List<ProjetModel> projets;
  final List<DevisModel> devis;
  final String? projetActifId;
  final String? devisActifId;
  final bool isOnline;
  final bool estConnecte;
  final bool estAbonne;
  final bool cguAcceptees;
  final bool syncing;
  final bool hydrated;

  ProjetModel? get projetActif {
    if (projetActifId == null) return null;
    try {
      return projets.firstWhere((p) => p.id == projetActifId);
    } catch (_) {
      return null;
    }
  }

  DevisModel? get devisActif {
    if (devisActifId == null) return null;
    try {
      return devis.firstWhere((d) => d.id == devisActifId);
    } catch (_) {
      return null;
    }
  }

  AppSession copyWith({
    List<ProjetModel>? projets,
    List<DevisModel>? devis,
    String? projetActifId,
    String? devisActifId,
    bool clearProjetActif = false,
    bool clearDevisActif = false,
    bool? isOnline,
    bool? estConnecte,
    bool? estAbonne,
    bool? cguAcceptees,
    bool? syncing,
    bool? hydrated,
  }) {
    return AppSession(
      projets: projets ?? this.projets,
      devis: devis ?? this.devis,
      projetActifId:
          clearProjetActif ? null : (projetActifId ?? this.projetActifId),
      devisActifId:
          clearDevisActif ? null : (devisActifId ?? this.devisActifId),
      isOnline: isOnline ?? this.isOnline,
      estConnecte: estConnecte ?? this.estConnecte,
      estAbonne: estAbonne ?? this.estAbonne,
      cguAcceptees: cguAcceptees ?? this.cguAcceptees,
      syncing: syncing ?? this.syncing,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

class AppSessionNotifier extends StateNotifier<AppSession> {
  AppSessionNotifier(this._store) : super(const AppSession()) {
    _hydrate();
  }

  final LocalStore _store;

  Future<void> _hydrate() async {
    final projetsRaw = await _store.getProjets();
    final devisRaw = await _store.getDevis();
    final meta = _store.meta;
    final projets = projetsRaw.map(ProjetModel.fromJson).toList();
    final devis = devisRaw.map(DevisModel.fromJson).toList();
    state = state.copyWith(
      projets: projets,
      devis: devis,
      projetActifId: meta['projetActifId'] as String?,
      devisActifId: meta['devisActifId'] as String?,
      cguAcceptees: meta['cguAcceptees'] as bool? ?? false,
      estConnecte: meta['utilisateurId'] != null,
      estAbonne: meta['estAbonne'] as bool? ?? false,
      hydrated: true,
    );
  }

  Future<void> accepterCgu() async {
    state = state.copyWith(cguAcceptees: true);
    await _store.setMeta({'cguAcceptees': true});
  }

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }

  void setSyncing(bool value) {
    state = state.copyWith(syncing: value);
  }

  void setAuth({required bool connecte, required bool abonne}) {
    state = state.copyWith(estConnecte: connecte, estAbonne: abonne);
  }

  Future<ProjetModel> creerProjet({
    required String nom,
    String adresse = '',
    String client = '',
    String deviseCode = 'XOF',
  }) async {
    final projet = ProjetModel(
      id: _uuid.v4(),
      nom: nom,
      adresse: adresse,
      client: client,
      deviseCode: deviseCode,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      projets: [...state.projets, projet],
      projetActifId: projet.id,
    );
    await _store.upsertProjet(projet.toJson());
    await _store.setMeta({'projetActifId': projet.id});
    return projet;
  }

  Future<void> selectionnerProjet(String id) async {
    state = state.copyWith(projetActifId: id);
    await _store.setMeta({'projetActifId': id});
  }

  Future<DevisModel> creerDevis({required String intitule}) async {
    final projet = state.projetActif;
    if (projet == null) {
      throw StateError('Aucun projet actif.');
    }
    final devis = DevisModel(
      id: _uuid.v4(),
      projetId: projet.id,
      intitule: intitule,
      dateDevis: DateTime.now(),
      deviseCode: projet.deviseCode,
      tauxConversion: 1.0,
      lignes: const [],
    );
    state = state.copyWith(
      devis: [...state.devis, devis],
      devisActifId: devis.id,
    );
    await _store.upsertDevis(devis.toJson());
    await _store.setMeta({'devisActifId': devis.id});
    return devis;
  }

  Future<void> ajouterResultatAuDevis({
    required CalculResult result,
    required String phase,
    double prixUnitaire = 0,
  }) async {
    var devis = state.devisActif;
    if (devis == null && state.projetActif != null) {
      devis = await creerDevis(intitule: 'Devis — ${state.projetActif!.nom}');
    }
    if (devis == null) {
      throw StateError('Créez un projet et un devis avant d\'ajouter une ligne.');
    }

    final ligne = LigneDevisModel(
      id: _uuid.v4(),
      designation: result.designation ?? 'Ligne de calcul',
      phase: phase,
      quantite: result.valeurPrincipale,
      unite: result.unite,
      prixUnitaire: prixUnitaire,
      coefficientPerte:
          (result.details['coefficient_perte'] as num?)?.toDouble() ?? 0,
      ordre: devis.lignes.length + 1,
    );

    final updated = devis.copyWith(lignes: [...devis.lignes, ligne]);
    final list =
        state.devis.map((d) => d.id == updated.id ? updated : d).toList();
    state = state.copyWith(devis: list, devisActifId: updated.id);
    await _store.upsertDevis(updated.toJson());
    await _store.setMeta({'devisActifId': updated.id});
  }

  Future<void> convertirDevis(String deviseCode, double taux) async {
    final devis = state.devisActif;
    if (devis == null) return;
    final converted = devis.convertir(deviseCode, taux);
    final list =
        state.devis.map((d) => d.id == converted.id ? converted : d).toList();
    state = state.copyWith(devis: list);
    await _store.upsertDevis(converted.toJson());
  }
}

final appSessionProvider =
    StateNotifierProvider<AppSessionNotifier, AppSession>((ref) {
  final notifier = AppSessionNotifier(ref.watch(localStoreProvider));
  ref.listen<AuthState>(authProvider, (prev, next) {
    if (next is AuthAuthenticated) {
      notifier.setAuth(connecte: true, abonne: next.user.estAbonne);
    } else if (next is AuthUnauthenticated) {
      notifier.setAuth(connecte: false, abonne: false);
    }
  });
  return notifier;
});
