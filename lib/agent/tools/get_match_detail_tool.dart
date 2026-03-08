import '../../core/result.dart';
import '../../repositories/match_repository.dart';

/// Tool definition for loading full match detail.
abstract final class GetMatchDetailTool {
  /// The registered tool name.
  static const String name = 'get_match_detail';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Loads the full state of a dinner match for shell rendering.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'match_id': <String, dynamic>{'type': 'string'},
          'viewer_user_id': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['match_id', 'viewer_user_id'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    MatchRepository repository,
  ) async {
    final Result result = await repository.getMatchDetail(
      matchId: input['match_id'] as String,
      viewerUserId: input['viewer_user_id'] as String,
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
