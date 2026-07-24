"""Entrypoint sans shell — compatible image Chainguard distroless."""
from __future__ import annotations

import os
import sys


def main() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

    import django

    django.setup()

    from django.core.management import call_command

    call_command("migrate", interactive=False, run_syncdb=True)
    try:
        call_command("seed_referentiels")
    except Exception as exc:  # noqa: BLE001
        print(f"seed_referentiels: {exc}", file=sys.stderr)

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
