import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../data/models/vocab_model.dart';

/// Custom exception for authentication errors (HTTP 401).
class CloudflareAuthException implements Exception {
  final String message;
  CloudflareAuthException(this.message);

  @override
  String toString() => 'CloudflareAuthException: $message';
}

/// Custom exception for API errors (HTTP 4xx/5xx).
class CloudflareApiException implements Exception {
  final int statusCode;
  final String message;
  CloudflareApiException(this.statusCode, this.message);

  @override
  String toString() => 'CloudflareApiException($statusCode): $message';
}

/// Service backing all data operations with Cloudflare D1 + Workers API.
///
/// All data operations (flashcards, history, bookmarks, streak) go through
/// a Cloudflare Worker REST API backed by D1 (SQLite).
/// Firebase Auth is used for authentication — the Worker verifies
/// the Firebase JWT token on every request.
class CloudflareService {
  final http.Client _client;
  final String _baseUrl;

  CloudflareService({
    http.Client? client,
    String baseUrl = 'https://lexiflow-api.quoctrunghrnk.workers.dev/api/v1',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  // ---------------------------------------------------------------
  // JWT Token Management
  // ---------------------------------------------------------------

  /// Get the current user's Firebase ID token for Worker authentication.
  /// Uses [getIdToken(true)] to force a refresh and avoid expiry mid-session.
  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// Build authorization headers with the Firebase JWT token.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _getIdToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  // ---------------------------------------------------------------
  // Generic HTTP Helpers
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final headers = await _authHeaders();
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw CloudflareAuthException('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    if (response.statusCode >= 400) {
      String errorMsg = 'Lỗi máy chủ (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          errorMsg = body['error'].toString();
        }
      } catch (_) {}
      throw CloudflareApiException(response.statusCode, errorMsg);
    }
  }

  // ---------------------------------------------------------------
  // Spaced Repetition Flashcards
  // ---------------------------------------------------------------

  /// Lấy tất cả thẻ flashcard của user, sắp xếp theo [nextReview] tăng dần.
  Future<List<Vocab>> getSpacedRepetitionVocabs(String uid) async {
    final data = await _get('/flashcards');
    final vocabsJson = (data['vocabs'] as List<dynamic>?) ?? [];
    return vocabsJson
        .map((j) => Vocab.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Lấy các thẻ flashcard đến hạn ôn tập (nextReview <= now).
  Future<List<Vocab>> getDueVocabs(String uid) async {
    final data = await _get('/flashcards/due');
    final vocabsJson = (data['vocabs'] as List<dynamic>?) ?? [];
    return vocabsJson
        .map((j) => Vocab.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Lưu hoặc cập nhật 1 thẻ flashcard.
  /// Nếu [vocab.id] rỗng → tạo mới. Ngược lại → cập nhật.
  Future<void> saveVocabToReview(String uid, Vocab vocab) async {
    await _post('/flashcards', vocab.toCloudflareMap());
  }

  /// Xóa 1 thẻ flashcard khỏi danh sách ôn tập.
  Future<void> deleteVocabFromReview(String uid, String vocabId) async {
    await _delete('/flashcards/$vocabId');
  }

  // ---------------------------------------------------------------
  // Search History
  // ---------------------------------------------------------------

  /// Lấy tối đa 30 mục lịch sử tra từ gần nhất.
  Future<List<Map<String, dynamic>>> getSearchHistory(String uid) async {
    final data = await _get('/history');
    final historyJson = (data['history'] as List<dynamic>?) ?? [];
    return historyJson.map((item) {
      final m = item as Map<String, dynamic>;
      return {
        'id': m['id'] ?? '',
        'word': m['word'] ?? '',
        'translation': m['translation'] ?? '',
        'timestamp': m['timestamp'],
      };
    }).toList();
  }

  /// Thêm một từ vào lịch sử tra cứu (upsert by word).
  Future<void> addToHistory(String uid, String word, String translation) async {
    await _post('/history', {
      'word': word,
      'translation': translation,
    });
  }

  /// Xóa 1 mục khỏi lịch sử tra từ.
  Future<void> deleteHistoryItem(String uid, String word) async {
    final encoded = Uri.encodeComponent(word.toLowerCase().trim());
    await _delete('/history/$encoded');
  }

  /// Xóa toàn bộ lịch sử tra từ của user.
  Future<void> clearAllHistory(String uid) async {
    await _delete('/history');
  }

  // ---------------------------------------------------------------
  // Bookmarks (Từ đã lưu)
  // ---------------------------------------------------------------

  /// Lấy danh sách word IDs đã bookmark (dùng để check nhanh).
  Future<List<String>> getBookmarks(String uid) async {
    final data = await _get('/bookmarks');
    final wordsJson = (data['words'] as List<dynamic>?) ?? [];
    return wordsJson.map((w) => w.toString()).toList();
  }

  /// Lấy danh sách bookmark đầy đủ (word + translation).
  Future<List<Map<String, String>>> getBookmarksList(String uid) async {
    final data = await _get('/bookmarks/list');
    final bookmarksJson = (data['bookmarks'] as List<dynamic>?) ?? [];
    return bookmarksJson.map((item) {
      final m = item as Map<String, dynamic>;
      return {
        'word': (m['word'] ?? '').toString(),
        'translation': (m['translation'] ?? '').toString(),
      };
    }).toList();
  }

  /// Thêm hoặc xóa bookmark cho 1 từ.
  Future<void> toggleBookmark(
    String uid,
    String word,
    bool makeBookmarked, {
    String translation = '',
  }) async {
    await _post('/bookmarks', {
      'word': word,
      'makeBookmarked': makeBookmarked,
      'translation': translation,
    });
  }

  /// Kiểm tra 1 từ đã được bookmark hay chưa.
  Future<bool> isWordBookmarked(String uid, String word) async {
    try {
      final encoded = Uri.encodeComponent(word.toLowerCase().trim());
      final data = await _get('/bookmarks/$encoded');
      return data['isBookmarked'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Study Streak
  // ---------------------------------------------------------------

  /// Lấy streak học tập hiện tại (số ngày liên tiếp).
  Future<int> getStudyStreak(String uid) async {
    try {
      final data = await _get('/streak');
      return (data['streak'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Lấy đầy đủ dữ liệu streak: current + longest.
  Future<Map<String, int>> getStreakData() async {
    try {
      final data = await _get('/streak');
      return {
        'current': (data['streak'] as num?)?.toInt() ?? 0,
        'longest': (data['longest_streak'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'current': 0, 'longest': 0};
    }
  }

  /// Ghi nhận phiên học hôm nay, cập nhật streak.
  Future<void> updateStudyStreak(String uid) async {
    await _post('/streak', {});
  }

  // ---------------------------------------------------------------
  // Farm Mini-Game
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> getFarmState() async {
    final data = await _get('/farm/state');
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> farmPlant(int slotIndex, String cropType) async {
    await _post('/farm/plant', {'slot_index': slotIndex, 'crop_type': cropType});
  }

  Future<void> farmWater(int drops) async {
    await _post('/farm/water', {'drops': drops});
  }

  Future<Map<String, dynamic>> farmHarvest(String plotId) async {
    final data = await _post('/farm/harvest', {'plot_id': plotId});
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> farmFulfillOrder(String orderId) async {
    final data = await _post('/farm/orders/$orderId/fulfill', {});
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> farmSkipOrder(String orderId) async {
    await _post('/farm/orders/$orderId/skip', {});
  }

  // ---------------------------------------------------------------
  // Home Mini-Game (Pet + Room)
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> getHomeState() async {
    final data = await _get('/home/state');
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> petFeed(String itemId) async {
    await _post('/home/pet/feed', {'item_id': itemId});
  }

  Future<void> petPlay(String itemId) async {
    await _post('/home/pet/play', {'item_id': itemId});
  }

  Future<void> shopBuyFurniture(String itemId, int roomSlot) async {
    await _post('/home/shop/buy', {'item_id': itemId, 'room_slot': roomSlot});
  }

  Future<void> removeFurniture(String id) async {
    await _delete('/home/furniture/$id');
  }

  Future<void> renamePet(String name) async {
    await _patch('/home/pet/rename', {'name': name});
  }

  // ---------------------------------------------------------------
  // Deck Summary
  // ---------------------------------------------------------------

  /// Lấy tóm tắt số lượng flashcard (single aggregated query, không tải toàn bộ list).
  Future<Map<String, int>> getDeckSummary() async {
    try {
      final data = await _get('/decks/summary');
      final summary = data['data']?['summary'] as Map<String, dynamic>? ?? {};
      return {
        'totalCards': (summary['totalCards'] as num?)?.toInt() ?? 0,
        'dueCards': (summary['dueCards'] as num?)?.toInt() ?? 0,
        'newCards': (summary['newCards'] as num?)?.toInt() ?? 0,
        'learningCards': (summary['learningCards'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'totalCards': 0, 'dueCards': 0, 'newCards': 0, 'learningCards': 0};
    }
  }

  // ---------------------------------------------------------------
  // Admin API
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> adminGetStats() async {
    final data = await _get('/admin/stats');
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<Map<String, dynamic>>> adminGetUsers({String q = '', int limit = 20, int offset = 0}) async {
    final path = '/admin/users?q=${Uri.encodeComponent(q)}&limit=$limit&offset=$offset';
    final data = await _get(path);
    return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminGetUser(String uid) async {
    final data = await _get('/admin/users/$uid');
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> adminEditUser(String uid, {
    int? grantXp,
    int? setLevel,
    String? displayName,
    int? grantCoins,
  }) async {
    final body = <String, dynamic>{};
    if (grantXp != null) body['grant_xp'] = grantXp;
    if (setLevel != null) body['set_level'] = setLevel;
    if (displayName != null) body['display_name'] = displayName;
    if (grantCoins != null) body['grant_coins'] = grantCoins;
    await _patch('/admin/users/$uid', body);
  }

  Future<void> adminDeleteUser(String uid) async {
    await _delete('/admin/users/$uid');
  }

  Future<void> adminBanUser(String uid, {String reason = ''}) async {
    await _post('/admin/users/$uid/ban', {'reason': reason});
  }

  Future<void> adminUnbanUser(String uid) async {
    await _post('/admin/users/$uid/unban', {});
  }

  Future<String> adminResetPassword(String uid) async {
    final data = await _post('/admin/users/$uid/reset-password', {});
    return (data['data']?['email'] ?? '').toString();
  }

  Future<List<Map<String, dynamic>>> adminGetContentCandidates({
    String q = '',
    int limit = 20,
    int offset = 0,
  }) async {
    final path = '/admin/content/candidates?q=${Uri.encodeComponent(q)}&limit=$limit&offset=$offset';
    final data = await _get(path);
    return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> adminGetCuratedContent({
    int limit = 30,
    int offset = 0,
  }) async {
    final data = await _get('/admin/content/curated?limit=$limit&offset=$offset');
    return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> adminCurateContent(String cardId, {String category = 'general'}) async {
    await _post('/admin/content/curate', {'card_id': cardId, 'category': category});
  }

  Future<void> adminRemoveCurated(String id) async {
    await _delete('/admin/content/curated/$id');
  }

  Future<List<Map<String, dynamic>>> adminGetLeaderboard({int limit = 10}) async {
    final data = await _get('/admin/leaderboard?limit=$limit');
    return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminGetFarmStats() async {
    final data = await _get('/admin/farm/stats');
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<Map<String, dynamic>>> adminGetActivity({int days = 7}) async {
    final data = await _get('/admin/activity?days=$days');
    return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> adminGetFlaggedSessions() async {
    final data = await _get('/battle/admin/flagged');
    final sessions = (data['data']?['flaggedSessions'] as List?) ?? [];
    return sessions.cast<Map<String, dynamic>>();
  }

  Future<void> adminResolveSession(String sessionId, String action) async {
    await _post('/battle/admin/resolve', {'sessionId': sessionId, 'action': action});
  }
}
