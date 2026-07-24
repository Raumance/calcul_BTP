class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

class ValidationException extends AppException {
  const ValidationException(String message, {String code = 'VALIDATION_ERREUR'})
      : super(message, code: code);
}

class AuthException extends AppException {
  const AuthException([String message = 'Identifiants incorrects.'])
      : super(message, code: 'IDENTIFIANTS_INCORRECTS');
}

class SubscriptionException extends AppException {
  const SubscriptionException([String message = 'Abonnement requis.'])
      : super(message, code: 'ABONNEMENT_REQUIS');
}

class SyncConflictException extends AppException {
  const SyncConflictException({this.remotePayload})
      : super('Conflit de synchronisation.', code: 'CONFLIT_SYNC');

  final Map<String, dynamic>? remotePayload;
}
