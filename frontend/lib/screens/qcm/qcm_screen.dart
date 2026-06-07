import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/subject_progress_provider.dart';
import '../../models/question_model.dart';
import '../../services/ai_service.dart';
import '../../services/saved_question_service.dart';
import '../../widgets/math_formula_renderer.dart';
import '../review/review_screen.dart';
import '../tickets/create_ticket_screen.dart';

class QcmScreen extends ConsumerStatefulWidget {
  const QcmScreen({super.key});

  @override
  ConsumerState<QcmScreen> createState() => _QcmScreenState();
}

class _QcmScreenState extends ConsumerState<QcmScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _aiLoading = false;
  String? _aiResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _submitExam() async {
    final quiz = ref.read(quizProvider.notifier);
    await quiz.submit();
    _timer?.cancel();
    if (!mounted) return;
    ref.read(subjectProgressRefreshProvider.notifier).state++;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReviewScreen()),
    );
  }

  Future<void> _saveQuestion(QuestionModel question) async {
    final letters = ['A', 'B', 'C', 'D', 'E'];
    final choicesText = question.options.asMap().entries
        .map((e) => '**${letters[e.key]})** ${e.value}')
        .join('\n');
    final fullText = '**Enoncé:** ${question.question}\n\n$choicesText\n\n[Principal]';
    try {
      await SavedQuestionService.saveQuestion(
        questionText: fullText,
        answerText: '',
        subject: question.subject,
        isAiGenerated: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question sauvegardée'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {}
  }

  Future<void> _aiSolve(String question, String subject, List<String> choices) async {
    setState(() { _aiLoading = true; _aiResult = null; });
    try {
      final result = await AiService.solveQuestion(question: question, subject: subject, choices: choices);
      if (mounted) setState(() => _aiResult = result);
    } catch (e) {
      if (mounted) setState(() => _aiResult = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
    if (mounted) _showAiDialog();
  }

  Future<void> _aiSimilar(String question, String subject) async {
    setState(() { _aiLoading = true; _aiResult = null; });
    try {
      final result = await AiService.generateSimilar(question: question, subject: subject);
      if (mounted) setState(() => _aiResult = result);
      // Auto-save to question bank (full enonce + choices + answer)
      try {
        await SavedQuestionService.saveQuestion(
          questionText: result,  // full raw: enonce + all choices + [REPONSE: X]
          answerText: _extractAnswerFromSimilar(result),
          subject: subject,
          isAiGenerated: true,
        );
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => _aiResult = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
    if (mounted) _showAiDialog();
  }

  String _extractQuestionFromSimilar(String raw) {
    // Extract between **Enonce:** and **A)**
    final match = RegExp(r'\*\*Enonce:\*\*\s*(.+?)(?=\n?\*\*A\)\*\*)', dotAll: true).firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
    // Fallback: try without bold markers on A)
    final match2 = RegExp(r'\*\*Enonce:\*\*\s*(.+?)(?=\n?A\))', dotAll: true).firstMatch(raw);
    if (match2 != null) return match2.group(1)!.trim();
    // Fallback: first non-empty line after Enonce
    final lines = raw.split('\n');
    bool foundEnonce = false;
    for (final line in lines) {
      if (line.contains('Enonce')) { foundEnonce = true; continue; }
      if (foundEnonce && line.trim().isNotEmpty && !RegExp(r'^[A-E]\)').hasMatch(line.trim())) {
        return line.trim();
      }
    }
    return raw.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => raw.split('\n').first);
  }

  String _extractAnswerFromSimilar(String raw) {
    final match = RegExp(r'\[REPONSE:\s*([A-E])\]', caseSensitive: false).firstMatch(raw);
    if (match != null) return 'Reponse: ${match.group(1)}';
    // Fallback: try lowercase
    final match2 = RegExp(r'\[reponse:\s*([A-E])\]', caseSensitive: false).firstMatch(raw);
    if (match2 != null) return 'Reponse: ${match2.group(1)}';
    return raw.split('\n').last.trim();
  }

  void _sendToExpert(String question, String subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(prefillQuestion: question),
      ),
    );
  }

  void _showAiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MathFormulaRenderer(
            text: _aiResult ?? '',
            textScale: 1.0,
            isAiContent: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    if (quizState == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(AppStrings.qcm)),
        body: const Center(child: Text(AppStrings.noExams)),
      );
    }

    final question = quizState.currentQuestion;
    final selected = quizState.answers[question.id];
    final elapsed = quizState.elapsedSeconds;
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    final submitted = quizState.submitted;
    final hasResult = quizState.result != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            '${quizState.currentIndex + 1} / ${quizState.exam.questions.length}'),
        actions: [
          if (submitted)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                '${quizState.correctCount}/${quizState.gradedCount} ✓',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: minutes >= 25
                    ? AppColors.error.withValues(alpha: 0.2)
                    : minutes >= 20
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: minutes >= 25
                      ? AppColors.error
                      : minutes >= 20
                          ? AppColors.warning
                          : AppColors.surfaceBorder,
                ),
              ),
              child: Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: minutes >= 25
                      ? AppColors.error
                      : minutes >= 20
                          ? AppColors.warning
                          : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _ProgressBar(
            total: quizState.exam.questions.length,
            answered: quizState.answers,
            correctness: quizState.correctness,
            currentIndex: quizState.currentIndex,
            bookmarked: quizState.bookmarked,
            submitted: submitted,
            onTap: submitted
                ? null
                : (i) =>
                    ref.read(quizProvider.notifier).goToQuestion(i),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (submitted)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (quizState.correctness[question.id] == true)
                            ? AppColors.success.withValues(alpha: 0.15)
                            : (quizState.correctness[question.id] == false &&
                                    quizState.answers[question.id] != null)
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (quizState.correctness[question.id] == true)
                              ? AppColors.success
                              : (quizState.correctness[question.id] ==
                                          false &&
                                      quizState.answers[question.id] != null)
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (quizState.correctness[question.id] == true)
                                ? Icons.check_circle
                                : (quizState.correctness[question.id] ==
                                            false &&
                                        quizState.answers[question.id] != null)
                                    ? Icons.cancel
                                    : Icons.radio_button_unchecked,
                            color: (quizState
                                        .correctness[question.id] ==
                                    true)
                                ? AppColors.success
                                : (quizState.correctness[question.id] ==
                                            false &&
                                        quizState.answers[question.id] != null)
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (quizState.correctness[question.id] == true)
                                ? 'Correct'
                                : (quizState.correctness[question.id] ==
                                            false &&
                                        quizState.answers[question.id] != null)
                                    ? 'Faux'
                                    : 'Non répondu',
                            style: TextStyle(
                              color: (quizState
                                          .correctness[question.id] ==
                                      true)
                                  ? AppColors.success
                                  : (quizState.correctness[question.id] ==
                                              false &&
                                          quizState.answers[question.id] !=
                                              null)
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (quizState.answers[question.id] != null) ...[
                            const Spacer(),
                            Text(
                              'Votre réponse: ${String.fromCharCode(65 + quizState.answers[question.id]!)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (submitted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => ref
                              .read(quizProvider.notifier)
                              .unsubmit(),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modifier ma réponse'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(question.subject,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 16),
                  MathFormulaRenderer(
                      text: question.question, textScale: 1.1),
                  const SizedBox(height: 12),
                  // AI buttons row
                  Row(
                    children: [
                      _AiButton(
                        icon: Icons.auto_awesome,
                        label: 'Résoudre IA',
                        color: AppColors.expertPrimary,
                        loading: _aiLoading,
                        onTap: () => _aiSolve(question.question, question.subject, question.options),
                      ),
                      const SizedBox(width: 8),
                      _AiButton(
                        icon: Icons.content_copy,
                        label: 'Similaire',
                        color: AppColors.primary,
                        loading: false,
                        onTap: () => _aiSimilar(question.question, question.subject),
                      ),
                      const SizedBox(width: 8),
                      _AiButton(
                        icon: Icons.bookmark,
                        label: 'Sauver',
                        color: AppColors.warning,
                        loading: false,
                        onTap: () => _saveQuestion(question),
                      ),
                      const SizedBox(width: 8),
                      _AiButton(
                        icon: Icons.support_agent,
                        label: 'Expert',
                        color: AppColors.ticketColor,
                        loading: false,
                        onTap: () => _sendToExpert(question.question, question.subject),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(question.options.length, (i) {
                    final isSelected = selected == i;
                    final isCorrectOption = hasResult &&
                        quizState.result!
                            .isCorrect(question.id, i);
                    final wasCorrect = quizState.correctness[question.id];

                    Color borderColor;
                    Color bgColor;
                    Color letterBg;
                    Color letterText;

                    if (submitted) {
                      if (isSelected && (wasCorrect == true)) {
                        borderColor = AppColors.success;
                        bgColor = AppColors.success.withValues(alpha: 0.1);
                        letterBg = AppColors.success;
                        letterText = Colors.white;
                      } else if (isSelected && (wasCorrect == false)) {
                        borderColor = AppColors.error;
                        bgColor = AppColors.error.withValues(alpha: 0.1);
                        letterBg = AppColors.error;
                        letterText = Colors.white;
                      } else if (isCorrectOption) {
                        borderColor = AppColors.success;
                        bgColor = AppColors.success.withValues(alpha: 0.05);
                        letterBg = AppColors.success;
                        letterText = Colors.white;
                      } else {
                        borderColor = AppColors.surfaceBorder;
                        bgColor = AppColors.surface;
                        letterBg =
                            AppColors.surfaceBorder.withValues(alpha: 0.5);
                        letterText = AppColors.textSecondary;
                      }
                    } else {
                      borderColor = isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder;
                      bgColor = isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surface;
                      letterBg = isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder.withValues(alpha: 0.5);
                      letterText = isSelected
                          ? Colors.white
                          : AppColors.textSecondary;
                    }

                    final letter = String.fromCharCode(65 + i);
                    final optionWidget = AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || isCorrectOption ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: letterBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(letter,
                                  style: TextStyle(
                                    color: letterText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MathFormulaRenderer(
                                text: question.options[i]),
                          ),
                          if (submitted && isSelected)
                            Icon(
                              wasCorrect == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: wasCorrect == true
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                          if (submitted && !isSelected && isCorrectOption)
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 20),
                        ],
                      ),
                    );

                    if (submitted) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: optionWidget,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(quizProvider.notifier)
                            .answer(question.id, i),
                        child: optionWidget,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (!submitted)
            _BottomBar(
              questionId: question.id,
              isBookmarked:
                  quizState.bookmarked.contains(question.id),
              onBookmark: () {
                ref
                    .read(quizProvider.notifier)
                    .toggleBookmark(question.id);
              },
              onPrevious: quizState.currentIndex > 0
                  ? () => ref
                      .read(quizProvider.notifier)
                      .goToQuestion(quizState.currentIndex - 1)
                  : null,
              onNext: quizState.currentIndex <
                      quizState.exam.questions.length - 1
                  ? () => ref
                      .read(quizProvider.notifier)
                      .goToQuestion(quizState.currentIndex + 1)
                  : null,
              onSubmit: _submitExam,
              answeredCount: quizState.answeredCount,
              totalCount: quizState.exam.questions.length,
            ),
        ],
      ),
    );
  }
}

/// Two-pass parser: enonce first, then choices — pure substring, no regex for extraction
class _QcmView extends StatelessWidget {
  final String raw;
  const _QcmView({required this.raw});

  @override
  Widget build(BuildContext context) {
    final enonce = _extractEnonce(raw);
    final choices = _extractChoices(raw);
    final reponse = _extractRep(raw);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (enonce.isNotEmpty)
        _EnonceCard(text: enonce),
      ...choices.map((c) => _OptionRow(letter: c.letter, text: c.text, isCorrect: c.letter == reponse)),
      if (reponse != null) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 18), const SizedBox(width: 8),
            Text('Reponse: $reponse', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ],
    ]);
  }

  /// Extract enonce text between **Enonce:** and first **X)** or [REPONSE:
  String _extractEnonce(String text) {
    final startMarkers = ['**Enonce:**', '**Enoncé:**'];
    int start = -1;
    for (final m in startMarkers) {
      start = text.indexOf(m);
      if (start != -1) { start += m.length; break; }
    }
    if (start == -1) return '';

    // Find end: first **X)** or [REPONSE: after start
    final optRe = RegExp(r'\*\*[A-E]\)\*\*');
    final optMatch = optRe.firstMatch(text.substring(start));
    final repIdx = text.indexOf('[REPONSE:', start);

    int end = text.length;
    if (optMatch != null) {
      final o = start + optMatch.start;
      if (o < end) end = o;
    }
    if (repIdx != -1 && repIdx < end) end = repIdx;

    return text.substring(start, end).trim();
  }

  /// Extract each choice: **A)** text1  **B)** text2 ...
  List<_Choice> _extractChoices(String text) {
    final choices = <_Choice>[];
    final re = RegExp(r'\*\*([A-E])\)\*\*');
    final matches = re.allMatches(text).toList();

    for (var i = 0; i < matches.length; i++) {
      final letter = matches[i].group(1)!;
      final contentStart = matches[i].end;
      // Content ends at next **X)** or [REPONSE: or end
      int contentEnd = text.length;
      if (i + 1 < matches.length) {
        contentEnd = matches[i + 1].start;
      } else {
        final repIdx = text.indexOf('[REPONSE:', contentStart);
        if (repIdx != -1) contentEnd = repIdx;
      }
      final content = text.substring(contentStart, contentEnd).trim();
      if (content.isNotEmpty) {
        choices.add(_Choice(letter: letter, text: content));
      }
    }
    return choices;
  }

  String? _extractRep(String text) {
    final re = RegExp(r'\[REPONSE:\s*([A-E])\]');
    return re.firstMatch(text)?.group(1);
  }
}

class _Choice { final String letter, text; const _Choice({required this.letter, required this.text}); }

class _EnonceCard extends StatelessWidget {
  final String text;
  const _EnonceCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: AppColors.expertBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.expertBorder.withValues(alpha: 0.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.auto_awesome, color: AppColors.expertPrimary, size: 16),
        SizedBox(width: 8),
        Text('Enonce genere par IA',
          style: TextStyle(color: AppColors.expertPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      MathFormulaRenderer(text: text, isAiContent: true, textScale: 1.0),
    ]),
  );
}

class _OptionRow extends StatelessWidget {
  final String letter, text;
  final bool isCorrect;
  const _OptionRow({required this.letter, required this.text, this.isCorrect = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: isCorrect ? AppColors.success : AppColors.surfaceBorder.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(letter,
          style: TextStyle(color: isCorrect ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold, fontSize: 13))),
      ),
      const SizedBox(width: 10),
      Expanded(child: MathFormulaRenderer(text: text, isAiContent: true, textScale: 0.95)),
    ]),
  );
}

class _ProgressBar extends StatelessWidget {
  final int total;
  final Map<String, int?> answered;
  final Map<String, bool> correctness;
  final int currentIndex;
  final Set<String> bookmarked;
  final bool submitted;
  final void Function(int)? onTap;

  const _ProgressBar({
    required this.total,
    required this.answered,
    required this.correctness,
    required this.currentIndex,
    required this.bookmarked,
    required this.submitted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        itemBuilder: (_, i) {
          final qId = 'Q${i.toString().padLeft(2, '0')}';
          final isCurrent = i == currentIndex;
          final isBookmarked = bookmarked.contains(qId);
          final isCorrect = correctness[qId];

          Color dotColor;
          if (submitted) {
            if (isCorrect == true) {
              dotColor = AppColors.success;
            } else if (isCorrect == false && answered[qId] != null) {
              dotColor = AppColors.error;
            } else {
              dotColor = AppColors.surfaceBorder.withValues(alpha: 0.3);
            }
          } else {
            final isAnswered = answered[qId] != null;
            dotColor = isCurrent
                ? AppColors.primary
                : isAnswered
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.surfaceBorder.withValues(alpha: 0.3);
          }

          String? statusChar;
          if (submitted) {
            if (isCorrect == true) {
              statusChar = '✓';
            } else if (isCorrect == false && answered[qId] != null) {
              statusChar = '✗';
            } else {
              statusChar = '—';
            }
          }

          return GestureDetector(
            onTap: onTap != null ? () => onTap!(i) : null,
            child: Container(
              width: submitted ? 38 : 32,
              margin:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(6),
                border: isCurrent && !submitted
                    ? Border.all(color: AppColors.primary, width: 1)
                    : null,
              ),
              child: submitted
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(statusChar!,
                            style: TextStyle(
                              color: isCorrect == true
                                  ? Colors.white
                                  : isCorrect == false
                                      ? Colors.white
                                      : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    )
                  : Stack(
                      children: [
                        Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                        if (isBookmarked)
                          const Positioned(
                            top: 1,
                            right: 1,
                            child: Icon(Icons.bookmark,
                                size: 10, color: AppColors.warning),
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

class _AiButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _AiButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String questionId;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;
  final int answeredCount;
  final int totalCount;

  const _BottomBar({
    required this.questionId,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.answeredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  isBookmarked ? AppColors.warning : AppColors.textSecondary,
            ),
            onPressed: onBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous,
                color: AppColors.textSecondary),
            onPressed: onPrevious,
          ),
          const Spacer(),
          Text('$answeredCount/$totalCount',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.skip_next,
                color: AppColors.textSecondary),
            onPressed: onNext,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text(AppStrings.submit,
                style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
