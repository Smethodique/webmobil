import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_model.dart';
import '../models/result_model.dart';
import '../services/data_service.dart';

final examsProvider = FutureProvider<List<ExamModel>>((ref) async {
  return DataService.loadAllExams();
});

final resultsProvider =
    FutureProvider<Map<String, ResultModel>>((ref) async {
  return DataService.loadAllResults();
});

final selectedExamProvider = StateProvider<ExamModel?>((ref) => null);
