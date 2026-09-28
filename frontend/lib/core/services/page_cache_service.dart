import '../models/page.dart';
import '../storage/storage_service.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';

/// Service for caching pages locally for faster loading and offline access
class PageCacheService {
  final StorageService _storage = StorageService.instance;
  final ApiClient _apiClient = ApiClient.instance;

  static PageCacheService? _instance;

  PageCacheService._internal();

  static PageCacheService get instance {
    _instance ??= PageCacheService._internal();
    return _instance!;
  }

  /// Get a page with cache-first strategy
  /// 1. Check cache first for instant loading
  /// 2. Fetch from server in background
  /// 3. Update cache if server version is newer
  Future<PageModel?> getPageWithCache(
    String pageId, {
    bool forceRefresh = false,
  }) async {
    PageModel? cachedPage;

    // Step 1: Load from cache first (unless force refresh)
    if (!forceRefresh) {
      cachedPage = _storage.getPage(pageId);
      if (cachedPage != null) {
        print('📦 Loaded page $pageId from cache (v${cachedPage.version})');
      }
    }

    // Step 2: Fetch from server
    try {
      final response = await _apiClient.get(ApiEndpoints.pageById(pageId));
      final serverPage = PageModel.fromJson(response.data['data']);

      print('🌐 Fetched page $pageId from server (v${serverPage.version})');

      // Step 3: Update cache if server version is newer or no cache exists
      if (cachedPage == null || serverPage.version >= cachedPage.version) {
        await _storage.savePage(serverPage);
        print('💾 Updated cache for page $pageId');
        return serverPage;
      }

      // Return cached version if it's the same or newer
      return cachedPage;
    } catch (e) {
      print('⚠️ Failed to fetch page from server: $e');

      // Return cached version if available (offline mode)
      if (cachedPage != null) {
        print('📦 Using cached page $pageId (offline mode)');
        return cachedPage;
      }

      rethrow; // No cache available, propagate error
    }
  }

  /// Save page to cache immediately
  Future<void> cachePage(PageModel page) async {
    await _storage.savePage(page);
    print('💾 Page ${page.id} cached');
  }

  /// Update cache after local changes
  Future<void> updateCache(String pageId, PageModel updatedPage) async {
    await _storage.savePage(updatedPage);
    print('🔄 Cache updated for page $pageId');
  }

  /// Remove page from cache
  Future<void> removeCachedPage(String pageId) async {
    await _storage.deletePage(pageId);
    print('🗑️ Removed page $pageId from cache');
  }

  /// Preload pages for faster access
  Future<void> preloadPages(List<String> pageIds) async {
    print('⏳ Preloading ${pageIds.length} pages...');

    int successCount = 0;
    for (final pageId in pageIds) {
      try {
        await getPageWithCache(pageId);
        successCount++;
      } catch (e) {
        print('⚠️ Failed to preload page $pageId: $e');
      }
    }

    print('✅ Preloaded $successCount/${pageIds.length} pages');
  }

  /// Get all cached pages (for offline viewing)
  List<PageModel> getCachedPages() {
    final pages = _storage.getAllPages();
    print('📦 Found ${pages.length} cached pages');
    return pages;
  }

  /// Check if page is cached
  bool isPageCached(String pageId) {
    return _storage.isPageCached(pageId);
  }

  /// Synchronously read a page straight out of the local cache, or null if
  /// it isn't cached. Used for instant-paint-then-reconcile loading, where
  /// the caller needs the cached copy before the network call resolves.
  PageModel? getCachedPage(String pageId) {
    return _storage.getPage(pageId);
  }

  /// Clear all cached pages
  Future<void> clearCache() async {
    await _storage.clearAllPages();
    print('🗑️ Cleared all page cache');
  }

  /// Sync cache with server (update stale pages)
  Future<void> syncCache() async {
    final cachedPages = _storage.getAllPages();
    print('🔄 Syncing ${cachedPages.length} cached pages...');

    int updatedCount = 0;
    for (final cachedPage in cachedPages) {
      try {
        final response = await _apiClient.get(
          ApiEndpoints.pageById(cachedPage.id),
        );
        final serverPage = PageModel.fromJson(response.data['data']);

        // Update cache if server has newer version
        if (serverPage.version > cachedPage.version) {
          await _storage.savePage(serverPage);
          updatedCount++;
          print(
            '🔄 Updated page ${cachedPage.id} (v${cachedPage.version} → v${serverPage.version})',
          );
        }
      } catch (e) {
        print('⚠️ Failed to sync page ${cachedPage.id}: $e');
      }
    }

    print('✅ Sync complete: $updatedCount pages updated');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final cachedPages = _storage.getAllPages();

    return {
      'totalPages': cachedPages.length,
      'pageIds': cachedPages.map((p) => p.id).toList(),
      'totalWidgets': cachedPages.fold<int>(
        0,
        (sum, page) => sum + page.pageData.widgets.length,
      ),
      'oldestUpdate': cachedPages.isEmpty
          ? null
          : cachedPages
                .map((p) => p.updatedAt)
                .reduce((a, b) => a.isBefore(b) ? a : b),
      'newestUpdate': cachedPages.isEmpty
          ? null
          : cachedPages
                .map((p) => p.updatedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// Print cache statistics
  void printCacheStats() {
    final stats = getCacheStats();
    print('📊 Page Cache Statistics:');
    print('   Total pages: ${stats['totalPages']}');
    print('   Total widgets: ${stats['totalWidgets']}');
    if (stats['oldestUpdate'] != null) {
      print('   Oldest update: ${stats['oldestUpdate']}');
    }
    if (stats['newestUpdate'] != null) {
      print('   Newest update: ${stats['newestUpdate']}');
    }
  }
}
