import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/environment.dart';
import 'api/token_storage.dart';

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;
  static const int _heartbeatInterval = 25;
  int? _groupId;

  WsConnectionState _connectionState = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _connectionState;

  late final StreamController<Map<String, dynamic>> _messageController;
  late final StreamController<WsConnectionState> _connectionStateController;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<WsConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  WebSocketService() {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _connectionStateController = StreamController<WsConnectionState>.broadcast(
      onListen: () {
        _connectionStateController.add(_connectionState);
      },
    );
  }

  void _setState(WsConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  Future<void> connect(int groupId) async {
    _groupId = groupId;
    // Clean up any existing connection WITHOUT clearing _groupId
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_groupId == null) return;

    if (_reconnectAttempts == 0) {
      _setState(WsConnectionState.connecting);
    } else {
      _setState(WsConnectionState.reconnecting);
    }

    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
      return;
    }

    final baseUrl = Environment.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('/api/v1', '');
    final uri = Uri.parse('$baseUrl/ws/chat/$_groupId/?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final msg = json.decode(data as String) as Map<String, dynamic>;
            if (msg['type'] == 'pong') return; // Ignore heartbeat responses
            _messageController.add(msg);
          } catch (_) {}
        },
        onError: (e) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_groupId == null) return;

    _reconnectAttempts++;
    final delay = min(
      pow(2, min(_reconnectAttempts, 5)).toInt(),
      _maxReconnectDelay,
    );

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_groupId != null) {
        _doConnect();
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (_) {
        try {
          _channel?.sink.add(json.encode({'type': 'ping'}));
        } catch (_) {
          _handleDisconnect();
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> disconnect() async {
    _groupId = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
