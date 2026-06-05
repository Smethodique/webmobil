import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../models/answered_question.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';
import '../../providers/exam_provider.dart';
import '../../services/answered_question_service.dart';
import '../../widgets/math_formula_renderer.dart';

class AnsweredQuestionsScreen extends ConsumerStatefulWidget {
  final String subject;

  const AnsweredQuestionsScreen({super.key, required this.subject});

  @override
  ConsumerState<AnsweredQuestionsScreen> createState() =>
      _AnsweredQuestionsScreenState();
}

class _AnsweredQuestionsScreenState
    extends ConsumerState<AnsweredQuestionsScreen> {
  List<AnsweredQuestion> _answers = [];
  Map<String, ExamModel> _examMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final answers = await AnsweredQuestionService.forSubject(widget.subject);
    final exams = await ref.read(examsProvider.future);
    final examMap = <String, ExamModel>{};
    for (final e in exams) {
      examMap[e.source] = e;
    }
    if (!mounted) return;
    setState(() {
      _answers = answers.reversed.toList();
      _examMap = examMap;
      _loading = false;
    });
  }

  QuestionModel? _findQuestion(String examSource, String questionId) {
    final exam = _examMap[examSource];
    if (exam == null) return null;
    try {
      return exam.questions.firstWhere((q) => q.id == questionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} — Réponses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _answers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text('Aucune réponse enregistrée',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _answers.length,
                  itemBuilder: (ctx, i) {
                    final a = _answers[i];
                    final q = _findQuestion(a.examSource, a.questionId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  a.isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: a.isCorrect
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Q${a.questionId}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  a.isCorrect ? 'Correct' : 'Faux',
                                  style: TextStyle(
                                    color: a.isCorrect
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (q != null) ...[
                              const SizedBox(height: 8),
                              MathFormulaRenderer(text: q.question),
                              const SizedBox(height: 8),
                              ...List.generate(q.options.length, (j) {
                                final isSelected = j == a.selectedAnswer;
                                final optionLabel =
                                    String.fromCharCode(65 + j);
                                return Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (a.isCorrect
                                            ? AppColors.success
                                            : AppColors.error)
                                        : AppColors.surfaceBorder
                                            .withValues(alpha: 0.3),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? (a.isCorrect
                                              ? AppColors.success
                                              : AppColors.error)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        child: Text(
                                          '$optionLabel.',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          q.options[j],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          a.isCorrect
                                              ? Icons.check
                                              : Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Question non trouvée',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
