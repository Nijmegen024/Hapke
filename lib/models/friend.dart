class FriendUserInfo {
  final String id;
  final String email;
  final String? name;
  const FriendUserInfo({required this.id, required this.email, this.name});

  factory FriendUserInfo.fromJson(Map<String, dynamic> json) {
    return FriendUserInfo(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
    );
  }

  String get displayName {
    final trimmed = name?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : email;
  }
}

class FriendSummary {
  final String friendshipId;
  final FriendUserInfo user;
  const FriendSummary({required this.friendshipId, required this.user});

  factory FriendSummary.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return FriendSummary(
      friendshipId: (json['friendshipId'] ?? json['id'] ?? '').toString(),
      user: userJson is Map<String, dynamic>
          ? FriendUserInfo.fromJson(userJson)
          : FriendUserInfo(id: '', email: ''),
    );
  }
}

class FriendRequestSummary {
  final String friendshipId;
  final DateTime createdAt;
  final FriendUserInfo requester;
  final FriendUserInfo addressee;
  const FriendRequestSummary({
    required this.friendshipId,
    required this.createdAt,
    required this.requester,
    required this.addressee,
  });

  factory FriendRequestSummary.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requester'];
    final addresseeJson = json['addressee'];
    return FriendRequestSummary(
      friendshipId: (json['friendshipId'] ?? json['id'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      requester: requesterJson is Map<String, dynamic>
          ? FriendUserInfo.fromJson(requesterJson)
          : FriendUserInfo(id: '', email: ''),
      addressee: addresseeJson is Map<String, dynamic>
          ? FriendUserInfo.fromJson(addresseeJson)
          : FriendUserInfo(id: '', email: ''),
    );
  }

  bool isIncoming(String currentUserId) => addressee.id == currentUserId;
}

class FriendSearchResult {
  final FriendUserInfo user;
  final String relationship; // NONE, FRIEND, PENDING_INCOMING, PENDING_OUTGOING
  final String? friendshipId;
  const FriendSearchResult({
    required this.user,
    required this.relationship,
    this.friendshipId,
  });

  factory FriendSearchResult.fromJson(Map<String, dynamic> json) {
    if (json['user'] is Map<String, dynamic>) {
      return FriendSearchResult(
        user: FriendUserInfo.fromJson(json['user'] as Map<String, dynamic>),
        relationship: (json['relationship'] ?? 'NONE').toString(),
        friendshipId: json['friendshipId']?.toString(),
      );
    }
    final info = FriendUserInfo(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
    );
    return FriendSearchResult(
      user: info,
      relationship: (json['relationship'] ?? 'NONE').toString(),
      friendshipId: json['friendshipId']?.toString(),
    );
  }
}
