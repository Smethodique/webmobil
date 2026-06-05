from django.contrib import admin
from .models import Group, GroupMembership, Message, Ticket


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by', 'created_at')
    search_fields = ('name',)


@admin.register(GroupMembership)
class GroupMembershipAdmin(admin.ModelAdmin):
    list_display = ('user', 'group', 'joined_at')
    list_filter = ('group',)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'sender', 'group', 'text_preview', 'created_at')
    list_filter = ('group', 'created_at')
    search_fields = ('text', 'sender__username')

    def text_preview(self, obj):
        return (obj.text or '')[:60]
    text_preview.short_description = 'Text'


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('question_text', 'user__username')
