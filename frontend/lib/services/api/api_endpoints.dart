import '../../config/environment.dart';

class ApiEndpoints {
  static String get baseUrl => Environment.baseUrl;
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String profile = '/auth/profile/';
  static const String refresh = '/auth/refresh/';
  static const String activate = '/auth/activate/';
  static const String adminCodes = '/auth/admin/codes/';
  static const String adminCodesGenerate = '/auth/admin/codes/generate/';
  static const String chatGroups = '/chat/groups/';
  static const String chatAutoJoin = '/chat/groups/auto-join/';
  static String chatMessages(int groupId) =>
      '/chat/groups/$groupId/messages/';
  static String chatSend(int groupId) =>
      '/chat/groups/$groupId/messages/send/';
  static const String tickets = '/chat/tickets/';
  static const String ticketsCreate = '/chat/tickets/create/';
  static String ticketsReply(int ticketId) =>
      '/chat/tickets/$ticketId/reply/';
  static const String aiSolve = '/ai/solve/';
  static const String aiSimilar = '/ai/similar/';
  static const String aiChat = '/ai/chat/';
  static const String aiOcr = '/ai/ocr/';
  static const String savedQuestions = '/chat/saved/';
  static String savedQuestionDelete(int id) => '/chat/saved/$id/';
}
