import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/page.dart';

/// Unified storage service using Hive
/// Provides type-safe access to different storage boxes
class StorageService {
  static StorageService? _instance;
  
  // Box names
  static const String _authBoxName = 'auth';
  static const String _pagesBoxName = 'pages';
  static const String _draftsBoxName = 'drafts';
  static const String _operationsBoxName = 'operations';
  static const String _settingsBoxName = 'settings';

  // Boxes
  Box<User>? _authBox;
  Box<PageModel>? _pagesBox;
  Box<PageModel>? _draftsBox;
  Box<Map>? _operationsBox;
  Box? _settingsBox;

  StorageService._internal();

  static StorageService get instance {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  /// Initialize all Hive boxes
  /// This should be called once at app startup
  Future<void> init() async {
    try {
      // Open all boxes
      _authBox = await Hive.openBox<User>(_authBoxName);
      _pagesBox = await Hive.openBox<PageModel>(_pagesBoxName);
      _draftsBox = await Hive.openBox<PageModel>(_draftsBoxName);
      _operationsBox = await Hive.openBox<Map>(_operationsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      
      print('✅ Hive storage initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Hive: $e');
      rethrow;
    }
  }

  /// Close all boxes (for cleanup)
  Future<void> close() async {
    await _authBox?.close();
    await _pagesBox?.close();
    await _draftsBox?.close();
    await _operationsBox?.close();
    await _settingsBox?.close();
  }

  // ==================== AUTH BOX ====================

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    await _settingsBox?.put('auth_token', token);
    print('🔑 Auth token saved to Hive');
  }

  /// Get auth token
  String? getAuthToken() {
    return _settingsBox?.get('auth_token') as String?;
  }

  /// Clear auth token
  Future<void> clearAuthToken() async {
    await _settingsBox?.delete('auth_token');
    print('🔑 Auth token cleared from Hive');
  }

  /// Save current user
  Future<void> saveUser(User user) async {
    await _authBox?.put('current_user', user);
    print('👤 User saved to Hive');
  }

  /// Get current user
  User? getUser() {
    return _authBox?.get('current_user');
  }

  /// Clear current user
  Future<void> clearUser() async {
    await _authBox?.delete('current_user');
    print('👤 User cleared from Hive');
  }

  /// Clear all auth data (token + user)
  Future<void> clearAuthData() async {
    await clearAuthToken();
    await clearUser();
    print('✅ All auth data cleared from Hive');
  }

  // ==================== PAGES BOX ====================

  /// Save a page to cache
  Future<void> savePage(PageModel page) async {
    await _pagesBox?.put(page.id, page);
    print('📄 Page ${page.id} cached to Hive');
  }

  /// Get a cached page
  PageModel? getPage(String pageId) {
    return _pagesBox?.get(pageId);
  }

  /// Get all cached pages
  List<PageModel> getAllPages() {
    return _pagesBox?.values.toList() ?? [];
  }

  /// Delete a cached page
  Future<void> deletePage(String pageId) async {
    await _pagesBox?.delete(pageId);
    print('📄 Page $pageId removed from cache');
  }

  /// Clear all cached pages
  Future<void> clearAllPages() async {
    await _pagesBox?.clear();
    print('📄 All pages cleared from cache');
  }

  /// Check if page is cached
  bool isPageCached(String pageId) {
    return _pagesBox?.containsKey(pageId) ?? false;
  }

  // ==================== DRAFTS BOX ====================

  /// Save a draft
  Future<void> saveDraft(String pageId, PageModel draft) async {
    await _draftsBox?.put(pageId, draft);
    print('💾 Draft for page $pageId saved');
  }

  /// Get a draft
  PageModel? getDraft(String pageId) {
    return _draftsBox?.get(pageId);
  }

  /// Delete a draft
  Future<void> deleteDraft(String pageId) async {
    await _draftsBox?.delete(pageId);
    print('💾 Draft for page $pageId deleted');
  }

  /// Get all drafts
  List<PageModel> getAllDrafts() {
    return _draftsBox?.values.toList() ?? [];
  }

  /// Check if draft exists
  bool hasDraft(String pageId) {
    return _draftsBox?.containsKey(pageId) ?? false;
  }

  // ==================== OPERATIONS QUEUE ====================

  /// Add operation to queue (for offline support). Returns the box key the
  /// operation was stored under, since that's what removeOperation() needs
  /// -- callers must not assume it matches any timestamp field of their own,
  /// as that can differ by the few milliseconds between the two calls.
  Future<int> queueOperation(Map<String, dynamic> operation) async {
    final key = DateTime.now().millisecondsSinceEpoch;
    await _operationsBox?.put(key, operation);
    print('⏳ Operation queued: ${operation['type']}');
    return key;
  }

  /// Get all queued operations
  List<Map<String, dynamic>> getQueuedOperations() {
    final operations = _operationsBox?.values.toList() ?? [];
    return operations.map((op) => Map<String, dynamic>.from(op)).toList();
  }

  /// Get all queued operations together with the box key each is stored
  /// under, in insertion order. Needed by callers that must remove a
  /// specific entry later via removeOperation(key).
  List<MapEntry<int, Map<String, dynamic>>> getQueuedOperationEntries() {
    final box = _operationsBox;
    if (box == null) return [];
    return box.keys
        .cast<int>()
        .map(
          (key) => MapEntry(key, Map<String, dynamic>.from(box.get(key)!)),
        )
        .toList();
  }

  /// Remove operation from queue
  Future<void> removeOperation(int timestamp) async {
    await _operationsBox?.delete(timestamp);
  }

  /// Clear all queued operations
  Future<void> clearOperationQueue() async {
    await _operationsBox?.clear();
    print('⏳ Operation queue cleared');
  }

  /// Get operation queue count
  int getOperationQueueCount() {
    return _operationsBox?.length ?? 0;
  }

  // ==================== SETTINGS BOX ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _settingsBox?.get(key, defaultValue: defaultValue);
    return value as T?;
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  /// Clear all settings
  Future<void> clearAllSettings() async {
    await _settingsBox?.clear();
  }

  // ==================== CANVAS PREFERENCES ====================

  /// Save canvas zoom level
  Future<void> saveCanvasZoom(double zoom) async {
    await saveSetting('canvas_zoom', zoom);
  }

  /// Get canvas zoom level
  double getCanvasZoom({double defaultZoom = 1.0}) {
    return getSetting('canvas_zoom', defaultValue: defaultZoom) ?? defaultZoom;
  }

  /// Save grid visibility
  Future<void> saveGridVisible(bool visible) async {
    await saveSetting('grid_visible', visible);
  }

  /// Get grid visibility
  bool getGridVisible({bool defaultValue = true}) {
    return getSetting('grid_visible', defaultValue: defaultValue) ?? defaultValue;
  }

  /// Save snap to grid setting
  Future<void> saveSnapToGrid(bool snap) async {
    await saveSetting('snap_to_grid', snap);
  }

  /// Get snap to grid setting
  bool getSnapToGrid({bool defaultValue = false}) {
    return getSetting('snap_to_grid', defaultValue: defaultValue) ?? defaultValue;
  }

  // ==================== STORAGE INFO ====================

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'pages': _pagesBox?.length ?? 0,
      'drafts': _draftsBox?.length ?? 0,
      'operations': _operationsBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
    };
  }

  /// Print storage statistics
  void printStorageStats() {
    final stats = getStorageStats();
    print('📊 Hive Storage Statistics:');
    print('   Pages cached: ${stats['pages']}');
    print('   Drafts saved: ${stats['drafts']}');
    print('   Operations queued: ${stats['operations']}');
    print('   Settings stored: ${stats['settings']}');
  }

  /// Clear all storage (for debugging or logout)
  Future<void> clearAllStorage() async {
    await clearAllPages();
    await _draftsBox?.clear();
    await _operationsBox?.clear();
    await _settingsBox?.clear();
    await clearAuthData();
    print('🗑️ All Hive storage cleared');
  }
}
