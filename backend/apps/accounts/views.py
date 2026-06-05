from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from .models import ActivationCode
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    ActivateSerializer, ActivationCodeSerializer,
)


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            UserSerializer(user).data,
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data,
        })


class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)


class ActivateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if request.user.is_activated:
            return Response(
                {'detail': 'Account is already activated'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = ActivateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.validated_data['code']
        code.is_used = True
        code.used_by = request.user
        code.used_at = code.created_at  # actually update to now
        from django.utils import timezone
        code.used_at = timezone.now()
        code.save()
        request.user.is_activated = True
        request.user.save()
        return Response({'detail': 'Account activated successfully'})


class AdminCodeListView(generics.ListAPIView):
    queryset = ActivationCode.objects.all().order_by('-created_at')
    serializer_class = ActivationCodeSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminCodeCreateView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        count = request.data.get('count', 1)
        codes = []
        for _ in range(count):
            code_str = ActivationCode.generate_code()
            while ActivationCode.objects.filter(code=code_str).exists():
                code_str = ActivationCode.generate_code()
            code = ActivationCode.objects.create(
                code=code_str,
                created_by=request.user,
            )
            codes.append(ActivationCodeSerializer(code).data)
        return Response({'codes': codes}, status=status.HTTP_201_CREATED)
