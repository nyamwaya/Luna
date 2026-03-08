import '../../core/result.dart';
import '../../repositories/match_repository.dart';

/// Tool definition for declining a match guest.
abstract final class DeclineMatchTool {
  /// The registered tool name.
  static const String name = 'decline_match_guest';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Declines an assigned dinner match and applies the cancellation policy.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'match_id': <String, dynamic>{'type': 'string'},
          'user_id': <String, dynamic>{'type': 'string'},
          'reason': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['match_id', 'user_id'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    MatchRepository repository,
  ) async {
    final Result result = await repository.declineMatchGuest(
      matchId: input['match_id'] as String,
      userId: input['user_id'] as String,
      reason: input['reason'] as String?,
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
