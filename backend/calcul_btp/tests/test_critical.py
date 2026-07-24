"""Tests critiques — auth, abonnement, sync journal."""
from __future__ import annotations

import uuid
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from calcul_btp.models import Projet
from calcul_btp.services.sync import appliquer_entree_journal

User = get_user_model()


@override_settings(
    PASSWORD_HASHERS=["django.contrib.auth.hashers.MD5PasswordHasher"],
)
class AuthApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_et_login(self):
        email = f"u_{uuid.uuid4().hex[:8]}@test.local"
        resp = self.client.post(
            "/api/auth/register/",
            {
                "email": email,
                "password": "DemoPass1",
                "nom": "Test",
                "cgu_acceptees": True,
            },
            format="json",
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", resp.data["data"])

        login = self.client.post(
            "/api/auth/login/",
            {"email": email, "password": "DemoPass1"},
            format="json",
        )
        self.assertEqual(login.status_code, status.HTTP_200_OK)
        self.assertFalse(login.data["data"]["user"]["est_abonne"])


class SyncServiceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="sync@test.local",
            email="sync@test.local",
            password="DemoPass1",
            first_name="Sync",
            cgu_acceptees=True,
            est_abonne=True,
            abonnement_expiration=timezone.now() + timedelta(days=30),
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_sync_projet_puis_devis(self):
        projet_id = str(uuid.uuid4())
        devis_id = str(uuid.uuid4())

        r1 = appliquer_entree_journal(
            self.user,
            {
                "entite_type": "Projet",
                "entite_id": projet_id,
                "operation": "INSERT",
                "payload": {
                    "nom": "Chantier A",
                    "adresse": "Rue 1",
                    "client": "Client",
                    "devise_code": "XOF",
                },
            },
        )
        self.assertTrue(r1.get("ok"))
        self.assertTrue(Projet.objects.filter(id=projet_id, utilisateur=self.user).exists())

        r2 = appliquer_entree_journal(
            self.user,
            {
                "entite_type": "Devis",
                "entite_id": devis_id,
                "operation": "INSERT",
                "payload": {
                    "projet_id": projet_id,
                    "intitule": "Devis A",
                    "devise_code": "XOF",
                    "lignes": [],
                },
            },
        )
        self.assertTrue(r2.get("ok"))

    def test_sync_calcul_sans_projet_echoue(self):
        r = appliquer_entree_journal(
            self.user,
            {
                "entite_type": "Calcul",
                "entite_id": str(uuid.uuid4()),
                "operation": "INSERT",
                "payload": {"projet_id": str(uuid.uuid4())},
            },
        )
        self.assertFalse(r.get("ok"))
        self.assertEqual(r.get("error"), "projet_introuvable")

    def test_api_sync_retourne_422_si_echec(self):
        resp = self.client.post(
            "/api/sync/journal/",
            {
                "entite_type": "Calcul",
                "entite_id": str(uuid.uuid4()),
                "operation": "INSERT",
                "payload": {"projet_id": str(uuid.uuid4())},
            },
            format="json",
        )
        self.assertEqual(resp.status_code, status.HTTP_422_UNPROCESSABLE_ENTITY)
        self.assertEqual(resp.data["code"], "SYNC_ECHOUEE")

    def test_sync_refusee_sans_abonnement(self):
        self.user.est_abonne = False
        self.user.save()
        resp = self.client.post(
            "/api/sync/journal/",
            {
                "entite_type": "Projet",
                "entite_id": str(uuid.uuid4()),
                "operation": "INSERT",
                "payload": {"nom": "X"},
            },
            format="json",
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
