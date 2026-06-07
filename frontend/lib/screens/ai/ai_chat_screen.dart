import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../services/ai_service.dart';
import '../../widgets/math_formula_renderer.dart';
import 'saved_questions_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _scrollCtrl = ScrollController();
  final List<String> _imagePaths = [];
  final List<Uint8List> _imageBytesList = [];
  bool _loading = false;
  bool _ocrLoading = false;
  String? _result;
  final List<_ChatEntry> _history = [];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() {
      _imagePaths.add(picked.path);
      _ocrLoading = true;
    });

    // Read bytes on web (blob URLs can't use fromFile)
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      _imageBytesList.add(Uint8List.fromList(bytes));
    }

    // OCR all images and combine text
    final ocrParts = <String>[];
    for (int i = 0; i < _imagePaths.length; i++) {
      try {
        final path = _imagePaths[i];
        final bytes = kIsWeb && i < _imageBytesList.length
            ? _imageBytesList[i]
            : null;
        final ocrText = await AiService.ocrImage(
          imagePath: path,
          imageBytes: bytes,
        );
        if (ocrText != null && ocrText.isNotEmpty) {
          ocrParts.add(ocrText);
        }
      } catch (_) {}
    }

    if (mounted) {
      final existing = _textCtrl.text.trim();
      final combined = ocrParts.join('\n---\n');
      setState(() {
        if (existing.isNotEmpty) {
          _textCtrl.text = '$existing\n\n$combined';
        } else {
          _textCtrl.text = combined;
        }
        _ocrLoading = false;
      });
      if (ocrParts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR échoué — écris ta question'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    if (_loading) return;

    final hasImages = _imagePaths.isNotEmpty;
    setState(() {
      _loading = true;
      _result = null;
      _history.add(_ChatEntry(
        text: text,
        isUser: true,
        imageCount: _imagePaths.length,
      ));
    });

    _textCtrl.clear();
    setState(() {
      _imagePaths.clear();
      _imageBytesList.clear();
    });

    try {
      final result = await AiService.aiChat(text: text);
      if (mounted) {
        setState(() {
          _result = result;
          _history.add(_ChatEntry(text: result, isUser: false));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Erreur: $e';
          _history.add(_ChatEntry(text: 'Erreur: $e', isUser: false));
          _loading = false;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.expertPrimary, size: 20),
            SizedBox(width: 8),
            Text('Assistant IA Math'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.expertBg,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.expertPrimary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo + exo sauvegardé — IA analyse',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Chat history
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 48, color: AppColors.expertPrimary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Photo, exo sauvegardé, ou décris ton exercice',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mathématiques — Bac scientifique marocain',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final entry = _history[i];
                      return _ChatBubble(entry: entry);
                    },
                  ),
          ),
          // Loading indicator
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.expertPrimary),
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Column(
              children: [
                // Image previews (multiple)
                if (_imagePaths.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePaths[i]),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_ocrLoading)
                            const Positioned.fill(
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.expertPrimary),
                              ),
                            ),
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: AppColors.textSecondary),
                      onPressed: () => _pickImage(ImageSource.camera),
                      tooltip: 'Photo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: AppColors.textSecondary),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      tooltip: 'Galerie',
                    ),
                    IconButton(
                      icon: const Icon(Icons.inventory_2, color: AppColors.expertPrimary),
                      tooltip: 'Exercice sauvegardé',
                      onPressed: () async {
                        final result = await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (_) => SavedQuestionsScreen(
                              onSelect: (q) => Navigator.of(context).pop(q),
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          final qText = result['question_text'] as String? ?? '';
                          final existing = _textCtrl.text.trim();
                          setState(() {
                            if (existing.isNotEmpty) {
                              _textCtrl.text = '$existing\n\n---\n$qText';
                            } else {
                              _textCtrl.text = qText;
                            }
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Ton message...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.expertPrimary),
                      onPressed: _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final String text;
  final bool isUser;
  final int imageCount;
  const _ChatEntry({required this.text, required this.isUser, this.imageCount = 0});
}

class _ChatBubble extends StatelessWidget {
  final _ChatEntry entry;
  const _ChatBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            entry.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            entry.isUser ? 'Vous' : 'IA Math',
            style: TextStyle(
              color: entry.isUser ? AppColors.primary : AppColors.expertPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.isUser
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.expertBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: entry.isUser ? const Radius.circular(12) : Radius.zero,
                bottomRight: entry.isUser ? Radius.zero : const Radius.circular(12),
              ),
              border: Border.all(
                color: entry.isUser
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.expertBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.imageCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('${entry.imageCount} photo(s)',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 10)),
                      ],
                    ),
                  ),
                MathFormulaRenderer(
                  text: entry.text,
                  textScale: 1.0,
                  isAiContent: !entry.isUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
