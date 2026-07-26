"""Entrypoint sans shell — compatible image Chainguard distroless."""
from __future__ import annotations

import os
import sys


def main() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

    import django

    django.setup()

    from django.core.management import call_command
    from calcul_btp.models import Materiau

    # On ne lance les migrations et le seeding que si nécessaire
    # En production, les migrations sont souvent gérées séparément,
    # mais ici on optimise pour le démarrage rapide.

    # On peut vérifier si les tables existent avant de migrer,
    # mais call_command('migrate') est généralement assez rapide s'il n'y a rien à faire.
    call_command("migrate", interactive=False)

    try:
        # Optimisation : On ne seed que si la table Materiau est vide
        if not Materiau.objects.exists():
            print("Base de données vide, lancement du seeding...")
            call_command("seed_referentiels")
        else:
            print("Référentiels déjà présents, passage du seeding.")
    except Exception as exc:  # noqa: BLE001
        print(f"seed_referentiels error: {exc}", file=sys.stderr)

    from daphne.cli import CommandLineInterface

    sys.argv = [
        "daphne",
        "-b",
        "0.0.0.0",
        "-p",
        os.environ.get("PORT", "8000"),
        "config.asgi:application",
    ]
    CommandLineInterface.entrypoint()


if __name__ == "__main__":
    main()
