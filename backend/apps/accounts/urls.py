from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('refresh/', TokenRefreshView.as_view(), name='refresh'),
    path('activate/', views.ActivateView.as_view(), name='activate'),
    path('admin/codes/', views.AdminCodeListView.as_view(), name='admin-codes-list'),
    path('admin/codes/generate/', views.AdminCodeCreateView.as_view(), name='admin-codes-generate'),
]
