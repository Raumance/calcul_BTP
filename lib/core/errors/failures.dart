sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion réseau.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Identifiants incorrects.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SyncConflictFailure extends Failure {
  const SyncConflictFailure([
    super.message = 'Conflit de synchronisation détecté.',
  ]);
}

class SubscriptionFailure extends Failure {
  const SubscriptionFailure([
    super.message = 'Cette fonctionnalité nécessite un abonnement actif.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur. Réessayez.']);
}

class LocalDbFailure extends Failure {
  const LocalDbFailure([
    super.message = 'Impossible de sauvegarder localement.',
  ]);
}
