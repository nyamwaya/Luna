import '../../core/result.dart';
import '../../repositories/dinner_repository.dart';

/// Tool definition for loading a guest-facing dinner event payload.
abstract final class GetDinnerEventForGuestTool {
  /// The registered tool name.
  static const String name = 'get_dinner_event_for_guest';

  /// The serialized tool definition.
  static Map<String, dynamic> get definition {
    return <String, dynamic>{
      'name': name,
      'description': 'Loads the guest perspective for a dinner event, including invite, match, and check-in state.',
      'input_schema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'dinner_event_id': <String, dynamic>{'type': 'string'},
          'viewer_user_id': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['dinner_event_id', 'viewer_user_id'],
      },
    };
  }

  /// Executes the tool handler.
  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    DinnerRepository repository,
  ) async {
    final Result result = await repository.getDinnerEventForGuest(
      dinnerEventId: input['dinner_event_id'] as String,
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
