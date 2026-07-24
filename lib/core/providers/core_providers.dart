import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../network/realtime_sync_service.dart';
import '../../shared/database/local_store.dart';
import '../../shared/sync/sync_service.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    storage: ref.watch(secureStorageProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final realtimeSyncProvider = Provider<RealtimeSyncService>((ref) {
  return RealtimeSyncService(
    wsBaseUrl: AppConfig.wsBaseUrl,
    storage: ref.watch(secureStorageProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    store: ref.watch(localStoreProvider),
    api: ref.watch(apiClientProvider),
  );
});
