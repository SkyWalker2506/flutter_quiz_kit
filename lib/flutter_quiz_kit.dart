/// flutter_quiz_kit — Quiz engine for Flutter apps.
library;

export 'src/interfaces/quiz_item.dart' show QuizItem;
export 'src/models/difficulty_level.dart'
    show
        DifficultyLevel,
        DifficultyParams,
        ProgressiveTier,
        kAdaptiveHistorySize,
        difficultyFromAccuracy;
export 'src/models/quiz_question.dart' show QuizMode, QuizDirection, QuizQuestion;
export 'src/models/quiz_result.dart' show QuizResult;
export 'src/security/quiz_abuse_detector.dart'
    show QuizAbuseDetector, QuizAbuseResult, QuizAbuseConfig, AbuseSeverity;
export 'src/services/quiz_sound_service.dart' show QuizSoundService;
export 'src/data/quiz_accuracy_local_datasource.dart'
    show QuizAccuracyLocalDataSource;
export 'src/usecases/stt_matches.dart' show sttRecognizedMatchesExpected;
export 'src/providers/quiz_providers.dart'
    show
        quizPrefsProvider,
        quizAccuracyDataSourceProvider,
        recentAverageAccuracyProvider,
        adaptiveDifficultyParamsProvider,
        quizSoundServiceProvider;
