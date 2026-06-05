from rest_framework import serializers
from .models import Group, GroupMembership, Message, Ticket, SavedQuestion


class GroupSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = (
            'id', 'name', 'description', 'created_by',
            'created_at', 'member_count',
        )
        read_only_fields = ('id', 'created_by', 'created_at', 'member_count')

    def get_member_count(self, obj):
        return obj.members.count()


class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(
        source='sender.username', read_only=True
    )
    sender_role = serializers.CharField(
        source='sender.role', read_only=True
    )
    ticket_id = serializers.IntegerField(
        source='ticket.id', read_only=True, allow_null=True
    )
    ticket_status = serializers.CharField(
        source='ticket.status', read_only=True, allow_null=True
    )
    ticket_question = serializers.CharField(
        source='ticket.question_text', read_only=True, allow_null=True
    )

    class Meta:
        model = Message
        fields = (
            'id', 'group', 'sender', 'sender_username', 'sender_role',
            'text', 'image', 'voice', 'created_at',
            'is_ticket', 'is_ticket_reply',
            'ticket_id', 'ticket_status', 'ticket_question',
        )
        read_only_fields = (
            'id', 'sender', 'sender_username', 'sender_role',
            'created_at', 'group',
            'is_ticket', 'is_ticket_reply',
            'ticket_id', 'ticket_status', 'ticket_question',
        )


class TicketSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(
        source='user.username', read_only=True
    )
    responded_by_username = serializers.CharField(
        source='responded_by.username', read_only=True, allow_null=True
    )

    class Meta:
        model = Ticket
        fields = (
            'id', 'user', 'user_username', 'question_text',
            'exercise_reference', 'exam_title', 'screenshot', 'status',
            'response_text', 'responded_by', 'responded_by_username',
            'responded_at', 'response_image',
            'created_at', 'updated_at',
        )
        read_only_fields = (
            'id', 'user', 'user_username', 'status',
            'responded_by', 'responded_by_username',
            'responded_at',
            'created_at', 'updated_at',
        )


class SavedQuestionSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = SavedQuestion
        fields = (
            'id', 'user', 'user_username', 'question_text',
            'answer_text', 'subject', 'is_ai_generated', 'created_at',
        )
        read_only_fields = (
            'id', 'user', 'user_username', 'created_at',
        )
