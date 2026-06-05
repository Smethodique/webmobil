import json
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Group, Message, Ticket, SavedQuestion
from .serializers import (
    GroupSerializer, MessageSerializer, TicketSerializer,
    SavedQuestionSerializer,
)

User = get_user_model()


def _broadcast_to_group(group_id, message_data):
    """Send a message to all WebSocket clients in the group."""
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        f'chat_{group_id}',
        {
            'type': 'chat_message',
            'message': message_data,
        },
    )


def _get_or_create_general_group():
    """Get or create the general group for all students."""
    group, _ = Group.objects.get_or_create(
        name='Général',
        defaults={'description': 'Groupe général pour tous les étudiants'},
    )
    return group


class GroupListView(generics.ListAPIView):
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return Group.objects.filter(members=self.request.user)


class GroupMessagesView(generics.ListAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return Message.objects.filter(
            group_id=self.kwargs['group_id'],
            group__members=self.request.user,
        )


class SendMessageView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [FormParser, MultiPartParser]

    def post(self, request, group_id):
        try:
            group = Group.objects.get(
                id=group_id, members=request.user
            )
        except Group.DoesNotExist:
            return Response(
                {'detail': 'Group not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = MessageSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        message = serializer.save(group=group, sender=request.user)
        _broadcast_to_group(group_id, MessageSerializer(message, context={'request': request}).data)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class AutoJoinView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        group_name = request.data.get('group_name', 'Général')
        group, created = Group.objects.get_or_create(
            name=group_name,
            defaults={'description': 'Groupe général pour tous les étudiants'},
        )
        if created:
            all_users = User.objects.filter(is_active=True)
            group.members.add(*all_users)
        elif not group.members.filter(id=request.user.id).exists():
            group.members.add(request.user)
        return Response(
            GroupSerializer(group).data,
            status=status.HTTP_200_OK,
        )


# ── Ticket views ────────────────────────────────────────────────────────────

class CreateTicketView(generics.CreateAPIView):
    """Student creates a ticket → auto-posts a colored message in the group chat."""
    serializer_class = TicketSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [FormParser, MultiPartParser]

    def perform_create(self, serializer):
        ticket = serializer.save(user=self.request.user)
        self._post_ticket_to_group_chat(ticket)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # Return the ticket, not the message
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def _post_ticket_to_group_chat(self, ticket):
        """Create a Message linked to this ticket and broadcast to the general group."""
        group = _get_or_create_general_group()
        if not group.members.filter(id=ticket.user.id).exists():
            group.members.add(ticket.user)

        # Build the message text from the ticket
        text_lines = []
        if ticket.exam_title:
            text_lines.append(f'📋 Ticket #{ticket.id} — {ticket.exam_title}')
        else:
            text_lines.append(f'📋 Ticket #{ticket.id}')
        if ticket.question_text:
            text_lines.append(ticket.question_text)
        if ticket.exercise_reference:
            text_lines.append(f'Q: {ticket.exercise_reference}')
        text = '\n'.join(text_lines)

        message = Message.objects.create(
            group=group,
            sender=ticket.user,
            text=text,
            image=ticket.screenshot,
            ticket=ticket,
            is_ticket=True,
        )
        msg_data = MessageSerializer(message, context={'request': self.request}).data
        _broadcast_to_group(group.id, msg_data)


class UserTicketsView(generics.ListAPIView):
    """Student: list my tickets. Expert: list all tickets."""
    serializer_class = TicketSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        if user.role == 'expert':
            return Ticket.objects.all().order_by('-created_at')
        return Ticket.objects.filter(user=user)


class ExpertTicketReplyView(APIView):
    """Expert replies to a ticket → updates ticket + broadcasts colored reply to group."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [FormParser, MultiPartParser]

    def post(self, request, ticket_id):
        if request.user.role != 'expert':
            return Response(
                {'detail': 'Only experts can reply to tickets'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            ticket = Ticket.objects.get(id=ticket_id)
        except Ticket.DoesNotExist:
            return Response(
                {'detail': 'Ticket not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        response_text = request.data.get('response_text', '')
        response_image = request.FILES.get('response_image')

        if not response_text and not response_image:
            return Response(
                {'detail': 'Response must have text or image'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ticket.response_text = response_text
        ticket.responded_by = request.user
        ticket.responded_at = timezone.now()
        ticket.status = 'resolved'
        if response_image:
            ticket.response_image = response_image
        ticket.save()

        # Post the expert reply as a message in the general group
        group = _get_or_create_general_group()
        if not group.members.filter(id=request.user.id).exists():
            group.members.add(request.user)

        reply_text = f'💬 Réponse Ticket #{ticket.id}: {response_text}' if response_text else f'💬 Réponse Ticket #{ticket.id}: [image]'

        message = Message.objects.create(
            group=group,
            sender=request.user,
            text=reply_text,
            image=response_image if response_image else None,
            ticket=ticket,
            is_ticket_reply=True,
        )
        msg_data = MessageSerializer(message, context={'request': request}).data
        _broadcast_to_group(group.id, msg_data)

        return Response(TicketSerializer(ticket).data, status=status.HTTP_200_OK)


# ── Saved Questions views ────────────────────────────────────────────────────

class SavedQuestionListCreateView(generics.ListCreateAPIView):
    """List all saved questions for current user, or create a new one."""
    serializer_class = SavedQuestionSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        qs = SavedQuestion.objects.filter(user=self.request.user)
        subject = self.request.query_params.get('subject')
        if subject:
            qs = qs.filter(subject=subject)
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SavedQuestionDeleteView(generics.DestroyAPIView):
    """Delete a saved question."""
    serializer_class = SavedQuestionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SavedQuestion.objects.filter(user=self.request.user)
