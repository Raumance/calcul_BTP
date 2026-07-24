import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/database/local_store.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.nom = '',
    this.estAbonne = false,
  });

  final String id;
  final String email;
  final String nom;
  final bool estAbonne;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        estAbonne: json['est_abonne'] as bool? ?? false,
      );
}

class AuthRepository {
  AuthRepository({
    required ApiClient api,
    required FlutterSecureStorage storage,
    required LocalStore store,
  })  : _api = api,
        _storage = storage,
        _store = store;

  final ApiClient _api;
  final FlutterSecureStorage _storage;
  final LocalStore _store;

  Future<AuthUser?> currentUser() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;
    final meta = _store.meta;
    final id = meta['utilisateurId'] as String?;
    final email = meta['email'] as String?;
    if (id == null || email == null) return null;
    return AuthUser(
      id: id,
      email: email,
      nom: meta['nom'] as String? ?? '',
      estAbonne: meta['estAbonne'] as bool? ?? false,
    );
  }

  Future<AuthUser> login(String email, String password) async {
    try {
      final resp = await _api.post(
        '/api/auth/login/',
        data: {'email': email.trim(), 'password': password},
      );
      return _persistTokens(resp.data);
    } on DioException catch (e) {
      throw AuthException(e.response?.data?['message']?.toString() ??
          'Identifiants incorrects.');
    }
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String nom,
    required bool cguAcceptees,
  }) async {
    try {
      final resp = await _api.post(
        '/api/auth/register/',
        data: {
          'email': email.trim(),
          'password': password,
          'nom': nom.trim(),
          'cgu_acceptees': cguAcceptees,
        },
      );
      return _persistTokens(resp.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map
          ? (data['message'] ?? data['detail'] ?? data.toString())
          : 'Inscription impossible.';
      throw AuthException(msg.toString());
    }
  }

  Future<void> logout() async {
    final refresh = await _storage.read(key: 'refresh_token');
    try {
      if (refresh != null) {
        await _api.post('/api/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // Logout local même si le serveur est injoignable.
    }
    await _storage.deleteAll();
    await _store.setMeta({
      'utilisateurId': null,
      'email': null,
      'nom': null,
      'estAbonne': false,
    });
  }

  Future<AuthUser> _persistTokens(dynamic body) async {
    final root = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final access = data['access'] as String? ?? data['access_token'] as String?;
    final refresh =
        data['refresh'] as String? ?? data['refresh_token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    if (access == null || refresh == null) {
      throw const AuthException('Réponse d\'authentification invalide.');
    }
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    final user = AuthUser.fromJson(userJson);
    await _store.setMeta({
      'utilisateurId': user.id,
      'email': user.email,
      'nom': user.nom,
      'estAbonne': user.estAbonne,
      'cguAcceptees': true,
    });
    return user;
  }
}
