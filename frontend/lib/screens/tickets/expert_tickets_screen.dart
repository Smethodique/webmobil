import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/environment.dart';
import '../../constants/colors.dart';
import '../../providers/ticket_provider.dart';
import '../../services/ticket_service.dart';
import '../ai/saved_questions_screen.dart';

String _absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final host = Environment.baseUrl.replaceFirst('/api/v1', '');
  return '$host$path';
}

class ExpertTicketsScreen extends ConsumerStatefulWidget {
  const ExpertTicketsScreen({super.key});

  @override
  ConsumerState<ExpertTicketsScreen> createState() =>
      _ExpertTicketsScreenState();
}

class _ExpertTicketsScreenState extends ConsumerState<ExpertTicketsScreen> {
  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: AppColors.expertPrimary, size: 20),
            SizedBox(width: 8),
            Text('Mode Expert'),
          ],
        ),
        backgroundColor: AppColors.expertBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2, color: AppColors.expertPrimary),
            tooltip: 'Banque de questions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SavedQuestionsScreen(
                    onSelect: (q) {
                      // Pre-fill a reply with this question
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(userTicketsProvider),
          ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.expertPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Erreur: $e',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(userTicketsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (tickets) {
          final openTickets =
              tickets.where((t) => t['status'] == 'open').toList();
          final resolvedTickets =
              tickets.where((t) => t['status'] == 'resolved').toList();

          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Aucun ticket',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (openTickets.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.ticketBg,
                  child: Row(
                    children: [
                      const Icon(Icons.priority_high,
                          color: AppColors.ticketColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tickets ouverts (${openTickets.length})',
                        style: const TextStyle(
                          color: AppColors.ticketColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: openTickets.length + resolvedTickets.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) {
                      if (i < openTickets.length) {
                        return _TicketCard(
                          ticket: openTickets[i],
                          onReply: () => _showReplyDialog(openTickets[i]),
                        );
                      }
                      final resolvedIndex = i - openTickets.length;
                      return _TicketCard(
                        ticket: resolvedTickets[resolvedIndex],
                        isResolved: true,
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: ListView.builder(
                    itemCount: resolvedTickets.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) {
                      return _TicketCard(
                        ticket: resolvedTickets[i],
                        isResolved: true,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showReplyDialog(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ReplySheet(ticket: ticket),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool isResolved;
  final VoidCallback? onReply;

  const _TicketCard({
    required this.ticket,
    this.isResolved = false,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final user = ticket['user_username'] as String? ?? 'Inconnu';
    final question = ticket['question_text'] as String? ?? '';
    final screenshot = ticket['screenshot'] as String?;
    final exercise = ticket['exercise_reference'] as String?;
    final createdAt = ticket['created_at'] as String? ?? '';
    final responseText = ticket['response_text'] as String?;
    final respondedBy = ticket['responded_by_username'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isResolved ? AppColors.surface : AppColors.ticketBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResolved ? AppColors.surfaceBorder : AppColors.ticketBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(
                  isResolved ? Icons.check_circle : Icons.confirmation_number,
                  color: isResolved
                      ? AppColors.success
                      : AppColors.ticketColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isResolved ? '$user (Résolu)' : '$user',
                    style: TextStyle(
                      color: isResolved
                          ? AppColors.textSecondary
                          : AppColors.ticketColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Question
          if (question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  )),
            ),
          // Exercise reference
          if (exercise != null && exercise.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text('Ref: $exercise',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  )),
            ),
          // Screenshot
          if (screenshot != null && screenshot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _absoluteUrl(screenshot),
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
          // Expert response
          if (responseText != null && responseText.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.expertReplyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.expertReplyBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply,
                          color: AppColors.expertReplyColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Réponse${respondedBy != null ? ' ($respondedBy)' : ''}',
                        style: const TextStyle(
                          color: AppColors.expertReplyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(responseText,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          // Reply button for open tickets
          if (!isResolved && onReply != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Répondre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expertPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reply bottom sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _ReplySheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> ticket;
  const _ReplySheet({required this.ticket});

  @override
  ConsumerState<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<_ReplySheet> {
  final _responseCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  bool _sending = false;

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _submit() async {
    final text = _responseCtrl.text.trim();
    if (text.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez un texte ou une image')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await TicketService.replyToTicket(
        ticketId: widget.ticket['id'] as int,
        responseText: text.isNotEmpty ? text : null,
        responseImagePath: _imagePath,
      );
      ref.read(ticketRefreshProvider.notifier).state++;
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réponse envoyée'),
            backgroundColor: AppColors.success,
          ),
        );
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
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final user = ticket['user_username'] as String? ?? 'Inconnu';
    final question = ticket['question_text'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ticket summary
          Row(
            children: [
              const Icon(Icons.confirmation_number,
                  color: AppColors.ticketColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Répondre à $user',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          if (question.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.ticketBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ticketBorder),
              ),
              child: Text(question,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  )),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _responseCtrl,
            maxLines: 4,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Votre réponse...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.expertPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          // Image picker
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, size: 16),
                label: const Text('Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _imagePath!.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: const Icon(Icons.close, color: AppColors.error, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Envoi...' : 'Envoyer la réponse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expertPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor:
                    AppColors.expertPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
