from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Group

User = get_user_model()


@receiver(post_save, sender=User)
def add_user_to_groups(sender, instance, created, **kwargs):
    if created:
        for group in Group.objects.all():
            group.members.add(instance)
        # If this is an expert, they also get added to all groups
        if instance.role == 'expert':
            for group in Group.objects.all():
                group.members.add(instance)


@receiver(post_save, sender=Group)
def add_expert_to_new_group(sender, instance, created, **kwargs):
    """When a new group is created, add the expert to it."""
    if created:
        expert = User.objects.filter(role='expert').first()
        if expert and not instance.members.filter(id=expert.id).exists():
            instance.members.add(expert)
