import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// Single WebSocket instance shared across the app
final webSocketProvider = Provider<WebSocketService>((ref) {
  final ws = WebSocketService();
  ref.onDispose(() => ws.dispose());
  return ws;
});

// Stream-based connection state that Riverpod can watch for rebuilds
final wsConnectionStateProvider = StreamProvider<WsConnectionState>((ref) {
  final ws = ref.watch(webSocketProvider);
  return ws.connectionStateStream;
});

final groupProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.status != AuthStatus.authenticated) {
    throw Exception('Vous devez être connecté');
  }
  final groups = await ChatService.getGroups();
  if (groups.isEmpty) {
    return await ChatService.autoJoin();
  }
  return groups.first as Map<String, dynamic>;
});

// Current user info for isOwn detection
final currentUserProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.status != AuthStatus.authenticated) return null;
  try {
    return await AuthService.getSession();
  } catch (_) {
    return null;
  }
});

// Raw HTTP messages from API
final httpMessagesProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, int>(
        (ref, groupId) async {
  final res = await ChatService.getMessages(groupId);
  return res.cast<Map<String, dynamic>>();
});

// Merged live messages (HTTP initial + WebSocket real-time)
final liveMessagesProvider =
    StateNotifierProvider.family<LiveMessagesNotifier, List<Map<String, dynamic>>, int>(
        (ref, groupId) {
  return LiveMessagesNotifier(ref, groupId);
});

class LiveMessagesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref _ref;
  final int _groupId;
  StreamSubscription? _wsSubscription;
  bool _httpLoaded = false;

  LiveMessagesNotifier(this._ref, this._groupId) : super([]) {
    _init();
  }

  void _init() {
    // Load HTTP messages first
    _ref.listen(httpMessagesProvider(_groupId), (_, next) {
      next.whenData((httpMessages) {
        _httpLoaded = true;
        _mergeMessages(httpMessages);
      });
    });

    // Listen to WebSocket for real-time messages
    final ws = _ref.read(webSocketProvider);
    _wsSubscription = ws.messageStream.listen(_onWsMessage);
    ws.connect(_groupId);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final msgId = msg['id'];
    final isDuplicate = state.any((m) => m['id'] == msgId);
    if (!isDuplicate) {
      state = [...state, msg];
    }
  }

  void _mergeMessages(List<Map<String, dynamic>> httpMessages) {
    // Add HTTP messages that aren't already in state (from WS)
    final existingIds = state.map((m) => m['id']).toSet();
    final newFromHttp = httpMessages
        .where((m) => !existingIds.contains(m['id']))
        .toList();
    if (newFromHttp.isNotEmpty) {
      state = [...newFromHttp, ...state];
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    String? text,
    String? imagePath,
    String? voicePath,
    List<int>? voiceBytes,
  }) async {
    final sent = await ChatService.sendMessage(
      groupId: _groupId,
      text: text,
      imagePath: imagePath,
      voicePath: voicePath,
      voiceBytes: voiceBytes,
    );
    // Add to state immediately — don't wait for WS broadcast
    final msgId = sent['id'];
    final isDuplicate = state.any((m) => m['id'] == msgId);
    if (!isDuplicate) {
      state = [...state, sent];
    }
    return sent;
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
