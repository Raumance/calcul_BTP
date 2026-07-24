import re

from django.core.exceptions import ValidationError


class ComplexPasswordValidator:
    """≥ 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre."""

    def validate(self, password, user=None):
        if len(password) < 8:
            raise ValidationError("Au moins 8 caractères.", code="password_too_short")
        if not re.search(r"[A-Z]", password):
            raise ValidationError("Au moins une majuscule.", code="password_no_upper")
        if not re.search(r"[a-z]", password):
            raise ValidationError("Au moins une minuscule.", code="password_no_lower")
        if not re.search(r"[0-9]", password):
            raise ValidationError("Au moins un chiffre.", code="password_no_digit")

    def get_help_text(self):
        return (
            "Le mot de passe doit contenir au moins 8 caractères, "
            "une majuscule, une minuscule et un chiffre."
        )
