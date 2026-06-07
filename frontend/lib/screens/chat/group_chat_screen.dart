import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import '../../config/environment.dart';
import '../../constants/colors.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';

String _absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final host = Environment.baseUrl.replaceFirst('/api/v1', '');
  return '$host$path';
}

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  StreamSubscription? _playerStateSub;
  StreamSubscription<List<int>>? _audioStreamSub;
  Completer<List<int>>? _recordCompleter;
  final List<int> _audioBytes = [];
  String? _webRecordPath; // Web: file path for recording
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSending = false;
  int? _currentUserId;
  bool _autoScroll = true;
  bool _wasAtBottom = true;

  // Audio recording duration tracking
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  static const int _minRecordSeconds = 2;
  static const int _maxRecordSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _scrollController.addListener(_onScroll);
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await AuthService.getCurrentUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (_wasAtBottom != atBottom) {
      setState(() {
        _wasAtBottom = atBottom;
        _autoScroll = atBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _audioStreamSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(groupProvider);
    }
  }

  Future<void> _sendMessage({
    required int groupId,
    String? text,
    String? imagePath,
    String? voicePath,
    List<int>? voiceBytes,
  }) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await ref.read(liveMessagesProvider(groupId).notifier).sendMessage(
        text: text,
        imagePath: imagePath,
        voicePath: voicePath,
        voiceBytes: voiceBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage(int groupId) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _sendMessage(groupId: groupId, imagePath: picked.path);
  }

  Future<void> _takePhoto(int groupId) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _sendMessage(groupId: groupId, imagePath: picked.path);
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  void _startRecordTimer(int groupId) {
    _recordStartTime = DateTime.now();
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_recordStartTime!).inSeconds;
      setState(() => _recordSeconds = elapsed);
      // Auto-stop at max duration
      if (elapsed >= _maxRecordSeconds) {
        _toggleRecord(groupId);
      }
    });
  }

  String _formatRecordTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleRecord(int groupId) async {
    if (_isRecording) {
      // STOP recording
      final recordedSeconds = _recordSeconds;
      _stopRecordTimer();
      try {
        await _audioRecorder.stop();
        List<int> bytes;
        if (kIsWeb && _webRecordPath != null) {
          // Web: read recorded file
          final file = File(_webRecordPath!);
          bytes = await file.readAsBytes();
          _webRecordPath = null;
        } else if (_recordCompleter != null) {
          bytes = await _recordCompleter!.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () => List<int>.from(_audioBytes),
          );
          _recordCompleter = null;
        } else {
          bytes = List<int>.from(_audioBytes);
        }
        await _audioStreamSub?.cancel();
        _audioBytes.clear();

        // Check minimum duration
        if (recordedSeconds < _minRecordSeconds) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vocal trop court (minimum 2 secondes)'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } else if (bytes.isNotEmpty) {
          await _sendMessage(groupId: groupId, voiceBytes: bytes);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("L'enregistrement n'a pas produit de fichier"),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      if (mounted) setState(() => _isRecording = false);
    } else {
      // START recording
      try {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission microphone refusée'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        _audioBytes.clear();
        _recordCompleter = Completer<List<int>>();

        if (kIsWeb) {
          // Web: record to temp file (stream not supported on web)
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          _webRecordPath = path;
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          _recordCompleter!.complete([0]); // placeholder, real bytes read on stop
        } else {
          // Native: use stream
          final stream = await _audioRecorder.startStream(
            const RecordConfig(encoder: AudioEncoder.aacLc),
          );
          _audioStreamSub = stream.listen(
            (data) => _audioBytes.addAll(data),
            onDone: () {
              if (_recordCompleter != null && !_recordCompleter!.isCompleted) {
                _recordCompleter!.complete(List<int>.from(_audioBytes));
              }
            },
            onError: (e) {
              if (_recordCompleter != null && !_recordCompleter!.isCompleted) {
                _recordCompleter!.completeError(e);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          );
        }
        _startRecordTimer(groupId);
        if (mounted) setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur micro: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _playVoice(String url) {
    if (_isPlaying) {
      _audioPlayer.stop();
    } else {
      _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _sendText(int groupId) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _sendMessage(groupId: groupId, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g['name'] as String? ?? 'Chat'),
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: groupAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text('Impossible de charger le groupe',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text('$e'.replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(groupProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (group) {
          final groupId = group['id'] as int;
          return Column(
            children: [
              // Connection status indicator
              _ConnectionBanner(groupId: groupId),
              Expanded(
                child: _MessageList(
                  groupId: groupId,
                  playVoice: _playVoice,
                  currentUserId: _currentUserId,
                  isPlaying: _isPlaying,
                  scrollController: _scrollController,
                  onMessagesChanged: _scrollToBottom,
                ),
              ),
              _buildInputBar(groupId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputBar(int groupId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.textSecondary),
            onPressed: () => _showAttachmentOptions(groupId),
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Votre message...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: (_) => _sendText(groupId),
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary,
                ),
              ),
            )
          else ...[
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatRecordTime(_recordSeconds),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.stop_circle,
                          color: AppColors.error, size: 28),
                      onPressed: () => _toggleRecord(groupId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.mic,
                    color: AppColors.textSecondary),
                onPressed: () => _toggleRecord(groupId),
              ),
            if (!_isRecording)
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: () => _sendText(groupId),
              ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentOptions(int groupId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachButton(
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(groupId);
                },
              ),
              _AttachButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto(groupId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Connection status banner
class _ConnectionBanner extends ConsumerWidget {
  final int groupId;
  const _ConnectionBanner({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(webSocketProvider);
    final stateAsync = ref.watch(wsConnectionStateProvider);
    final state = stateAsync.valueOrNull ?? WsConnectionState.disconnected;

    if (state == WsConnectionState.connected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: state == WsConnectionState.reconnecting
          ? AppColors.warning.withValues(alpha: 0.9)
          : AppColors.error.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state == WsConnectionState.connecting ||
              state == WsConnectionState.reconnecting)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,
              ),
            )
          else
            const Icon(Icons.cloud_off, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            state == WsConnectionState.connecting
                ? 'Connexion...'
                : state == WsConnectionState.reconnecting
                    ? 'Reconnexion...'
                    : 'Déconnecté',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (state == WsConnectionState.disconnected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ws.connect(groupId),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  final int groupId;
  final void Function(String url) playVoice;
  final int? currentUserId;
  final bool isPlaying;
  final ScrollController scrollController;
  final VoidCallback onMessagesChanged;

  const _MessageList({
    required this.groupId,
    required this.playVoice,
    required this.currentUserId,
    this.isPlaying = false,
    required this.scrollController,
    required this.onMessagesChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(liveMessagesProvider(groupId));
    final httpAsync = ref.watch(httpMessagesProvider(groupId));

    // Notify about message changes for auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onMessagesChanged();
    });

    // Show loading while HTTP messages are being fetched
    if (httpAsync.isLoading && messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Show error only if both HTTP failed AND WS has no messages
    if (httpAsync.hasError && messages.isEmpty) {
      return Center(
        child: Text(
          'Erreur: ${httpAsync.error}',
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    if (messages.isEmpty) {
      return ListView(
        controller: scrollController,
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('Aucun message',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final isOwn = currentUserId != null &&
            m['sender'] == currentUserId;
        return _MessageBubble(
          message: m,
          playVoice: playVoice,
          isOwn: isOwn,
          isPlaying: isPlaying,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final void Function(String url) playVoice;
  final bool isOwn;
  final bool isPlaying;

  const _MessageBubble({
    required this.message,
    required this.playVoice,
    required this.isOwn,
    this.isPlaying = false,
  });

  bool get _isTicket => message['is_ticket'] == true;
  bool get _isTicketReply => message['is_ticket_reply'] == true;
  String get _senderRole => message['sender_role'] as String? ?? 'student';
  bool get _isExpert => _senderRole == 'expert';

  Color get _bubbleBg {
    if (_isTicket) return AppColors.ticketBg;
    if (_isTicketReply) return AppColors.expertReplyBg;
    if (_isExpert) return AppColors.expertBg;
    if (isOwn) return AppColors.primary.withValues(alpha: 0.15);
    return AppColors.surface;
  }

  Color get _bubbleBorder {
    if (_isTicket) return AppColors.ticketBorder;
    if (_isTicketReply) return AppColors.expertReplyBorder;
    if (_isExpert) return AppColors.expertBorder;
    if (isOwn) return AppColors.primary.withValues(alpha: 0.3);
    return AppColors.surfaceBorder;
  }

  Color get _senderColor {
    if (_isTicket) return AppColors.ticketColor;
    if (_isTicketReply) return AppColors.expertReplyColor;
    if (_isExpert) return AppColors.expertPrimary;
    if (isOwn) return AppColors.primary;
    return AppColors.textSecondary;
  }

  Color? get _iconColor {
    if (_isTicket) return AppColors.ticketColor;
    if (_isTicketReply) return AppColors.expertReplyColor;
    if (_isExpert) return AppColors.expertPrimary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final text = message['text'] as String?;
    final image = message['image'] as String?;
    final voice = message['voice'] as String?;
    final sender = message['sender_username'] as String? ?? 'Inconnu';
    final createdAt = message['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTicket)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.confirmation_number, size: 12, color: AppColors.ticketColor),
                  ),
                if (_isTicketReply)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.reply, size: 12, color: AppColors.expertReplyColor),
                  ),
                if (_isExpert && !_isTicketReply)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.verified, size: 12, color: AppColors.expertPrimary),
                  ),
                Text(
                  _isTicketReply
                      ? '$sender (Expert)'
                      : _isExpert
                          ? '$sender (Expert)'
                          : isOwn
                              ? 'Vous'
                              : sender,
                  style: TextStyle(
                    color: _senderColor,
                    fontSize: 11,
                    fontWeight: (_isTicket || _isTicketReply || _isExpert || isOwn)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (_isTicket) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Ticket',
                    style: TextStyle(
                      color: AppColors.ticketColor.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft:
                    isOwn && !_isTicket && !_isTicketReply && !_isExpert
                        ? const Radius.circular(12)
                        : Radius.zero,
                bottomRight:
                    isOwn && !_isTicket && !_isTicketReply && !_isExpert
                        ? Radius.zero
                        : const Radius.circular(12),
              ),
              border: Border.all(color: _bubbleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text != null && text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        )),
                  ),
                if (image != null && image.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _absoluteUrl(image),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                if (voice != null && voice.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle_fill,
                          color: _iconColor,
                        ),
                        onPressed: () => playVoice(_absoluteUrl(voice)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPlaying ? 'Lecture...' : 'Message vocal',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_formatTime(createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}
