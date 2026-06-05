from django.urls import path
from . import views

urlpatterns = [
    path('solve/', views.SolveQuestionView.as_view(), name='ai-solve'),
    path('similar/', views.GenerateSimilarView.as_view(), name='ai-similar'),
    path('chat/', views.AiChatView.as_view(), name='ai-chat'),
    path('ocr/', views.OcrView.as_view(), name='ai-ocr'),
]
