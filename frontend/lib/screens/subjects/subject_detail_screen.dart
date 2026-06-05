import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../providers/subject_progress_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/answered_question_service.dart';
import '../qcm/qcm_screen.dart';
import 'answered_questions_screen.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState
    extends ConsumerState<SubjectDetailScreen> {
  int _answeredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAnsweredCount();
  }

  Future<void> _loadAnsweredCount() async {
    final answers =
        await AnsweredQuestionService.forSubject(widget.subject);
    if (!mounted) return;
    setState(() => _answeredCount = answers.length);
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(resultsProvider);
    final overviewAsync = ref.watch(subjectOverviewProvider);
    final examsWithProgressAsync =
        ref.watch(subjectExamsProvider(widget.subject));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: examsWithProgressAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Erreur: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (examItems) {
          if (examItems.isEmpty) {
            return const Center(
              child: Text('Aucun examen trouvé',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final results = resultsAsync.asData?.value ?? {};
          final overview = overviewAsync.valueOrNull?[widget.subject];
          final totalTaux = overview?.taux ?? 0;
          final totalCorrect = overview?.correct ?? 0;
          final totalWrong = overview?.wrong ?? 0;
          final totalUnanswered = overview?.unanswered ?? 0;
          final totalQuestions = overview?.totalQuestions ?? 0;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(totalTaux * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCorrect/$totalQuestions correctes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderBadge('$totalCorrect✓', AppColors.success),
                        const SizedBox(width: 8),
                        _HeaderBadge('$totalWrong✗', AppColors.error),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                            '$totalUnanswered—', Colors.white54),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _answeredCount > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnsweredQuestionsScreen(
                                    subject: widget.subject),
                              ),
                            ).then((_) => _loadAnsweredCount())
                        : null,
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(
                      'Voir mes réponses ($_answeredCount)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: examItems.length,
                  itemBuilder: (ctx, i) {
                    final item = examItems[i];
                    final exam = item.exam;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final result = results[exam.source];
                          final filtered = ExamModel(
                            source: exam.source,
                            questions: exam.questions
                                .where((q) => q.subject == widget.subject)
                                .toList(),
                          );
                          ref
                              .read(quizProvider.notifier)
                              .startExam(filtered, result: result);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const QcmScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.article,
                                        color: AppColors.primary,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.questionCount} question${item.questionCount > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.play_circle_fill,
                                      color: AppColors.primary, size: 28),
                                ],
                              ),
                              if (item.answered != null &&
                                  item.answered! > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _MiniBadge(
                                        '${item.correct ?? 0}✓',
                                        AppColors.success),
                                    const SizedBox(width: 6),
                                    _MiniBadge(
                                        '${(item.answered ?? 0) - (item.correct ?? 0)}✗',
                                        AppColors.error),
                                    const SizedBox(width: 6),
                                    _MiniBadge(
                                        '${item.questionCount - (item.answered ?? 0)}—',
                                        AppColors.textSecondary),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
