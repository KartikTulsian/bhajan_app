import 'package:bhajan_app/service/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final _supabase = SupabaseService();

  // In-memory cache
  List<Map<String, dynamic>>? _bhajansCache;
  List<Map<String, dynamic>>? _lyricsCache;

  // Hive boxes
  Box<dynamic>? _bhajanBox;
  Box<dynamic>? _lyricsBox;

  // Cache expiry (24 hours)
  static const Duration cacheExpiry = Duration(hours: 24);

  // Initialization flag
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Initialize Hive boxes (call this in main.dart before runApp)
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Try to get already opened boxes first
      try {
        _bhajanBox = Hive.box('bhajansCache');
        debugPrint('📦 Using existing bhajansCache box');
      } catch (e) {
        // Box not opened, open it now
        _bhajanBox = await Hive.openBox('bhajansCache');
        debugPrint('📦 Opened new bhajansCache box');
      }

      try {
        _lyricsBox = Hive.box('lyricsCache');
        debugPrint('📦 Using existing lyricsCache box');
      } catch (e) {
        // Box not opened, open it now
        _lyricsBox = await Hive.openBox('lyricsCache');
        debugPrint('📦 Opened new lyricsCache box');
      }

      _isInitialized = true;
      debugPrint('✅ CacheManager initialized');
    } catch (e) {
      debugPrint('❌ CacheManager initialization error: $e');
      _bhajanBox = null;
      _lyricsBox = null;
    } finally {
      _isInitializing = false;
    }
  }

  /// Fetch bhajans with smart caching
  Future<List<Map<String, dynamic>>> getBhajans({bool forceRefresh = false}) async {
    // Ensure initialization
    if (!_isInitialized) {
      await initialize();
    }

    // Return in-memory cache if available
    if (!forceRefresh && _bhajansCache != null && _bhajansCache!.isNotEmpty) {
      debugPrint('📦 Returning bhajans from memory cache');
      return _bhajansCache!;
    }

    // Check Hive cache first (before network call)
    List<Map<String, dynamic>>? cachedData;
    if (!forceRefresh) {
      final cacheDataRaw = _bhajanBox?.get('bhajans_data');
      final cacheTime = _bhajanBox?.get('bhajans_timestamp');

      if (cacheDataRaw != null && cacheTime != null) {
        final timestamp = DateTime.parse(cacheTime.toString());
        final isExpired = DateTime.now().difference(timestamp) > cacheExpiry;

        // 🧩 Force-convert to correct type
        final converted = (cacheDataRaw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (!isExpired) {
          debugPrint('📦 Returning bhajans from Hive cache (fresh)');
          _bhajansCache = converted;
          return _bhajansCache!;
        } else {
          // Cache expired, but keep it as fallback
          cachedData = converted;
          debugPrint('⏰ Hive cache expired, will try network with fallback ready');
        }
      }
    }

    // Fetch from network
    try {
      debugPrint('🌐 Fetching bhajans from network...');
      final raw = await _supabase.fetchBhajans().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Network timeout'),
      );

      List<Map<String, dynamic>> fetched = [];
      if (raw is List) {
        try {
          fetched = raw.map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
        } catch (_) {
          fetched = List<Map<String, dynamic>>.from(raw);
        }
      }

      if (fetched.isNotEmpty) {
        // Update caches
        _bhajansCache = fetched;
        await _bhajanBox?.put('bhajans_data', fetched);
        await _bhajanBox?.put('bhajans_timestamp', DateTime.now().toIso8601String());

        debugPrint('✅ Bhajans fetched and cached: ${fetched.length} items');
        return fetched;
      } else {
        throw Exception('Empty response from server');
      }

    } catch (e) {
      debugPrint('❌ Network fetch failed: $e');

      // Use cached data as fallback (even if expired)
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('⚠️ Using cached data as fallback (${cachedData.length} items)');
        _bhajansCache = cachedData;
        return cachedData;
      }

      // Last resort: check if we have any cache at all
      final lastResortCache = _bhajanBox?.get('bhajans_data');
      if (lastResortCache != null) {
        debugPrint('⚠️ Using stale cache as last resort');
        _bhajansCache = List<Map<String, dynamic>>.from(lastResortCache);
        return _bhajansCache!;
      }

      // No cache available at all
      debugPrint('❌ No cache available, returning empty list');
      return [];
    }
  }

  /// Fetch lyrics with smart caching
  Future<List<Map<String, dynamic>>> getLyrics({bool forceRefresh = false}) async {
    // Ensure initialization
    if (!_isInitialized) {
      await initialize();
    }

    // Return in-memory cache if available
    if (!forceRefresh && _lyricsCache != null && _lyricsCache!.isNotEmpty) {
      debugPrint('📦 Returning lyrics from memory cache');
      return _lyricsCache!;
    }

    // Check Hive cache first (before network call)
    List<Map<String, dynamic>>? cachedData;
    if (!forceRefresh) {
      final cacheDataRaw = _lyricsBox?.get('lyrics_data');
      final cacheTime = _lyricsBox?.get('lyrics_timestamp');

      if (cacheDataRaw != null && cacheTime != null) {
        final timestamp = DateTime.parse(cacheTime.toString());
        final isExpired = DateTime.now().difference(timestamp) > cacheExpiry;

        // 🧩 Force-convert to correct type
        final converted = (cacheDataRaw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (!isExpired) {
          debugPrint('📦 Returning lyrics from Hive cache (fresh)');
          _lyricsCache = converted;
          return _lyricsCache!;
        } else {
          cachedData = converted;
          debugPrint('⏰ Hive cache expired, will try network with fallback ready');
        }
      }

    }

    // Fetch from network
    try {
      debugPrint('🌐 Fetching lyrics from network...');
      final raw = await _supabase.fetchLyrics().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Network timeout'),
      );

      List<Map<String, dynamic>> fetched = [];
      if (raw is List) {
        try {
          fetched = raw.map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
        } catch (_) {
          fetched = List<Map<String, dynamic>>.from(raw);
        }
      }

      if (fetched.isNotEmpty) {
        // Sort alphabetically
        fetched.sort((a, b) => a['lyricsName']
            .toString()
            .toLowerCase()
            .compareTo(b['lyricsName'].toString().toLowerCase()));

        // Update caches
        _lyricsCache = fetched;
        await _lyricsBox?.put('lyrics_data', fetched);
        await _lyricsBox?.put('lyrics_timestamp', DateTime.now().toIso8601String());

        debugPrint('✅ Lyrics fetched and cached: ${fetched.length} items');
        return fetched;
      } else {
        throw Exception('Empty response from server');
      }

    } catch (e) {
      debugPrint('❌ Network fetch failed: $e');

      // Use cached data as fallback (even if expired)
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('⚠️ Using cached data as fallback (${cachedData.length} items)');
        _lyricsCache = cachedData;
        return cachedData;
      }

      // Last resort: check if we have any cache at all
      final lastResortCache = _lyricsBox?.get('lyrics_data');
      if (lastResortCache != null) {
        debugPrint('⚠️ Using stale cache as last resort');
        _lyricsCache = List<Map<String, dynamic>>.from(lastResortCache);
        return _lyricsCache!;
      }

      // No cache available at all
      debugPrint('❌ No cache available, returning empty list');
      return [];
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();

    _bhajansCache = null;
    _lyricsCache = null;
    await _bhajanBox?.clear();
    await _lyricsBox?.clear();
    debugPrint('🗑️ All caches cleared');
  }

  /// Invalidate bhajans cache (force refresh on next fetch)
  Future<void> invalidateBhajansCache() async {
    if (!_isInitialized) await initialize();

    _bhajansCache = null;
    await _bhajanBox?.delete('bhajans_data');
    await _bhajanBox?.delete('bhajans_timestamp');
    debugPrint('🔄 Bhajans cache invalidated');
  }

  /// Invalidate lyrics cache (force refresh on next fetch)
  Future<void> invalidateLyricsCache() async {
    if (!_isInitialized) await initialize();

    _lyricsCache = null;
    await _lyricsBox?.delete('lyrics_data');
    await _lyricsBox?.delete('lyrics_timestamp');
    debugPrint('🔄 Lyrics cache invalidated');
  }

  /// Check if data is available offline
  bool get hasOfflineBhajans =>
      _bhajansCache != null || _bhajanBox?.get('bhajans_data') != null;

  bool get hasOfflineLyrics =>
      _lyricsCache != null || _lyricsBox?.get('lyrics_data') != null;
}