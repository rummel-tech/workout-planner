/// Chat data models
class ChatSession {
  final int id;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
    };
  }
}

class ChatMessage {
  final int? id;
  final int sessionId;
  final String role; // "user" or "assistant"
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.metadata,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['session_id'],
      role: json['role'],
      content: json['content'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class SendMessageRequest {
  final String userId;
  final String message;
  final int? sessionId;

  SendMessageRequest({
    required this.userId,
    required this.message,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
    };
  }
}

class SendMessageResponse {
  final int sessionId;
  final ChatMessage userMessage;
  final ChatMessage assistantMessage;

  SendMessageResponse({
    required this.sessionId,
    required this.userMessage,
    required this.assistantMessage,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      sessionId: json['session_id'],
      userMessage: ChatMessage.fromJson(json['user_message']),
      assistantMessage: ChatMessage.fromJson(json['assistant_message']),
    );
  }
}
