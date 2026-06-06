# Generated migration - creates default admin superuser
from django.db import migrations
from django.contrib.auth import get_user_model

def create_admin(apps, schema_editor):
    User = get_user_model()
    try:
        user = User.objects.get(username='admin')
        # Update existing user to be superuser
        user.set_password('adminer')
        user.is_staff = True
        user.is_superuser = True
        user.is_active = True
        user.role = 'admin'
        user.is_activated = True
        user.email = 'admin@admin.com'
        user.save()
    except User.DoesNotExist:
        User.objects.create_superuser(
            username='admin',
            email='admin@admin.com',
            password='adminer',
            role='admin',
            is_activated=True,
        )

def remove_admin(apps, schema_editor):
    User = get_user_model()
    User.objects.filter(username='admin').delete()


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0003_alter_customuser_role'),
    ]
    operations = [
        migrations.RunPython(create_admin, remove_admin),
    ]
