import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exam_model.dart';
import '../models/result_model.dart';

class DataService {
  static const _assetPath = 'assets/';
  static const _resultPath = 'assets/results/';

  static List<String> get examFileNames => [
        'math_exemple-concours-fmp-oujda-2013.json',
        'math_exemple-concours-fmp-oujda-2015.json',
        'math_exemple-concours-fmp-oujda-2012.json',
        'math_exemple-concours-fmp-oujda-2011.json',
        'math_exemple-concours-fmp-oujda-2014.json',
        'math_exemple-concours-fmp-rabat-2011.json',
        'math_exemple-concours-fmp-marrakech-2015.json',
        'math_exemple-concours-fmp-marrakech-2012.json',
        'math_exemple-concours-fmp-marrakech-2017.json',
        'math_exemple-concours-fmp-marrakech-2011.json',
        'math_exemple-concours-fmp-fes-2016.json',
        'math_exemple-concours-fmp-fes-2012.json',
        'math_exemple-concours-fmp-casa-2015.json',
        'math_exemple-concours-fmp-casa-2017.json',
        'math_exemple-concours-fmp-agadir-2016.json',
        'NNNmath_exemple-concours-fmp-tanger-2016.json',
        'NNNmath_exemple-concours-fmp-oujda-2016.json',
        'NNNmath_exemple-concours-fmp-oujda-2010.json',
        'NNNmath_exemple-concours-fmp-rabat-2014.json',
        'NNNmath_exemple-concours-fmp-marrakech-2014.json',
        'NNNmath_exemple-concours-fmp-marrakech-2010.json',
        'NNNmath_exemple-concours-fmp-fes-2017.json',
        'NNNmath_exemple-concours-fmp-fes-2015_removed.json',
        'NNvNmath_exemple-concours-fmp-oujda-2017_cropped.json',
        'FConcours-medecine-2022-Corrigé-.json',
        'FConcours-medecine-2024-Corrigé.json',
        'FConcours-medecine-2021-Corrigé.json',
        'FConcours-medecine-2023-Corrigé-.json',
        'FConcours-medecine-2020-Corrigé.json',
        'FConcours-medecine-2019-CASA-Corrige-.json',
        'FCorrection concours  médecine 2025 PUB.json',
      ];

  static List<String> get _resultFileNames => [
        'FConcours-medecine-2019-CASA-Corrig_-.json_answers_2026-05-18T16-46-14.480Z.json',
        'FConcours-medecine-2020-Corrig_.json_answers_2026-05-18T19-08-27.939Z.json',
        'FConcours-medecine-2021-Corrig_.json_answers_2026-05-18T19-14-43.616Z.json',
        'FConcours-medecine-2022-Corrig_-.json_answers_2026-05-19T12-50-44.447Z.json',
        'FConcours-medecine-2023-Corrig_-.json_answers_2026-05-19T20-10-19.422Z.json',
        'FConcours-medecine-2024-Corrig_.json_answers_2026-05-19T20-31-04.346Z.json',
        'FCorrection_concours__m_decine_2025_PUB.json_answers_2026-05-19T20-42-53.727Z.json',
        'NNNmath_exemple-concours-fmp-fes-2015_removed.json_answers_2026-05-19T22-41-07.366Z.json',
        'NNNmath_exemple-concours-fmp-fes-2017.json_answers_2026-05-19T22-47-12.161Z.json',
        'NNNmath_exemple-concours-fmp-marrakech-2010.json_answers_2026-05-19T21-07-53.195Z.json',
        'NNNmath_exemple-concours-fmp-marrakech-2014.json_answers_2026-05-20T12-06-31.151Z.json',
        'NNNmath_exemple-concours-fmp-oujda-2010.json_answers_2026-05-20T12-11-52.545Z.json',
        'NNNmath_exemple-concours-fmp-oujda-2016.json_answers_2026-05-20T12-33-56.563Z.json',
        'NNNmath_exemple-concours-fmp-rabat-2014.json_answers_2026-05-20T12-39-49.179Z.json',
        'NNNmath_exemple-concours-fmp-tanger-2016.json_answers_2026-05-20T13-22-37.669Z.json',
        'NNvNmath_exemple-concours-fmp-oujda-2017_cropped.json_answers_2026-05-21T13-46-26.591Z.json',
        'math_exemple-concours-fmp-agadir-2016.json_answers_2026-05-20T13-58-02.791Z.json',
        'math_exemple-concours-fmp-agadir-2016.json_answers_2026-05-21T13-49-26.761Z.json',
        'math_exemple-concours-fmp-casa-2015.json_answers_2026-05-21T13-42-27.047Z.json',
        'math_exemple-concours-fmp-casa-2017.json_answers_2026-05-20T14-45-57.291Z.json',
        'math_exemple-concours-fmp-fes-2012.json_answers_2026-05-20T14-56-28.618Z.json',
        'math_exemple-concours-fmp-fes-2016.json_answers_2026-05-20T15-01-49.466Z.json',
        'math_exemple-concours-fmp-marrakech-2011.json_answers_2026-05-20T15-08-04.767Z.json',
        'math_exemple-concours-fmp-marrakech-2012.json_answers_2026-05-20T18-13-04.650Z.json',
        'math_exemple-concours-fmp-marrakech-2015.json_answers_2026-05-20T18-18-00.583Z.json',
        'math_exemple-concours-fmp-marrakech-2017.json_answers_2026-05-20T18-22-51.049Z.json',
        'math_exemple-concours-fmp-oujda-2011.json_answers_2026-05-20T21-00-00.219Z.json',
        'math_exemple-concours-fmp-oujda-2012.json_answers_2026-05-21T13-37-40.585Z.json',
        'math_exemple-concours-fmp-oujda-2013.json_answers_2026-05-21T18-10-21.579Z.json',
        'math_exemple-concours-fmp-oujda-2014.json_answers_2026-05-21T14-15-28.020Z.json',
        'math_exemple-concours-fmp-oujda-2015.json_answers_2026-05-21T14-47-54.287Z.json',
        'math_exemple-concours-fmp-rabat-2011.json_answers_2026-05-21T14-54-30.465Z.json',
      ];

  static Future<List<ExamModel>> loadAllExams() async {
    final exams = <ExamModel>[];
    for (final fileName in examFileNames) {
      try {
        final jsonString = await rootBundle.loadString('$_assetPath$fileName');
        final jsonList = json.decode(jsonString) as List<dynamic>;
        exams.add(ExamModel.fromJsonList(jsonList));
      } catch (e) {
        // ignore files that fail to load
      }
    }
    return exams;
  }

  static Future<Map<String, ResultModel>> loadAllResults() async {
    final resultMap = <String, ResultModel>{};
    for (final fileName in _resultFileNames) {
      try {
        final jsonString =
            await rootBundle.loadString('$_resultPath$fileName');
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final result = ResultModel.fromJson(jsonMap);
        String key = result.source;
        if (key.endsWith('.json')) {
          key = key.substring(0, key.length - 5);
        }
        final existing = resultMap[key];
        if (existing == null) {
          resultMap[key] = result;
        }
      } catch (e) {
        // ignore files that fail to load
      }
    }
    return resultMap;
  }
}
