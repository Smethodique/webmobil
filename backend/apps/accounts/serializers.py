from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import CustomUser, ActivationCode


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=4)

    class Meta:
        model = CustomUser
        fields = ('id', 'username', 'password', 'role')
        extra_kwargs = {'role': {'required': False}}

    def validate_username(self, value):
        if CustomUser.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError('Username already exists')
        return value

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            role=validated_data.get('role', 'student'),
        )
        return user


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, data):
        user = authenticate(username=data['username'], password=data['password'])
        if user is None:
            raise serializers.ValidationError('Invalid username or password')
        if not user.is_active:
            raise serializers.ValidationError('Account is disabled')
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('id', 'username', 'role', 'is_activated')


class ActivateSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=14)

    def validate_code(self, value):
        try:
            code = ActivationCode.objects.get(code=value.upper(), is_used=False)
        except ActivationCode.DoesNotExist:
            raise serializers.ValidationError('Invalid or already used activation code')
        return code


class ActivationCodeSerializer(serializers.ModelSerializer):
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    used_by_username = serializers.CharField(source='used_by.username', read_only=True, allow_null=True)

    class Meta:
        model = ActivationCode
        fields = (
            'id', 'code', 'is_used', 'created_by', 'created_by_username',
            'used_by', 'used_by_username', 'created_at', 'used_at',
        )
        read_only_fields = (
            'id', 'code', 'is_used', 'created_by', 'created_by_username',
            'used_by', 'used_by_username', 'created_at', 'used_at',
        )
