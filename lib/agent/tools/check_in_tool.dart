import '../../core/result.dart';
import '../../repositories/match_repository.dart';

/// Tool definition for recording a dinner check-in.
abstract final class CheckInTool {
  /// The registered tool name.
  static const String name = 'check_in_to_dinner';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Records a day-of check-in for a dinner match.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'match_id': <String, dynamic>{'type': 'string'},
          'user_id': <String, dynamic>{'type': 'string'},
          'latitude': <String, dynamic>{'type': 'number'},
          'longitude': <String, dynamic>{'type': 'number'},
        },
        'required': <String>['match_id', 'user_id', 'latitude', 'longitude'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    MatchRepository repository,
  ) async {
    final Result result = await repository.checkInToDinner(
      matchId: input['match_id'] as String,
      userId: input['user_id'] as String,
      latitude: (input['latitude'] as num).toDouble(),
      longitude: (input['longitude'] as num).toDouble(),
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
