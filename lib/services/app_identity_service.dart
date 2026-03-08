import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../strings.dart';

class AppIdentity {
  const AppIdentity({
    required this.userId,
    required this.firstName,
    required this.city,
    required this.initials,
    required this.provider,
  });

  final String userId;
  final String firstName;
  final String city;
  final String initials;
  final String provider;

  Map<String, dynamic> toContextJson() {
    return <String, dynamic>{
      'firstName': firstName,
      'city': city,
      'initials': initials,
      'provider': provider,
    };
  }
}

abstract final class AppIdentityService {
  static const String _userIdKey = 'app_identity_user_id';
  static const String _firstNameKey = 'app_identity_first_name';
  static const String _cityKey = 'app_identity_city';
  static const String _conversationSessionIdKey = 'app_identity_conversation_session_id';
  static const String _provider = 'local';

  static SharedPreferences? _preferences;
  static AppIdentity? _identity;
  static String? _conversationSessionId;

  static Future<void> initialize() async {
    await _ensureLoaded();
  }

  static Future<AppIdentity> currentIdentity() async {
    await _ensureLoaded();
    return _identity!;
  }

  static Future<String> currentConversationSessionId() async {
    await _ensureLoaded();
    return _conversationSessionId!;
  }

  static Future<String> rotateConversationSession() async {
    await _ensureLoaded();
    final SharedPreferences preferences = _preferences!;
    final String nextSessionId = _generateId('session');
    _conversationSessionId = nextSessionId;
    await preferences.setString(_conversationSessionIdKey, nextSessionId);
    return nextSessionId;
  }

  static Future<void> _ensureLoaded() async {
    if (_identity != null && _conversationSessionId != null && _preferences != null) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _preferences = preferences;

    final String userId = _readOrCreate(
      preferences: preferences,
      key: _userIdKey,
      fallback: () => _generateId('user'),
    );
    final String firstName = _readOrCreate(
      preferences: preferences,
      key: _firstNameKey,
      fallback: () => '',
    );
    final String city = _readOrCreate(
      preferences: preferences,
      key: _cityKey,
      fallback: () => Strings.homeCity,
    );
    final String conversationSessionId = _readOrCreate(
      preferences: preferences,
      key: _conversationSessionIdKey,
      fallback: () => _generateId('session'),
    );

    _identity = AppIdentity(
      userId: userId,
      firstName: firstName,
      city: city,
      initials: _buildInitials(firstName),
      provider: _provider,
    );
    _conversationSessionId = conversationSessionId;
  }

  static String _readOrCreate({
    required SharedPreferences preferences,
    required String key,
    required String Function() fallback,
  }) {
    final String existingValue = preferences.getString(key)?.trim() ?? '';
    if (existingValue.isNotEmpty) {
      return existingValue;
    }

    final String nextValue = fallback();
    preferences.setString(key, nextValue);
    return nextValue;
  }

  static String _buildInitials(String firstName) {
    final String normalized = firstName.trim();
    if (normalized.isEmpty) {
      return 'ME';
    }

    final List<String> parts = normalized
        .split(RegExp(r'\s+'))
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'ME';
    }

    if (parts.length == 1) {
      final String word = parts.first.toUpperCase();
      return word.length >= 2 ? word.substring(0, 2) : word;
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _generateId(String prefix) {
    final int randomValue = Random().nextInt(0x7fffffff);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${randomValue.toRadixString(36)}';
  }
}
