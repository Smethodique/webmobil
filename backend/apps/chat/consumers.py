import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import get_user_model
from .models import Group, Message
from .serializers import MessageSerializer

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_id = self.scope['url_route']['kwargs']['group_id']
        self.room_group_name = f'chat_{self.group_id}'

        user = await self.authenticate_user()
        if user is None or not user.is_authenticated:
            await self.close()
            return

        self.user = user
        can_join = await self.user_in_group()
        if not can_join:
            await self.close()
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name,
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name,
        )

    async def receive(self, text_data):
        pass

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event['message']))

    @database_sync_to_async
    def authenticate_user(self):
        token_str = self.scope['query_string'].decode()
        if 'token=' in token_str:
            token_str = token_str.split('token=')[1].split('&')[0]
        try:
            token = AccessToken(token_str)
            return User.objects.get(id=token['user_id'])
        except Exception:
            return None

    @database_sync_to_async
    def user_in_group(self):
        return Group.objects.filter(
            id=self.group_id, members=self.user
        ).exists()
