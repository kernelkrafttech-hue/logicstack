import 'package:cloud_functions/cloud_functions.dart';

import '../domain/maintenance_request.dart';
import 'request_repository.dart';

/// Thin client for the `analyzeMaintenanceRequest` callable Cloud Function.
///
/// The OpenAI key lives entirely server-side; this class only sees the
/// already-analyzed result. Errors are mapped onto [RequestException] so the
/// rest of the app's error handling can treat AI failures uniformly with
/// other request operations.
class AiAnalysisService {
  AiAnalysisService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  static const String _functionName = 'analyzeMaintenanceRequest';

  Future<AiAnalysis> analyze({
    required String title,
    required String description,
    required RequestCategory category,
    required RequestUrgency urgency,
  }) async {
    try {
      final HttpsCallableResult<Object?> result =
          await _functions.httpsCallable(_functionName).call<Object?>(
        <String, Object?>{
          'title': title,
          'description': description,
          'category': category.storageValue,
          'urgency': urgency.storageValue,
        },
      );

      final Map<String, Object?> data = _toMap(result.data);
      return AiAnalysis(
        aiSummary: (data['aiSummary'] as String?) ?? '',
        likelyTrade: (data['likelyTrade'] as String?) ?? '',
        urgencySuggestion: (data['urgencySuggestion'] as String?) ?? '',
        contractorMessage: (data['contractorMessage'] as String?) ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      throw RequestException(_messageForCode(e));
    } catch (_) {
      throw RequestException('AI analysis failed. Please try again.');
    }
  }

  /// Cloud Functions returns a typed map but the cast on Flutter is
  /// `Object?`; this normalises it without crashing on unexpected shapes.
  Map<String, Object?> _toMap(Object? raw) {
    if (raw is Map) {
      return raw.map<String, Object?>(
        (Object? key, Object? value) =>
            MapEntry<String, Object?>(key.toString(), value),
      );
    }
    return <String, Object?>{};
  }

  String _messageForCode(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again and try.';
      case 'invalid-argument':
        return e.message ?? 'The request data was rejected.';
      case 'deadline-exceeded':
      case 'unavailable':
        return 'AI service is taking too long. Please try again.';
      case 'permission-denied':
        return "You don't have permission to run AI analysis.";
      default:
        return e.message ?? 'AI analysis failed. Please try again.';
    }
  }
}
