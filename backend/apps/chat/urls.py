from django.urls import path
from . import views

urlpatterns = [
    path('groups/', views.GroupListView.as_view(), name='chat-groups'),
    path('groups/auto-join/', views.AutoJoinView.as_view(), name='chat-auto-join'),
    path('groups/<int:group_id>/messages/',
         views.GroupMessagesView.as_view(), name='chat-messages'),
    path('groups/<int:group_id>/messages/send/',
         views.SendMessageView.as_view(), name='chat-send'),
    path('tickets/', views.UserTicketsView.as_view(), name='tickets-list'),
    path('tickets/create/', views.CreateTicketView.as_view(), name='tickets-create'),
    path('tickets/<int:ticket_id>/reply/',
         views.ExpertTicketReplyView.as_view(), name='tickets-reply'),
    path('saved/', views.SavedQuestionListCreateView.as_view(), name='saved-list'),
    path('saved/<int:pk>/', views.SavedQuestionDeleteView.as_view(), name='saved-delete'),
]
