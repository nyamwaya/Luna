import '../../core/result.dart';
import '../../models/dinner_invite.dart';
import '../../repositories/dinner_repository.dart';

/// Tool definition for responding to a dinner invite.
abstract final class RespondToInviteTool {
  /// The registered tool name.
  static const String name = 'respond_to_dinner_invite';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Accepts or declines a dinner invite for the current user.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'invite_id': <String, dynamic>{'type': 'string'},
          'user_id': <String, dynamic>{'type': 'string'},
          'response': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['invite_id', 'user_id', 'response'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    DinnerRepository repository,
  ) async {
    final Result result = await repository.respondToDinnerInvite(
      inviteId: input['invite_id'] as String,
      userId: input['user_id'] as String,
      response: InviteStatus.fromString(input['response'] as String?),
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
