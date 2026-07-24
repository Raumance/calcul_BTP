from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken
from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware

User = get_user_model()


@database_sync_to_async
def user_from_token(token: str):
    try:
        access = AccessToken(token)
        return User.objects.get(id=access["user_id"])
    except Exception:
        return AnonymousUser()


class JwtAuthMiddleware(BaseMiddleware):
    """Authentifie les WebSockets via ?token=<JWT access>."""

    async def __call__(self, scope, receive, send):
        query = scope.get("query_string", b"").decode()
        token = ""
        for part in query.split("&"):
            if part.startswith("token="):
                token = part[6:]
                break
        scope["user"] = await user_from_token(token) if token else AnonymousUser()
        return await super().__call__(scope, receive, send)


def JwtAuthMiddlewareStack(inner):
    return JwtAuthMiddleware(inner)
