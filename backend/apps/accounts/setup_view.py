# TEMPORARY - will be removed
from django.http import JsonResponse
from django.contrib.auth import get_user_model

User = get_user_model()

def setup_admin(request):
    if User.objects.filter(username='admin').exists():
        user = User.objects.get(username='admin')
        user.set_password('adminer')
        user.is_staff = True
        user.is_superuser = True
        user.role = 'admin'
        user.is_activated = True
        user.email = 'admin@admin.com'
        user.save()
        return JsonResponse({'status': 'updated'})
    User.objects.create_superuser(
        username='admin',
        email='admin@admin.com',
        password='adminer',
        role='admin',
        is_activated=True,
    )
    return JsonResponse({'status': 'created'})
