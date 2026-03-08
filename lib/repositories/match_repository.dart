import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../core/result.dart';
import '../models/action_results.dart';
import '../models/match_detail.dart';

/// Repository responsible for all match-related data access.
class MatchRepository {
  /// Creates a match repository.
  MatchRepository(this._client);

  final SupabaseClient _client;

  /// Loads the full match detail for a viewer.
  Future<Result<MatchDetail>> getMatchDetail({
    required String matchId,
    required String viewerUserId,
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'get_match_detail',
        params: <String, dynamic>{
          'p_match_id': matchId,
          'p_viewer_user_id': viewerUserId,
        },
      );

      if (response is! Map) {
        return const Failure<MatchDetail>('Invalid match detail response');
      }

      return Success<MatchDetail>(
        MatchDetail.fromJson(Map<String, dynamic>.from(response)),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'getMatchDetail failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'matchId': matchId, 'viewerUserId': viewerUserId},
      );
      return Failure<MatchDetail>('Failed to load match detail', error: error);
    }
  }

  /// Confirms a guest for a given match.
  Future<Result<MatchActionResult>> confirmMatchGuest({
    required String matchId,
    required String userId,
  }) async {
    return _runMatchAction(
      rpcName: 'confirm_match_guest',
      params: <String, dynamic>{
        'p_match_id': matchId,
        'p_user_id': userId,
      },
      failureMessage: 'Failed to confirm match',
      actionName: 'confirmMatchGuest',
    );
  }

  /// Declines a guest from a given match.
  Future<Result<MatchActionResult>> declineMatchGuest({
    required String matchId,
    required String userId,
    String? reason,
  }) async {
    return _runMatchAction(
      rpcName: 'decline_match_guest',
      params: <String, dynamic>{
        'p_match_id': matchId,
        'p_user_id': userId,
        'p_reason': reason,
      },
      failureMessage: 'Failed to decline match',
      actionName: 'declineMatchGuest',
    );
  }

  /// Checks the current user into the dinner.
  Future<Result<CheckInResult>> checkInToDinner({
    required String matchId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'check_in_to_dinner',
        params: <String, dynamic>{
          'p_match_id': matchId,
          'p_user_id': userId,
          'p_latitude': latitude,
          'p_longitude': longitude,
        },
      );

      if (response is! Map) {
        return const Failure<CheckInResult>('Invalid check-in response');
      }

      return Success<CheckInResult>(
        CheckInResult.fromJson(Map<String, dynamic>.from(response)),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'checkInToDinner failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'matchId': matchId, 'userId': userId},
      );
      return Failure<CheckInResult>('Failed to check in to dinner', error: error);
    }
  }

  /// Reports whether the current user attended.
  Future<Result<AttendanceReportResult>> reportAttendance({
    required String matchId,
    required String userId,
    required bool attended,
  }) async {
    try {
      final dynamic response = await _client.rpc(
        'report_attendance',
        params: <String, dynamic>{
          'p_match_id': matchId,
          'p_user_id': userId,
          'p_attended': attended,
        },
      );

      if (response is! Map) {
        return const Failure<AttendanceReportResult>('Invalid attendance response');
      }

      return Success<AttendanceReportResult>(
        AttendanceReportResult.fromJson(
          Map<String, dynamic>.from(response),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'reportAttendance failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'matchId': matchId, 'userId': userId, 'attended': attended},
      );
      return Failure<AttendanceReportResult>('Failed to report attendance', error: error);
    }
  }

  Future<Result<MatchActionResult>> _runMatchAction({
    required String rpcName,
    required Map<String, dynamic> params,
    required String failureMessage,
    required String actionName,
  }) async {
    try {
      final dynamic response = await _client.rpc(rpcName, params: params);

      if (response is! Map) {
        return const Failure<MatchActionResult>('Invalid match action response');
      }

      return Success<MatchActionResult>(
        MatchActionResult.fromJson(Map<String, dynamic>.from(response)),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '$actionName failed',
        error: error,
        stackTrace: stackTrace,
        data: params.cast<String, Object?>(),
      );
      return Failure<MatchActionResult>(failureMessage, error: error);
    }
  }
}
