import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../models/exam_model.dart';
import '../../models/result_model.dart';
import '../../providers/exam_provider.dart';
import '../../providers/quiz_provider.dart';
import '../chat/group_chat_screen.dart';
import '../qcm/qcm_screen.dart';
import '../profile/profile_screen.dart';
import '../subjects/subjects_screen.dart';
import '../tickets/create_ticket_screen.dart';
import '../tickets/expert_tickets_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../ai/saved_questions_screen.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);
    final resultsAsync = ref.watch(resultsProvider);
    final auth = ref.watch(authProvider);
    final isExpert = auth.role == 'expert';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        leading: isExpert
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.expertPrimary, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified, color: Colors.white, size: 18),
                  ),
                ),
              )
            : null,
        actions: [
          if (isExpert)
            IconButton(
              icon: const Icon(Icons.support_agent,
                  color: AppColors.expertPrimary),
              tooltip: 'Mode Expert',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ExpertTicketsScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(examsProvider);
              ref.invalidate(resultsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubjectsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const GroupChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome,
                color: AppColors.expertPrimary),
            tooltip: 'Assistant IA Math',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AiChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2,
                color: AppColors.expertPrimary),
            tooltip: 'Banque de Questions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SavedQuestionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_number,
                color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CreateTicketScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: examsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(AppStrings.loading,
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Erreur: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        data: (exams) => exams.isEmpty
            ? const Center(
                child: Text(AppStrings.noExams,
                    style: TextStyle(color: AppColors.textSecondary)))
            : _DashboardContent(exams: exams, resultsAsync: resultsAsync),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<ExamModel> exams;
  final AsyncValue<Map<String, ResultModel>> resultsAsync;

  const _DashboardContent(
      {required this.exams, required this.resultsAsync});

  @override
  Widget build(BuildContext context) {
    final villes = <String, List<ExamModel>>{};
    for (final exam in exams) {
      final parts = exam.source
          .replaceAll('math_exemple-concours-fmp-', '')
          .replaceAll('NNN', '')
          .replaceAll('NNvN', '')
          .split('-');
      final city = parts.isNotEmpty ? parts[0] : 'Inconnu';
      villes.putIfAbsent(city, () => []).add(exam);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.selectExam,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('${exams.length} examens disponibles',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              villes.entries.map((entry) {
                return _VilleSection(
                    city: entry.key,
                    exams: entry.value,
                    resultsAsync: resultsAsync);
              }).toList(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _VilleSection extends StatelessWidget {
  final String city;
  final List<ExamModel> exams;
  final AsyncValue<Map<String, ResultModel>> resultsAsync;

  const _VilleSection(
      {required this.city,
      required this.exams,
      required this.resultsAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(city[0].toUpperCase() + city.substring(1),
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          ...exams.map((exam) => _ExamCard(
              exam: exam, resultsAsync: resultsAsync)),
        ],
      ),
    );
  }
}

class _ExamCard extends ConsumerWidget {
  final ExamModel exam;
  final AsyncValue<Map<String, ResultModel>> resultsAsync;

  const _ExamCard(
      {required this.exam, required this.resultsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final results =
              resultsAsync.asData?.value ?? {};
          final result = results[exam.source];
          ref
              .read(quizProvider.notifier)
              .startExam(exam, result: result);
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const QcmScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.assignment,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.totalQuestions} questions • ${exam.subjects.length} matières',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
