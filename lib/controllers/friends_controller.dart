import 'dart:convert';
import 'package:get/get.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../models/friend.dart';
import '../../network/api_client.dart';
import '../../network/api_helpers.dart';

class FriendsController extends GetxController {
  final HapkeUser? currentUser;
  
  final _loading = false.obs;
  bool get loading => _loading.value;

  final _searching = false.obs;
  bool get searching => _searching.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _friends = <FriendSummary>[].obs;
  List<FriendSummary> get friends => _friends;

  final _incoming = <FriendRequestSummary>[].obs;
  List<FriendRequestSummary> get incoming => _incoming;

  final _outgoing = <FriendRequestSummary>[].obs;
  List<FriendRequestSummary> get outgoing => _outgoing;

  final _searchResults = <FriendSearchResult>[].obs;
  List<FriendSearchResult> get searchResults => _searchResults;

  FriendsController({required this.currentUser});

  @override
  void onInit() {
    super.onInit();
    if (currentUser != null) {
      loadAll();
    }
  }

  Future<void> loadAll() async {
    if (currentUser == null) return;
    _loading.value = true;
    _error.value = null;
    try {
      final friendsList = await _fetchFriends();
      final pending = await _fetchPending();
      _friends.value = friendsList;
      _incoming.value = pending['incoming'] ?? [];
      _outgoing.value = pending['outgoing'] ?? [];
    } catch (e) {
      _error.value = 'Kon vrienden niet laden: $e';
    } finally {
      _loading.value = false;
    }
  }

  Future<List<FriendSummary>> _fetchFriends() async {
    final res = await apiClient.get(
      Uri.parse('$apiBase/friends'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception(extractErrorMessage(res));
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FriendSummary.fromJson)
          .where((f) => f.user.id.isNotEmpty)
          .toList();
    }
    return const <FriendSummary>[];
  }

  Future<Map<String, List<FriendRequestSummary>>> _fetchPending() async {
    final res = await apiClient.get(
      Uri.parse('$apiBase/friends/requests'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception(extractErrorMessage(res));
    }
    final decoded = jsonDecode(res.body);
    final incomingList =
        decoded is Map<String, dynamic> && decoded['incoming'] is List
        ? (decoded['incoming'] as List)
              .whereType<Map<String, dynamic>>()
              .map(FriendRequestSummary.fromJson)
              .where((f) => f.friendshipId.isNotEmpty)
              .toList()
        : <FriendRequestSummary>[];
    final outgoingList =
        decoded is Map<String, dynamic> && decoded['outgoing'] is List
        ? (decoded['outgoing'] as List)
              .whereType<Map<String, dynamic>>()
              .map(FriendRequestSummary.fromJson)
              .where((f) => f.friendshipId.isNotEmpty)
              .toList()
        : <FriendRequestSummary>[];
    return {'incoming': incomingList, 'outgoing': outgoingList};
  }

  Future<void> handleSearch(String query) async {
    if (currentUser == null) return;
    query = query.trim();
    if (query.length < 2) {
      _searchResults.clear();
      return;
    }
    _searching.value = true;
    _error.value = null;
    try {
      final uri = Uri.parse(
        '$apiBase/friends/search?q=${Uri.encodeQueryComponent(query)}',
      );
      final res = await apiClient.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        throw Exception(extractErrorMessage(res));
      }
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        final results = decoded
            .whereType<Map<String, dynamic>>()
            .map(FriendSearchResult.fromJson)
            .where((r) => r.user.id.isNotEmpty && r.user.id != currentUser!.id)
            .toList();
        _searchResults.value = results;
      } else {
        _searchResults.clear();
      }
    } catch (e) {
      _error.value = 'Zoeken mislukt: $e';
    } finally {
      _searching.value = false;
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    _searching.value = true;
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/friends/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'targetUserId': userId}),
      );
      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception(extractErrorMessage(res));
      }
      await loadAll();
      return true;
    } catch (e) {
      _error.value = 'Kon verzoek niet versturen: $e';
      return false;
    } finally {
      _searching.value = false;
    }
  }

  Future<void> respondToRequest(String friendshipId, String action) async {
    try {
      final res = await apiClient.patch(
        Uri.parse('$apiBase/friends/requests/$friendshipId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );
      if (res.statusCode != 200) {
        throw Exception(extractErrorMessage(res));
      }
      await loadAll();
    } catch (e) {
      _error.value = 'Kon verzoek niet bijwerken: $e';
    }
  }
}
