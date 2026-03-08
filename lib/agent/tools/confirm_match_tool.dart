import '../../core/result.dart';
import '../../repositories/match_repository.dart';

/// Tool definition for confirming a match guest.
abstract final class ConfirmMatchTool {
  /// The registered tool name.
  static const String name = 'confirm_match_guest';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Confirms that the current user will attend their paired dinner.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'match_id': <String, dynamic>{'type': 'string'},
          'user_id': <String, dynamic>{'type': 'string'},
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
    final Result result = await repository.confirmMatchGuest(
      matchId: input['match_id'] as String,
      userId: input['user_id'] as String,
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
