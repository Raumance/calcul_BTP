import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistance offline JSON optimisée (projets, devis, calculs, plans, journal sync).
class LocalStore {
  LocalStore({this.inMemory = false});

  /// Mode tests / démo sans filesystem.
  final bool inMemory;

  File? _file;
  Timer? _debounceTimer;
  Map<String, dynamic> _data = {
    'projets': <dynamic>[],
    'devis': <dynamic>[],
    'calculs': <dynamic>[],
    'plans': <dynamic>[],
    'journal': <dynamic>[],
    'meta': <String, dynamic>{
      'cguAcceptees': false,
      'utilisateurId': null,
      'email': null,
    },
  };

  Future<void> init() async {
    if (inMemory) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File(p.join(dir.path, 'btp_local_store.json'));
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        if (raw.trim().isNotEmpty) {
          _data = jsonDecode(raw) as Map<String, dynamic>;
        }
      } else {
        await _persistNow();
      }
    } catch (e) {
      print('LocalStore: Erreur lors de l\'initialisation : $e');
    }
  }

  Map<String, dynamic> get meta =>
      Map<String, dynamic>.from(_data['meta'] as Map? ?? {});

  Future<void> setMeta(Map<String, dynamic> patch) async {
    final m = meta..addAll(patch);
    _data['meta'] = m;
    _schedulePersist();
  }

  List<Map<String, dynamic>> _list(String key) {
    final raw = _data[key] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _updateList(String key, List<Map<String, dynamic>> items) {
    _data[key] = items;
    _schedulePersist();
  }

  Future<List<Map<String, dynamic>>> getProjets() async => _list('projets');

  Future<void> upsertProjet(Map<String, dynamic> projet) async {
    final items = _list('projets');
    final i = items.indexWhere((e) => e['id'] == projet['id']);
    if (i >= 0) {
      items[i] = projet;
    } else {
      items.add(projet);
    }
    _updateList('projets', items);
    await enqueueJournal(
      entiteType: 'Projet',
      entiteId: projet['id'] as String,
      operation: i >= 0 ? 'UPDATE' : 'INSERT',
      payload: projet,
    );
  }

  Future<List<Map<String, dynamic>>> getDevis() async => _list('devis');

  Future<void> upsertDevis(Map<String, dynamic> devis) async {
    final items = _list('devis');
    final i = items.indexWhere((e) => e['id'] == devis['id']);
    if (i >= 0) {
      items[i] = devis;
    } else {
      items.add(devis);
    }
    _updateList('devis', items);
    await enqueueJournal(
      entiteType: 'Devis',
      entiteId: devis['id'] as String,
      operation: i >= 0 ? 'UPDATE' : 'INSERT',
      payload: devis,
    );
  }

  Future<List<Map<String, dynamic>>> getCalculs({String? projetId}) async {
    final items = _list('calculs');
    if (projetId == null) return items;
    return items.where((e) => e['projet_id'] == projetId).toList();
  }

  Future<void> upsertCalcul(Map<String, dynamic> calcul) async {
    final items = _list('calculs');
    final i = items.indexWhere((e) => e['id'] == calcul['id']);
    if (i >= 0) {
      items[i] = calcul;
    } else {
      items.add(calcul);
    }
    _updateList('calculs', items);
    await enqueueJournal(
      entiteType: 'Calcul',
      entiteId: calcul['id'] as String,
      operation: i >= 0 ? 'UPDATE' : 'INSERT',
      payload: calcul,
    );
  }

  Future<List<Map<String, dynamic>>> getPlans({String? projetId}) async {
    final items = _list('plans');
    if (projetId == null) return items;
    return items.where((e) => e['projet_id'] == projetId).toList();
  }

  Future<void> upsertPlan(Map<String, dynamic> plan) async {
    final items = _list('plans');
    final i = items.indexWhere((e) => e['id'] == plan['id']);
    if (i >= 0) {
      items[i] = plan;
    } else {
      items.add(plan);
    }
    _updateList('plans', items);
    await enqueueJournal(
      entiteType: 'Plan',
      entiteId: plan['id'] as String,
      operation: i >= 0 ? 'UPDATE' : 'INSERT',
      payload: plan,
    );
  }

  Future<void> enqueueJournal({
    required String entiteType,
    required String entiteId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final journal = _list('journal');
    journal.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'entite_type': entiteType,
      'entite_id': entiteId,
      'operation': operation,
      'payload': payload,
      'est_synchro': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    _updateList('journal', journal);
  }

  Future<List<Map<String, dynamic>>> pendingJournal() async {
    return _list('journal').where((e) => e['est_synchro'] != true).toList();
  }

  Future<void> markJournalSynced(String id) async {
    final journal = _list('journal');
    for (final e in journal) {
      if (e['id'] == id) e['est_synchro'] = true;
    }
    _updateList('journal', journal);
  }

  /// Planifie une sauvegarde différée pour grouper les écritures disque (debouncing).
  void _schedulePersist() {
    if (inMemory) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), _persistNow);
  }

  /// Sauvegarde immédiate des données sur le disque en format compact.
  Future<void> _persistNow() async {
    final file = _file;
    if (file == null) return;
    try {
      final raw = jsonEncode(_data);
      await file.writeAsString(raw);
    } catch (e) {
      print('LocalStore: Erreur de sauvegarde : $e');
    }
  }
}
