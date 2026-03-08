import '../../core/result.dart';
import '../../repositories/dinner_repository.dart';

/// Tool definition for loading a single dinner invite.
abstract final class GetDinnerInviteTool {
  /// The registered tool name.
  static const String name = 'get_dinner_invite';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Loads a single dinner invite with event context for display.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'invite_id': <String, dynamic>{'type': 'string'},
          'viewer_user_id': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['invite_id', 'viewer_user_id'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    DinnerRepository repository,
  ) async {
    final Result result = await repository.getDinnerInvite(
      inviteId: input['invite_id'] as String,
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
