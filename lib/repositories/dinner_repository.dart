import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../core/result.dart';
import '../models/action_results.dart';
import '../models/dinner_invite.dart';
import '../models/guest_dinner_event_view.dart';

/// Repository responsible for dinner event and invite data access.
class DinnerRepository {
  /// Creates a dinner repository.
  DinnerRepository(this._client);

  final SupabaseClient _client;

  /// Loads a single dinner invite for display.
  Future<Result<DinnerInvite>> getDinnerInvite({
    required String inviteId,
    required String viewerUserId,
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'get_dinner_invite',
        params: <String, dynamic>{
          'p_invite_id': inviteId,
          'p_viewer_user_id': viewerUserId,
        },
      );

      if (response is! Map) {
        return const Failure<DinnerInvite>('Invalid dinner invite response');
      }

      return Success<DinnerInvite>(
        DinnerInvite.fromJson(Map<String, dynamic>.from(response)),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'getDinnerInvite failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'inviteId': inviteId, 'viewerUserId': viewerUserId},
      );
      return Failure<DinnerInvite>('Failed to load dinner invite', error: error);
    }
  }

  /// Responds to a dinner invite with acceptance or decline.
  Future<Result<InviteResponseResult>> respondToDinnerInvite({
    required String inviteId,
    required String userId,
    required InviteStatus response,
  }) async {
    try {
      final dynamic rpcResponse = await _client.rpc(
        'respond_to_dinner_invite',
        params: <String, dynamic>{
          'p_invite_id': inviteId,
          'p_user_id': userId,
          'p_response': response.value,
        },
      );

      if (rpcResponse is! Map) {
        return const Failure<InviteResponseResult>('Invalid invite response result');
      }

      return Success<InviteResponseResult>(
        InviteResponseResult.fromJson(
          Map<String, dynamic>.from(rpcResponse),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'respondToDinnerInvite failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'inviteId': inviteId, 'userId': userId, 'response': response.value},
      );
      return Failure<InviteResponseResult>('Failed to respond to dinner invite', error: error);
    }
  }

  /// Loads a guest-facing dinner event payload.
  Future<Result<GuestDinnerEventView>> getDinnerEventForGuest({
    required String dinnerEventId,
    required String viewerUserId,
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'get_dinner_event_for_guest',
        params: <String, dynamic>{
          'p_dinner_event_id': dinnerEventId,
          'p_viewer_user_id': viewerUserId,
        },
      );

      if (response is! Map) {
        return const Failure<GuestDinnerEventView>('Invalid dinner event response');
      }

      return Success<GuestDinnerEventView>(
        GuestDinnerEventView.fromJson(
          Map<String, dynamic>.from(response),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'getDinnerEventForGuest failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'dinnerEventId': dinnerEventId, 'viewerUserId': viewerUserId},
      );
      return Failure<GuestDinnerEventView>('Failed to load dinner event', error: error);
    }
  }

  /// Submits dinner feedback for an attended match.
  Future<Result<FeedbackSubmissionResult>> submitDinnerFeedback({
    required String dinnerEventId,
    required String matchId,
    required String userId,
    required int starRating,
    List<String> quickTags = const <String>[],
    String? tellUsMore,
    List<String> photoPaths = const <String>[],
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'submit_dinner_feedback',
        params: <String, dynamic>{
          'p_dinner_event_id': dinnerEventId,
          'p_match_id': matchId,
          'p_user_id': userId,
          'p_star_rating': starRating,
          'p_quick_tags': quickTags,
          'p_tell_us_more': tellUsMore,
          'p_photo_paths': photoPaths,
        },
      );

      if (response is! Map) {
        return const Failure<FeedbackSubmissionResult>('Invalid feedback response');
      }

      return Success<FeedbackSubmissionResult>(
        FeedbackSubmissionResult.fromJson(
          Map<String, dynamic>.from(response),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'submitDinnerFeedback failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'dinnerEventId': dinnerEventId, 'matchId': matchId, 'userId': userId},
      );
      return Failure<FeedbackSubmissionResult>('Failed to submit dinner feedback', error: error);
    }
  }
}
