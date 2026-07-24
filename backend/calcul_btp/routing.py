from django.urls import re_path

from .consumers import SyncConsumer

websocket_urlpatterns = [
    re_path(r"ws/sync/(?P<projet_id>[^/]+)/$", SyncConsumer.as_asgi()),
]
