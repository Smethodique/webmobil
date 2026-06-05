import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../models/subject_overview.dart';
import '../../providers/subject_progress_provider.dart';
import '../../services/answered_question_service.dart';
import '../../services/progress_service.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matières'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.error),
            tooltip: 'Réinitialiser la progression',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Réinitialiser'),
                  content: const Text(
                    'Effacer toute la progression ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Effacer',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ProgressService.reset();
                await AnsweredQuestionService.reset();
                ref.read(subjectProgressRefreshProvider.notifier).state++;
              }
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Erreur: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('Aucune matière trouvée',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          final list = subjects.entries.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final entry = list[i];
              return _SubjectCard(
                overview: entry.value,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SubjectDetailScreen(subject: entry.key),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectOverview overview;
  final VoidCallback onTap;

  const _SubjectCard({required this.overview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (overview.taux * 100).toStringAsFixed(0);
    final color = overview.taux >= 0.7
        ? AppColors.success
        : overview.taux >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: overview.taux,
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${overview.correct}/${overview.totalQuestions} correctes',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${overview.totalQuestions} Q',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (overview.answered > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                         _Badge('${overview.correct}✓', AppColors.success),
                          const SizedBox(width: 6),
                          _Badge('${overview.wrong}✗', AppColors.error),
                          const SizedBox(width: 6),
                          _Badge('${overview.unanswered}—', AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
