from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Create admin superuser'

    def handle(self, *args, **options):
        if User.objects.filter(username='admin').exists():
            user = User.objects.get(username='admin')
            user.set_password('adminer')
            user.is_staff = True
            user.is_superuser = True
            user.role = 'admin'
            user.is_activated = True
            user.email = 'admin@admin.com'
            user.save()
            self.stdout.write('Admin updated')
        else:
            User.objects.create_superuser(
                username='admin',
                email='admin@admin.com',
                password='adminer',
                role='admin',
                is_activated=True,
            )
            self.stdout.write('Admin created')
