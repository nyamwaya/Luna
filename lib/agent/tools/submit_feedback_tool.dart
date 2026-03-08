import '../../core/result.dart';
import '../../repositories/dinner_repository.dart';

/// Tool definition for submitting dinner feedback.
abstract final class SubmitFeedbackTool {
  /// The registered tool name.
  static const String name = 'submit_dinner_feedback';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Submits post-dinner feedback for an attended event.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'dinner_event_id': <String, dynamic>{'type': 'string'},
          'match_id': <String, dynamic>{'type': 'string'},
          'user_id': <String, dynamic>{'type': 'string'},
          'star_rating': <String, dynamic>{'type': 'integer'},
          'quick_tags': <String, dynamic>{'type': 'array', 'items': <String, dynamic>{'type': 'string'}},
          'tell_us_more': <String, dynamic>{'type': 'string'},
          'photo_paths': <String, dynamic>{'type': 'array', 'items': <String, dynamic>{'type': 'string'}},
        },
        'required': <String>['dinner_event_id', 'match_id', 'user_id', 'star_rating'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    DinnerRepository repository,
  ) async {
    final Result result = await repository.submitDinnerFeedback(
      dinnerEventId: input['dinner_event_id'] as String,
      matchId: input['match_id'] as String,
      userId: input['user_id'] as String,
      starRating: input['star_rating'] as int,
      quickTags: (input['quick_tags'] as List?)?.whereType<String>().toList() ?? const <String>[],
      tellUsMore: input['tell_us_more'] as String?,
      photoPaths: (input['photo_paths'] as List?)?.whereType<String>().toList() ?? const <String>[],
    );

    return result.when(
      success: (dynamic data) => <String, dynamic>{'success': true, ...(data as dynamic).toJson() as Map<String, dynamic>},
      failure: (String message, Object? error) => <String, dynamic>{
        'success': false,
        'error': message,
      },
    );
  }
}
