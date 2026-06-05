from django.conf import settings
from django.db import models


class Group(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='created_groups'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL, through='GroupMembership',
        related_name='chat_groups'
    )

    def __str__(self):
        return self.name


class GroupMembership(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='group_memberships'
    )
    group = models.ForeignKey(
        Group, on_delete=models.CASCADE, related_name='memberships'
    )
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'group')

    def __str__(self):
        return f'{self.user.username} in {self.group.name}'


class Message(models.Model):
    group = models.ForeignKey(
        Group, on_delete=models.CASCADE, related_name='messages'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='chat_messages'
    )
    text = models.TextField(blank=True)
    image = models.ImageField(upload_to='chat/images/', blank=True, null=True)
    voice = models.FileField(upload_to='chat/voice/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # Expert mode: ticket-related fields
    ticket = models.ForeignKey(
        'Ticket', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='chat_messages'
    )
    is_ticket = models.BooleanField(default=False)
    is_ticket_reply = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        name = self.sender.username
        if self.text:
            return f'{name}: {self.text[:50]}'
        if self.image:
            return f'{name}: [image]'
        if self.voice:
            return f'{name}: [voice]'
        return f'{name}: [empty]'


class Ticket(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('resolved', 'Resolved'),
    ]
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='tickets'
    )
    question_text = models.TextField()
    exercise_reference = models.CharField(
        max_length=500, blank=True,
        help_text='Reference to the exercise (exam source + question ID)'
    )
    exam_title = models.CharField(
        max_length=300, blank=True,
        help_text='Human-readable exam title (e.g., FMP Oujda 2013)'
    )
    screenshot = models.ImageField(
        upload_to='tickets/screenshots/', blank=True, null=True
    )
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='open'
    )

    # Expert mode fields
    response_text = models.TextField(blank=True)
    responded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='responded_tickets'
    )
    responded_at = models.DateTimeField(null=True, blank=True)
    response_image = models.ImageField(
        upload_to='tickets/responses/', blank=True, null=True
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Ticket #{self.id} by {self.user.username}'


class SavedQuestion(models.Model):
    """AI-generated or saved questions bank — classified by subject."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='saved_questions'
    )
    question_text = models.TextField()
    answer_text = models.TextField(blank=True)
    subject = models.CharField(max_length=100, blank=True)
    is_ai_generated = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        src = 'AI' if self.is_ai_generated else 'User'
        return f'[{src}] {self.subject}: {self.question_text[:60]}'
