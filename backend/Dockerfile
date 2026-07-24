# syntax=docker/dockerfile:1
# Base Chainguard (Wolfi) — image minimale, peu/pas de CVE critiques (Docker DX).

# ── Build : venv + dépendances ──────────────────────────────────────────
FROM cgr.dev/chainguard/python:latest-dev AS builder

WORKDIR /build

ENV PATH="/build/venv/bin:$PATH" \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN python -m venv /build/venv \
    && pip install --upgrade "pip>=25.3" "setuptools>=78" "wheel"

COPY requirements.txt .
RUN pip install -r requirements.txt

# ── Runtime : image distroless-like, non-root ───────────────────────────
FROM cgr.dev/chainguard/python:latest AS runtime

WORKDIR /app

ENV PATH="/app/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /build/venv /app/venv
COPY . .

# Chainguard définit ENTRYPOINT=python — on le remplace pour lancer Daphne.
ENTRYPOINT []
USER nonroot

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
  CMD ["/app/venv/bin/python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health/', timeout=3)"]

# Compose override : python start.py (migrate + seed + daphne, sans shell).
CMD ["/app/venv/bin/python", "start.py"]
