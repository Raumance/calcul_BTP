import json

from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser


class SyncConsumer(AsyncJsonWebsocketConsumer):
    """Diffusion temps réel des modifications projet / devis / calculs."""

    async def connect(self):
        user = self.scope.get("user")
        if user is None or isinstance(user, AnonymousUser) or not user.is_authenticated:
            await self.close(code=4401)
            return

        self.projet_id = self.scope["url_route"]["kwargs"].get("projet_id", "all")
        self.group_name = f"user_{user.id}_projet_{self.projet_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.channel_layer.group_add(f"user_{user.id}_all", self.channel_name)
        await self.accept()
        await self.send_json({"type": "connected", "projet_id": self.projet_id})

    async def disconnect(self, code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)
            user = self.scope.get("user")
            if user and user.is_authenticated:
                await self.channel_layer.group_discard(
                    f"user_{user.id}_all", self.channel_name
                )

    async def receive_json(self, content, **kwargs):
        msg_type = content.get("type")
        if msg_type == "ping":
            await self.send_json({"type": "pong"})
            return

        if msg_type == "subscribe":
            projet_id = content.get("projet_id", self.projet_id)
            self.projet_id = projet_id
            self.group_name = f"user_{self.scope['user'].id}_projet_{projet_id}"
            await self.channel_layer.group_add(self.group_name, self.channel_name)
            await self.send_json({"type": "subscribed", "projet_id": projet_id})
            return

        if msg_type == "entity_changed":
            payload = {
                "type": "entity_update",
                "entite_type": content.get("entite_type"),
                "entite_id": content.get("entite_id"),
                "operation": content.get("operation"),
                "payload": content.get("payload"),
                "timestamp": content.get("timestamp"),
                "origin_channel": self.channel_name,
            }
            await self.channel_layer.group_send(
                self.group_name,
                {"type": "broadcast.entity", "data": payload},
            )
            await self.channel_layer.group_send(
                f"user_{self.scope['user'].id}_all",
                {"type": "broadcast.entity", "data": payload},
            )

    async def broadcast_entity(self, event):
        data = event["data"]
        # Ne pas renvoyer à l'émetteur.
        if data.get("origin_channel") == self.channel_name:
            return
        await self.send_json(data)
