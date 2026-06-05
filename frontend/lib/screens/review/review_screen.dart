import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../models/result_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/math_formula_renderer.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    if (quizState == null || !quizState.submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.review)),
        body: const Center(child: Text(AppStrings.noExams)),
      );
    }

    final correctCount = quizState.correctCount;
    final total = quizState.exam.questions.length;
    final hasResult = quizState.result != null;
    final answered = quizState.answeredCount;
    final totalSecs = quizState.endTimeSeconds ?? 0;
    final avgSecs = answered > 0 ? totalSecs ~/ answered : 0;
    final avgMinutes = avgSecs ~/ 60;
    final avgSeconds = avgSecs % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.examResults),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            ref.read(quizProvider.notifier).reset();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _PerformanceCard(
              correctCount: correctCount,
              total: total,
              avgMinutes: avgMinutes,
              avgSeconds: avgSeconds,
              hasResult: hasResult,
              answered: answered,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(AppStrings.review,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (hasResult)
                    Text(
                      '$correctCount/$total correct',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(quizState.exam.questions.length, (i) {
              final q = quizState.exam.questions[i];
              final userAnswer = quizState.answers[q.id];
              final isCorrect = quizState.correctness[q.id];
              return _QuestionReviewCard(
                index: i,
                question: q.question,
                subject: q.subject,
                options: q.options,
                userAnswer: userAnswer,
                isCorrect: isCorrect,
                hasResult: hasResult,
                isBookmarked: quizState.bookmarked.contains(q.id),
                result: quizState.result,
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final int correctCount;
  final int total;
  final int avgMinutes;
  final int avgSeconds;
  final bool hasResult;
  final int answered;

  const _PerformanceCard({
    required this.correctCount,
    required this.total,
    required this.avgMinutes,
    required this.avgSeconds,
    required this.hasResult,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final rate = hasResult && total > 0 ? (correctCount / total) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
                hasResult ? AppStrings.score : AppStrings.answered,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                )),
            const SizedBox(height: 8),
            Text(
              hasResult
                  ? '$correctCount / $total'
                  : '$answered / $total',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasResult) ...[
              const SizedBox(height: 4),
              Icon(
                rate >= 0.5 ? Icons.check_circle : Icons.info_outline,
                color: rate >= 0.5 ? AppColors.success : AppColors.warning,
                size: 28,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  label: hasResult ? AppStrings.accuracy : AppStrings.answered,
                  value: hasResult
                      ? '${(rate * 100).toStringAsFixed(0)}%'
                      : '$answered/$total',
                  color: hasResult ? AppColors.success : AppColors.primary,
                ),
                _StatItem(
                  icon: Icons.timer,
                  label: 'Moy/Q',
                  value:
                      '${avgMinutes.toString().padLeft(2, '0')}:${avgSeconds.toString().padLeft(2, '0')}',
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final String question;
  final String subject;
  final List<String> options;
  final int? userAnswer;
  final bool? isCorrect;
  final bool hasResult;
  final bool isBookmarked;
  final ResultModel? result;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.subject,
    required this.options,
    required this.userAnswer,
    required this.isCorrect,
    required this.hasResult,
    required this.isBookmarked,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswer = userAnswer != null;
    final answerLetter =
        hasAnswer ? String.fromCharCode(65 + userAnswer!) : '-';

    Color leftBorderColor;
    if (!hasResult) {
      leftBorderColor = hasAnswer
          ? AppColors.primary.withValues(alpha: 0.5)
          : AppColors.surfaceBorder;
    } else if (isCorrect == true) {
      leftBorderColor = AppColors.success;
    } else if (isCorrect == false && hasAnswer) {
      leftBorderColor = AppColors.error;
    } else {
      leftBorderColor = AppColors.surfaceBorder;
    }

    Color dotColor;
    if (!hasResult) {
      dotColor = hasAnswer
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.error.withValues(alpha: 0.2);
    } else if (isCorrect == true) {
      dotColor = AppColors.success.withValues(alpha: 0.2);
    } else if (isCorrect == false && hasAnswer) {
      dotColor = AppColors.error.withValues(alpha: 0.2);
    } else {
      dotColor = AppColors.surfaceBorder.withValues(alpha: 0.3);
    }

    Color dotTextColor;
    if (!hasResult) {
      dotTextColor = hasAnswer ? AppColors.primary : AppColors.error;
    } else if (isCorrect == true) {
      dotTextColor = AppColors.success;
    } else if (isCorrect == false && hasAnswer) {
      dotTextColor = AppColors.error;
    } else {
      dotTextColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: leftBorderColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasAnswer
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Q${index + 1}',
                        style: TextStyle(
                          color: hasAnswer
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(subject,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        )),
                  ),
                  if (isBookmarked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.bookmark,
                        size: 14, color: AppColors.warning),
                  ],
                  const Spacer(),
                  if (hasResult && hasAnswer)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCorrect == true)
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                        if (isCorrect == false)
                          const Icon(Icons.cancel,
                              size: 16, color: AppColors.error),
                      ],
                    ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(answerLetter,
                          style: TextStyle(
                            color: dotTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MathFormulaRenderer(text: question),

            ],
          ),
        ),
      ),
    );
  }

}
