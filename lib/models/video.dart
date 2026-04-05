class VideoItem {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String title;
  final String description;
  final String videoUrl;
  final double? price;
  final String? menuItemId;
  final String? thumbUrl;
  final int likesCount;
  final bool likedByMe;
  VideoItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.price,
    this.menuItemId,
    this.thumbUrl,
    this.likesCount = 0,
    this.likedByMe = false,
  });
}

class VideoComment {
  final String id;
  final String userName;
  final String text;
  final DateTime createdAt;
  VideoComment({
    required this.id,
    required this.userName,
    required this.text,
    required this.createdAt,
  });
}

class ShareFriend {
  final String id;
  final String name;
  const ShareFriend({required this.id, required this.name});
}

class VideoSource {
  final String id;
  final String name;
  const VideoSource({required this.id, required this.name});
}
