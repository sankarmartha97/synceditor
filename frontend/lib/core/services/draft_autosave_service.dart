import 'dart:async';
import '../models/page.dart';
import '../storage/storage_service.dart';

/// Service for auto-saving page drafts
/// Automatically saves page state at regular intervals
class DraftAutoSaveService {
  final StorageService _storage = StorageService.instance;

  static DraftAutoSaveService? _instance;
  
  Timer? _autoSaveTimer;
  Map<String, PageModel> _pendingDrafts = {};
  Map<String, DateTime> _lastSaveTime = {};
  
  // Auto-save interval (default: 5 seconds)
  Duration autoSaveInterval = const Duration(seconds: 5);
  
  // Minimum time between saves (debouncing)
  Duration minSaveInterval = const Duration(seconds: 2);

  DraftAutoSaveService._internal();

  static DraftAutoSaveService get instance {
    _instance ??= DraftAutoSaveService._internal();
    return _instance!;
  }

  /// Start auto-save for a page
  /// Call this when user starts editing a page
  void startAutoSave(String pageId, {Duration? interval}) {
    if (interval != null) {
      autoSaveInterval = interval;
    }

    // Stop existing timer if any
    _autoSaveTimer?.cancel();

    // Start periodic auto-save
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (timer) {
      _processPendingDrafts();
    });

    print('💾 Auto-save started for page $pageId (interval: ${autoSaveInterval.inSeconds}s)');
  }

  /// Stop auto-save
  /// Call this when user leaves the page or closes the editor
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    
    // Save any pending drafts before stopping
    _processPendingDrafts();
    
    print('💾 Auto-save stopped');
  }

  /// Mark a page as modified (queue for auto-save)
  void markModified(String pageId, PageModel page) {
    _pendingDrafts[pageId] = page;
  }

  /// Process all pending drafts
  void _processPendingDrafts() async {
    if (_pendingDrafts.isEmpty) {
      return;
    }

    final draftsToSave = Map<String, PageModel>.from(_pendingDrafts);
    _pendingDrafts.clear();

    for (final entry in draftsToSave.entries) {
      final pageId = entry.key;
      final page = entry.value;
      
      // Check if enough time has passed since last save (debouncing)
      final lastSave = _lastSaveTime[pageId];
      if (lastSave != null) {
        final elapsed = DateTime.now().difference(lastSave);
        if (elapsed < minSaveInterval) {
          // Re-queue for next cycle
          _pendingDrafts[pageId] = page;
          continue;
        }
      }

      // Save the draft
      await _saveDraftInternal(pageId, page);
      _lastSaveTime[pageId] = DateTime.now();
    }
  }

  /// Save a draft immediately (bypass auto-save queue)
  Future<void> saveDraft(String pageId, PageModel page) async {
    await _saveDraftInternal(pageId, page);
    _lastSaveTime[pageId] = DateTime.now();
  }

  /// Internal save method
  Future<void> _saveDraftInternal(String pageId, PageModel page) async {
    try {
      await _storage.saveDraft(pageId, page);
      print('💾 Draft saved for page $pageId (${page.pageData.widgets.length} widgets)');
    } catch (e) {
      print('⚠️ Failed to save draft for page $pageId: $e');
    }
  }

  /// Load a draft
  PageModel? loadDraft(String pageId) {
    final draft = _storage.getDraft(pageId);
    if (draft != null) {
      print('📂 Loaded draft for page $pageId');
    }
    return draft;
  }

  /// Check if a draft exists
  bool hasDraft(String pageId) {
    return _storage.hasDraft(pageId);
  }

  /// Delete a draft (after successful save to server)
  Future<void> deleteDraft(String pageId) async {
    await _storage.deleteDraft(pageId);
    _lastSaveTime.remove(pageId);
    _pendingDrafts.remove(pageId);
    print('🗑️ Deleted draft for page $pageId');
  }

  /// Get all drafts
  List<PageModel> getAllDrafts() {
    return _storage.getAllDrafts();
  }

  /// Get draft info (for display)
  Map<String, dynamic>? getDraftInfo(String pageId) {
    final draft = _storage.getDraft(pageId);
    if (draft == null) return null;

    return {
      'pageId': pageId,
      'pageName': draft.name,
      'widgetCount': draft.pageData.widgets.length,
      'version': draft.version,
      'lastModified': draft.updatedAt,
    };
  }

  /// Restore draft to continue editing
  /// Returns the draft and shows recovery UI
  Future<PageModel?> recoverDraft(String pageId) async {
    final draft = loadDraft(pageId);
    if (draft != null) {
      print('🔄 Recovered draft for page $pageId');
    }
    return draft;
  }

  /// Compare draft with server version
  /// Returns true if draft is newer
  bool isDraftNewer(PageModel draft, PageModel serverPage) {
    return draft.updatedAt.isAfter(serverPage.updatedAt);
  }

  /// Get all pages with drafts (for recovery UI)
  List<Map<String, dynamic>> getPagesWithDrafts() {
    final drafts = getAllDrafts();
    return drafts.map((draft) => {
      'pageId': draft.id,
      'pageName': draft.name,
      'widgetCount': draft.pageData.widgets.length,
      'lastModified': draft.updatedAt,
    }).toList();
  }

  /// Clear all drafts (for cleanup)
  Future<void> clearAllDrafts() async {
    final drafts = getAllDrafts();
    for (final draft in drafts) {
      await _storage.deleteDraft(draft.id);
    }
    _pendingDrafts.clear();
    _lastSaveTime.clear();
    print('🗑️ Cleared all drafts');
  }

  /// Print draft statistics
  void printDraftStats() {
    final drafts = getAllDrafts();
    
    if (drafts.isEmpty) {
      print('📊 Drafts: None');
      return;
    }

    print('📊 Draft Statistics:');
    print('   Total drafts: ${drafts.length}');
    print('   Pending saves: ${_pendingDrafts.length}');
    
    for (final draft in drafts) {
      final lastSave = _lastSaveTime[draft.id];
      final elapsed = lastSave != null 
        ? DateTime.now().difference(lastSave).inSeconds 
        : null;
      
      print('   ${draft.name}:');
      print('     Widgets: ${draft.pageData.widgets.length}');
      print('     Last modified: ${draft.updatedAt}');
      if (elapsed != null) {
        print('     Last saved: ${elapsed}s ago');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSave();
  }
}
