import os
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "fmp_prep.settings")

django_asgi_app = get_asgi_application()

from apps.chat import routing

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": URLRouter(routing.websocket_urlpatterns),
})
