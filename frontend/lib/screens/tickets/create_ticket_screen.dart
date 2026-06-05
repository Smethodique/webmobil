import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../models/exam_model.dart';
import '../../providers/ticket_provider.dart';
import '../../services/data_service.dart';
import '../../services/ticket_service.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  final String? prefillQuestion;
  const CreateTicketScreen({super.key, this.prefillQuestion});

  @override
  ConsumerState<CreateTicketScreen> createState() =>
      _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _questionCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _screenshotPath;
  bool _sending = false;
  bool _loadingExams = true;
  List<ExamModel> _exams = [];
  ExamModel? _selectedExam;

  @override
  void initState() {
    super.initState();
    if (widget.prefillQuestion != null) {
      _questionCtrl.text = widget.prefillQuestion!;
    }
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await DataService.loadAllExams();
      if (mounted) {
        setState(() {
          _exams = exams;
          _loadingExams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExams = false);
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _exerciseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _screenshotPath = picked.path);
  }

  Future<void> _captureScreenshot() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _screenshotPath = picked.path);
  }

  String _getExamTitle(ExamModel exam) {
    return exam.title;
  }

  String _getExamSubtitle(ExamModel exam) {
    return '${exam.totalQuestions} questions • ${exam.subjects.join(", ")}';
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire votre question')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await TicketService.createTicket(
        questionText: question,
        exerciseReference: _exerciseCtrl.text.trim(),
        examTitle: _selectedExam != null ? _getExamTitle(_selectedExam!) : null,
        screenshotPath: _screenshotPath,
      );
      ref.read(ticketRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket vers Expert'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.expertPrimary, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Envoyer un ticket à l'expert",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                      Text("Décrivez votre problème",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exam selector
            const Text("Concours / Examen",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            _loadingExams
                ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ExamModel>(
                        value: _selectedExam,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary),
                        ),
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Sélectionner un concours...',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              )),
                        ),
                        items: _exams.map((exam) {
                          return DropdownMenuItem<ExamModel>(
                            value: exam,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getExamTitle(exam),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _getExamSubtitle(exam),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (exam) {
                          setState(() => _selectedExam = exam);
                        },
                      ),
                    ),
                  ),
            if (_selectedExam != null) ...[
              const SizedBox(height: 4),
              Text(
                'Titre du ticket: "${_getExamTitle(_selectedExam!)}"',
                style: const TextStyle(
                  color: AppColors.expertPrimary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Question
            const Text("Votre question",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            TextField(
              controller: _questionCtrl,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Décrivez votre question...',
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
            const SizedBox(height: 16),

            // Exercise reference
            const Text("Référence de l'exercice (optionnel)",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            TextField(
              controller: _exerciseCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ex: Q05 — Suite intégrale',
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
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Screenshot
            const Text("Capture d'écran (optionnel)",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickScreenshot,
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _captureScreenshot,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            if (_screenshotPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_screenshotPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _screenshotPath = null),
                icon:
                    const Icon(Icons.close, size: 16, color: AppColors.error),
                label: const Text('Supprimer',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
            const SizedBox(height: 24),
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
                label: Text(_sending ? 'Envoi...' : 'Envoyer le ticket'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.expertPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.expertPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
