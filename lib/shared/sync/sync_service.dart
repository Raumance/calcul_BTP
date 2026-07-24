import '../../core/network/api_client.dart';
import '../database/local_store.dart';

class SyncResult {
  const SyncResult({
    this.succes = 0,
    this.conflits = 0,
    this.erreurs = 0,
  });

  final int succes;
  final int conflits;
  final int erreurs;
}

/// Pousse le journal offline vers `POST /api/sync/journal/`.
/// Ordre : Projet → Devis/Calcul/Plan pour éviter `projet_introuvable`.
class SyncService {
  SyncService({required LocalStore store, required ApiClient api})
      : _store = store,
        _api = api;

  final LocalStore _store;
  final ApiClient _api;

  static const _priorite = {
    'Projet': 0,
    'Devis': 1,
    'Calcul': 2,
    'Plan': 3,
  };

  Future<SyncResult> synchroniser() async {
    final pending = await _store.pendingJournal();
    pending.sort((a, b) {
      final pa = _priorite[a['entite_type']] ?? 9;
      final pb = _priorite[b['entite_type']] ?? 9;
      if (pa != pb) return pa.compareTo(pb);
      return (a['created_at'] as String? ?? '')
          .compareTo(b['created_at'] as String? ?? '');
    });

    var succes = 0;
    var conflits = 0;
    var erreurs = 0;

    for (final entry in pending) {
      try {
        final resp = await _api.post(
          '/api/sync/journal/',
          data: {
            'entite_type': entry['entite_type'],
            'entite_id': entry['entite_id'],
            'operation': entry['operation'],
            'payload': _normalizePayload(
              entry['entite_type'] as String?,
              Map<String, dynamic>.from(entry['payload'] as Map? ?? {}),
            ),
          },
        );
        final body = resp.data;
        final root = body is Map ? Map<String, dynamic>.from(body) : null;
        final data = root?['data'];
        final ok = data is Map ? data['ok'] != false : true;
        if (!ok) {
          erreurs++;
          continue;
        }
        await _store.markJournalSynced(entry['id'] as String);
        succes++;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('CONFLIT_SYNC') || msg.contains('409')) {
          conflits++;
        } else {
          erreurs++;
        }
      }
    }
    return SyncResult(succes: succes, conflits: conflits, erreurs: erreurs);
  }

  Map<String, dynamic> _normalizePayload(
    String? type,
    Map<String, dynamic> payload,
  ) {
    if (type == 'Projet') {
      return {
        ...payload,
        'adresse_chantier':
            payload['adresse_chantier'] ?? payload['adresse'] ?? '',
        'nom_client': payload['nom_client'] ?? payload['client'] ?? '',
        'updated_at':
            payload['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
      };
    }
    return payload;
  }
}
