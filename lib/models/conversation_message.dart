/// Identifies the sender of a conversation message.
enum ConversationAuthor {
  /// A message authored by Luma.
  luma('luma'),

  /// A message authored by the user.
  user('user');

  /// Creates an author value.
  const ConversationAuthor(this.value);

  /// The serialized value used in storage and transport.
  final String value;

  /// Parses a serialized author value.
  static ConversationAuthor fromString(String value) {
    return ConversationAuthor.values.firstWhere(
      (author) => author.value == value,
      orElse: () => ConversationAuthor.luma,
    );
  }
}

/// Represents a single item in the conversation feed.
class ConversationMessage {
  /// Creates a conversation message.
  const ConversationMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Creates a Luma-authored message.
  factory ConversationMessage.luma({
    required String text,
    Map<String, dynamic> metadata = const {},
  }) {
    return ConversationMessage(
      id: _defaultMessageId(),
      text: text,
      author: ConversationAuthor.luma,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a user-authored message.
  factory ConversationMessage.user({
    required String text,
    Map<String, dynamic> metadata = const {},
  }) {
    return ConversationMessage(
      id: _defaultMessageId(),
      text: text,
      author: ConversationAuthor.user,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a message from serialized JSON.
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String? ?? _defaultMessageId(),
      text: json['text'] as String? ?? '',
      author: ConversationAuthor.fromString(
        json['author'] as String? ?? ConversationAuthor.luma.value,
      ),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  /// The unique identifier for the message.
  final String id;

  /// The rendered text content.
  final String text;

  /// The author of the message.
  final ConversationAuthor author;

  /// The timestamp the message was created.
  final DateTime createdAt;

  /// Additional structured payload for the message.
  final Map<String, dynamic> metadata;

  /// Converts the message to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'author': author.value,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Creates a modified copy of the message.
  ConversationMessage copyWith({
    String? id,
    String? text,
    ConversationAuthor? author,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

String _defaultMessageId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
