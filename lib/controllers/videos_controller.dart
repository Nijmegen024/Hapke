import 'dart:convert';
import 'package:get/get.dart';
import '../../models/video.dart';
import '../../models/restaurant.dart';
import '../../models/friend.dart';
import '../../network/api_client.dart';
import '../../network/api_helpers.dart';
import '../../core/constants.dart';

class VideosController extends GetxController {
  final List<Restaurant> restaurants;
  final double? userLat;
  final double? userLng;

  final _videos = <String, List<VideoItem>>{}.obs;
  Map<String, List<VideoItem>> get videos => _videos;

  final _loadingAll = false.obs;
  bool get loadingAll => _loadingAll.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _activeIndex = 0.obs;
  int get activeIndex => _activeIndex.value;
  set activeIndex(int val) => _activeIndex.value = val;

  final _muted = true.obs;
  bool get muted => _muted.value;

  final _ordering = false.obs;
  bool get ordering => _ordering.value;

  final _orderSuccess = RxnString();
  String? get orderSuccess => _orderSuccess.value;

  VideosController({
    required this.restaurants,
    this.userLat,
    this.userLng,
  });

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  Future<void> loadFeed() async {
    _loadingAll.value = true;
    _error.value = null;
    _videos.clear();
    try {
      final res = await apiClient.get(
        Uri.parse('$apiBase/videos'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 404) {
        await loadAllVideos();
        return;
      } else if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = <VideoItem>[];
        if (data is List) {
          for (final v in data) {
            if (v is! Map<String, dynamic>) continue;
            final item = _parseVideoItem(v);
            if (item != null) list.add(item);
          }
        }
        _videos['feed'] = list;
      } else {
        _error.value = 'Video’s laden mislukt (${res.statusCode})';
      }
    } catch (e) {
      _error.value = 'Video’s laden mislukt: $e';
    } finally {
      _loadingAll.value = false;
    }
  }

  Future<void> loadAllVideos() async {
    _loadingAll.value = true;
    _error.value = null;
    _videos.clear();
    final sources = <VideoSource>[];
    sources.addAll(
      restaurants.map((r) => VideoSource(id: r.id, name: r.name)),
    );
    if (userLat != null && userLng != null) {
      try {
        final res = await apiClient.get(
          restaurantsUri(lat: userLat, lng: userLng),
          headers: {'Accept': 'application/json'},
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is List) {
            for (final r in data) {
              if (r is! Map<String, dynamic>) continue;
              final id = (r['id'] ?? r['vendorId'] ?? '').toString().trim();
              final name = (r['name'] ?? '').toString().trim();
              if (id.isEmpty || name.isEmpty) continue;
              sources.add(VideoSource(id: id, name: name));
            }
          }
        }
      } catch (_) {}
    }
    final seen = <String>{};
    final uniqueSources = sources.where((s) => seen.add(s.id)).toList();
    try {
      for (final r in uniqueSources) {
        await loadVideos(r.id, r.name);
      }
    } catch (e) {
      _error.value = 'Video’s laden mislukt: $e';
    } finally {
      _loadingAll.value = false;
    }
  }

  Future<void> loadVideos(String restaurantId, String restaurantName) async {
    try {
      final res = await apiClient.get(
        Uri.parse('$apiBase/restaurants/$restaurantId/videos'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = <VideoItem>[];
        if (data is List) {
          for (final v in data) {
            if (v is! Map<String, dynamic>) continue;
            final item = _parseVideoItem(v, restaurantId: restaurantId, restaurantName: restaurantName);
            if (item != null) list.add(item);
          }
        }
        _videos[restaurantId] = list;
      }
    } catch (_) {}
  }

  VideoItem? _parseVideoItem(Map<String, dynamic> v, {String? restaurantId, String? restaurantName}) {
    final id = (v['id'] ?? '').toString().trim();
    final title = (v['title'] ?? '').toString().trim();
    final url = (v['videoUrl'] ?? '').toString().trim();
    final restId = restaurantId ?? (v['restaurantId'] ?? v['vendorId'] ?? v['restaurant'] ?? '').toString().trim();
    String restName = restaurantName ?? (v['restaurantName'] ?? v['vendorName'] ?? '').toString().trim();
    if (id.isEmpty || title.isEmpty || url.isEmpty || restId.isEmpty) return null;
    if (restName.isEmpty) {
      final found = restaurants.firstWhere(
        (r) => r.id == restId,
        orElse: () => const Restaurant(id: '', name: '', cuisine: '', category: '', rating: 0, eta: '', menu: [], imageUrl: '', minOrder: 0),
      );
      restName = found.name.isNotEmpty ? found.name : 'Restaurant';
    }
    final rawThumb = (v['thumbUrl'] ?? '').toString().trim();
    final menuItemId = (v['menuItemId'] ?? '').toString().trim();
    final priceRaw = v['price'];
    final price = priceRaw is num ? priceRaw.toDouble() : null;
    final likesCount = v['likesCount'] is num ? (v['likesCount'] as num).round() : 0;
    final likedByMe = v['likedByMe'] == true;
    return VideoItem(
      id: id,
      restaurantId: restId,
      restaurantName: restName.isEmpty ? 'Restaurant' : restName,
      title: title,
      description: (v['description'] ?? '').toString(),
      videoUrl: url,
      price: price,
      menuItemId: menuItemId.isEmpty ? null : menuItemId,
      thumbUrl: rawThumb.isEmpty ? null : rawThumb,
      likesCount: likesCount,
      likedByMe: likedByMe,
    );
  }

  List<VideoItem> allVideos() {
    final flattened = <VideoItem>[];
    for (final list in _videos.values) {
      flattened.addAll(list);
    }
    return flattened;
  }

  void _updateVideoItem(String id, VideoItem Function(VideoItem current) transform) {
    _videos.updateAll((key, list) {
        return list.map((item) => item.id == id ? transform(item) : item).toList();
    });
  }

  Future<void> toggleLike(VideoItem v) async {
    final targetLiked = !v.likedByMe;
    final optimisticLikes = targetLiked ? v.likesCount + 1 : (v.likesCount - 1).clamp(0, 1000000);
    _updateVideoItem(v.id, (cur) => cur.copyWith(likesCount: optimisticLikes, likedByMe: targetLiked));
    try {
      final res = await (targetLiked
          ? apiClient.post(Uri.parse('$apiBase/videos/${v.id}/like'), headers: {'Accept': 'application/json'})
          : apiClient.delete(Uri.parse('$apiBase/videos/${v.id}/like'), headers: {'Accept': 'application/json'}));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final likesCount = body is Map && body['likesCount'] is num ? body['likesCount'] : null;
        final likedByMe = body is Map && body['likedByMe'] == true;
        if (likesCount != null) {
          _updateVideoItem(v.id, (cur) => cur.copyWith(likesCount: (likesCount as num).round(), likedByMe: likedByMe));
        }
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (e) {
      _updateVideoItem(v.id, (cur) => cur.copyWith(likesCount: v.likesCount, likedByMe: v.likedByMe));
      _error.value = 'Like mislukt: $e';
    }
  }

  Future<List<VideoComment>> fetchComments(String videoId) async {
    final res = await apiClient.get(Uri.parse('$apiBase/videos/$videoId/comments'), headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Status ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    final list = <VideoComment>[];
    if (decoded is List) {
      for (final c in decoded) {
        if (c is! Map<String, dynamic>) continue;
        final id = (c['id'] ?? '').toString();
        final text = (c['text'] ?? '').toString();
        final createdAt = DateTime.tryParse((c['createdAt'] ?? '').toString()) ?? DateTime.now();
        String userName = '';
        if (c['user'] is Map<String, dynamic>) {
          final user = c['user'] as Map<String, dynamic>;
          userName = (user['name'] ?? user['email'] ?? '').toString();
        }
        if (userName.isEmpty) userName = 'Gebruiker';
        if (id.isEmpty || text.isEmpty) continue;
        list.add(VideoComment(id: id, userName: userName, text: text, createdAt: createdAt));
      }
    }
    return list;
  }

  Future<VideoComment?> postComment(String videoId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final res = await apiClient.post(
      Uri.parse('$apiBase/videos/$videoId/comments'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'text': trimmed}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Status ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? '').toString();
      final createdAt = DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime.now();
      String userName = '';
      if (data['user'] is Map<String, dynamic>) {
        final user = data['user'] as Map<String, dynamic>;
        userName = (user['name'] ?? user['email'] ?? '').toString();
      }
      if (userName.isEmpty) userName = 'Jij';
      return VideoComment(id: id, userName: userName, text: trimmed, createdAt: createdAt);
    }
    return null;
  }

  Future<List<ShareFriend>> fetchShareFriends() async {
    try {
      final res = await apiClient.get(Uri.parse('$apiBase/friends'), headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(FriendSummary.fromJson)
            .where((f) => f.user.id.isNotEmpty)
            .map((f) => ShareFriend(id: f.user.id, name: f.user.displayName))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> sendVideoToFriend({required String videoId, required String toUserId}) async {
    final res = await apiClient.post(
      Uri.parse('$apiBase/video-shares'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'toUserId': toUserId, 'videoId': videoId}),
    );
    if (res.statusCode == 404) throw Exception('Server ondersteunt delen nog niet (404)');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Status ${res.statusCode}');
  }

  void toggleMute() {
    _muted.value = !_muted.value;
  }
}

extension VideoItemCopy on VideoItem {
  VideoItem copyWith({int? likesCount, bool? likedByMe}) {
    return VideoItem(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      title: title,
      description: description,
      videoUrl: videoUrl,
      price: price,
      menuItemId: menuItemId,
      thumbUrl: thumbUrl,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class VideoSource {
  final String id;
  final String name;
  VideoSource({required this.id, required this.name});
}
