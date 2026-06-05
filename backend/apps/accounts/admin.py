from django.contrib import admin, messages
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, ActivationCode


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'role', 'is_activated', 'is_staff')
    list_filter = ('is_activated', 'role', 'is_staff')
    fieldsets = UserAdmin.fieldsets + (
        ('Role & Activation', {'fields': ('role', 'is_activated')}),
    )


@admin.register(ActivationCode)
class ActivationCodeAdmin(admin.ModelAdmin):
    list_display = ('code', 'is_used', 'created_by', 'used_by', 'created_at', 'used_at')
    list_filter = ('is_used', 'created_at')
    search_fields = ('code', 'created_by__username', 'used_by__username')
    readonly_fields = ('code', 'created_by', 'used_by', 'created_at', 'used_at')
    actions = ['generate_codes']

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
            if not obj.code:
                obj.code = ActivationCode.generate_code()
        super().save_model(request, obj, form, change)

    def generate_codes(self, request, queryset):
        count = request.POST.get('count', 1)
        try:
            count = int(count)
        except (ValueError, TypeError):
            count = 1
        for _ in range(count):
            code_str = ActivationCode.generate_code()
            while ActivationCode.objects.filter(code=code_str).exists():
                code_str = ActivationCode.generate_code()
            ActivationCode.objects.create(
                code=code_str,
                created_by=request.user,
            )
        self.message_user(
            request, f'{count} code(s) generated successfully.',
            messages.SUCCESS,
        )
    generate_codes.short_description = 'Generate activation codes'

    def get_deleted_objects(self, objs, request):
        return super().get_deleted_objects(objs, request)
