import hashlib
import uuid
from django.contrib.auth.models import AbstractUser
from django.conf import settings
from django.db import models


class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('student', 'Student'),
        ('admin', 'Admin'),
        ('expert', 'Expert'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='student')
    is_activated = models.BooleanField(default=False)

    def __str__(self):
        return self.username


class ActivationCode(models.Model):
    code = models.CharField(max_length=14, unique=True)
    created_by = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='generated_codes'
    )
    used_by = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='used_code'
    )
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    used_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.code

    @staticmethod
    def generate_code():
        from django.utils import timezone
        now = timezone.now()
        seed = (
            f"{now.timestamp()}-{now.microsecond}"
            f"-{uuid.uuid4()}-{settings.SECRET_KEY}"
        )
        raw = hashlib.sha256(seed.encode()).hexdigest()[:12].upper()
        return '-'.join(raw[i:i + 4] for i in range(0, 12, 4))
