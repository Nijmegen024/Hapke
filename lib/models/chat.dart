import 'friend.dart';

class ChatMessageView {
  final String id;
  final FriendUserInfo sender;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  const ChatMessageView({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessageView.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final senderJson = json['sender'];
    final sender = senderJson is Map<String, dynamic>
        ? FriendUserInfo.fromJson(senderJson)
        : FriendUserInfo(id: (json['senderId'] ?? '').toString(), email: '');
    return ChatMessageView(
      id: (json['id'] ?? '').toString(),
      sender: sender,
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      isMine: sender.id == currentUserId,
    );
  }
}

class ChatThread {
  final String id;
  final List<FriendUserInfo> participants;
  final List<ChatMessageView> messages;
  const ChatThread({
    required this.id,
    required this.participants,
    required this.messages,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json, String currentUserId) {
    final participantsJson =
        (json['participants'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final messagesJson = (json['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ChatThread(
      id: (json['id'] ?? '').toString(),
      participants: participantsJson
          .map(FriendUserInfo.fromJson)
          .where((u) => u.id.isNotEmpty)
          .toList(),
      messages: messagesJson
          .map((msg) => ChatMessageView.fromJson(msg, currentUserId))
          .toList(),
    );
  }
}
