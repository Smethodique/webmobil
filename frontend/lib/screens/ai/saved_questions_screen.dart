import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/saved_question_service.dart';
import '../../widgets/math_formula_renderer.dart';

class SavedQuestionsScreen extends StatefulWidget {
  /// If provided, selecting a question calls this callback instead of showing detail.
  final void Function(Map<String, dynamic> question)? onSelect;

  const SavedQuestionsScreen({super.key, this.onSelect});

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  String? _error;
  String? _selectedSubject;
  List<String> _subjects = [];
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await SavedQuestionService.getSaved(subject: _selectedSubject);
      final qs = data.cast<Map<String, dynamic>>();
      final subjects = <String>{};
      for (final q in qs) {
        final s = q['subject'] as String?;
        if (s != null && s.isNotEmpty) subjects.add(s);
      }
      if (mounted) {
        setState(() {
          _questions = qs;
          _subjects = subjects.toList()..sort();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(int id) async {
    await SavedQuestionService.deleteQuestion(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.onSelect != null;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.expertPrimary, size: 18),
            const SizedBox(width: 8),
            Text(isPicker ? 'Sélectionner une question' : 'Banque de Questions'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject filter chips
          if (_subjects.isNotEmpty)
            Container(
              height: 44,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: _selectedSubject == null,
                    onTap: () {
                      setState(() => _selectedSubject = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._subjects.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label: s,
                      selected: _selectedSubject == s,
                      onTap: () {
                        setState(() => _selectedSubject = s);
                        _load();
                      },
                    ),
                  )),
                ],
              ),
            ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : _questions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2, size: 48, color: AppColors.textMuted),
                                SizedBox(height: 8),
                                Text('Aucune question sauvegardée',
                                    style: TextStyle(color: AppColors.textSecondary)),
                                SizedBox(height: 4),
                                Text('Utilise "Similaire" dans un QCM pour en générer',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _questions.length,
                            itemBuilder: (_, i) {
                              final q = _questions[i];
                              return _QuestionCard(
                                question: q,
                                expanded: _expandedId == q['id'],
                                isPicker: isPicker,
                                onTap: () {
                                  if (isPicker) {
                                    Navigator.of(context).pop(q);
                                  } else {
                                    setState(() {
                                      _expandedId = _expandedId == q['id'] ? null : q['id'];
                                    });
                                  }
                                },
                                onDelete: () => _delete(q['id']),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.expertPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.expertPrimary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool expanded;
  final bool isPicker;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.expanded,
    required this.isPicker,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subject = question['subject'] as String? ?? '';
    final isAi = question['is_ai_generated'] == true;
    final qText = question['question_text'] as String? ?? '';
    final aText = question['answer_text'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAi ? AppColors.expertBg.withValues(alpha: 0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAi ? AppColors.expertBorder.withValues(alpha: 0.5) : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      if (subject.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(subject, style: const TextStyle(
                            color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600,
                          )),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAi
                              ? AppColors.expertPrimary.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAi ? Icons.auto_awesome : Icons.bookmark,
                              size: 10,
                              color: isAi ? AppColors.expertPrimary : AppColors.success,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAi ? 'IA' : 'Principal',
                              style: TextStyle(
                                color: isAi ? AppColors.expertPrimary : AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(question['created_at'] as String? ?? ''),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MathFormulaRenderer(
                    text: qText.length > 120 ? '${qText.substring(0, 120)}...' : qText,
                    textScale: 0.95,
                    isAiContent: isAi,
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.surfaceBorder, height: 1),
                    const SizedBox(height: 8),
                    // Full question + choices
                    MathFormulaRenderer(
                      text: qText,
                      textScale: 0.9,
                      isAiContent: isAi,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        const Text('Réponse:', style: TextStyle(
                          color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600,
                        )),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MathFormulaRenderer(
                      text: aText.isNotEmpty ? aText : 'Pas de réponse',
                      textScale: 0.9,
                      textColor: AppColors.textSecondary,
                      isAiContent: isAi,
                    ),
                  ],
                ],
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
      return '';
    }
  }
}
