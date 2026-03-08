/// Represents a user profile used throughout the pairing flow.
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.id,
    required this.firstName,
    this.lastName,
    this.profilePhotoPath,
    this.occupation,
    this.bio,
    this.interests = const <String>[],
  });

  /// Creates a user profile from serialized JSON.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? json['user_id'] ?? json['userid'] ?? '') as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      occupation: json['occupation'] as String?,
      bio: json['bio'] as String?,
      interests: _parseStringList(json['interests']),
    );
  }

  /// The unique identifier for the user.
  final String id;

  /// The first name shown in the pairing flow.
  final String firstName;

  /// The optional last name.
  final String? lastName;

  /// The stored profile photo path.
  final String? profilePhotoPath;

  /// The optional occupation label.
  final String? occupation;

  /// The optional user bio.
  final String? bio;

  /// The user's selected interests.
  final List<String> interests;

  /// Converts the profile to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'profile_photo_path': profilePhotoPath,
      'occupation': occupation,
      'bio': bio,
      'interests': interests,
    };
  }

  /// Creates a modified copy of the profile.
  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? profilePhotoPath,
    String? occupation,
    String? bio,
    List<String>? interests,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
    );
  }
}

List<String> _parseStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }

  return const <String>[];
}
