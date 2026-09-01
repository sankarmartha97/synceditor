import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/page_service.dart';
import '../../../core/services/patch_service.dart';
import '../../../core/api/page_websocket_client.dart';
import '../../../core/models/page.dart';
import '../../../core/models/position_mode.dart';
import '../../../core/utils/widget_tree_helper.dart';
import '../managers/cursor_manager.dart';
import '../widgets/remote_cursor.dart';
import '../widgets/active_users_list.dart' as aul;
import 'page_event.dart';
import 'page_state.dart';

class PageBloc extends Bloc<PageEvent, PageState> {
  final PageService _pageService;
  final PatchService _patchService = PatchService();
  final PageWebSocketClient _wsClient = PageWebSocketClient.instance;
  final CursorManager _cursorManager =
      CursorManager(); // Managed by BLoC, not state

  // Expose cursor manager for UI
  CursorManager get cursorManager => _cursorManager;

  StreamSubscription? _patchReceivedSubscription;
  StreamSubscription? _patchAppliedSubscription;
  StreamSubscription? _conflictSubscription;
  StreamSubscription? _pageJoinedSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _cursorUpdatedSubscription;
  StreamSubscription? _selectionUpdatedSubscription;
  StreamSubscription? _undoAppliedSubscription;
  StreamSubscription? _redoAppliedSubscription;
  StreamSubscription? _undoRedoStateSubscription;
  StreamSubscription? _undoErrorSubscription;
  StreamSubscription? _redoErrorSubscription;

  Timer? _cursorThrottleTimer;
  final Duration _cursorThrottleDuration = const Duration(milliseconds: 100);

  Timer? _syncTimeoutTimer;

  PageBloc(this._pageService) : super(PageState.initial()) {
    on<LoadPages>(_onLoadPages);
    on<LoadPage>(_onLoadPage);
    on<CreatePage>(_onCreatePage);
    on<UpdatePage>(_onUpdatePage);
    on<RenamePage>(_onRenamePage);
    on<DeletePage>(_onDeletePage);
    on<SharePage>(_onSharePage);
    on<LoadPagePermissions>(_onLoadPagePermissions);
    on<RevokePageAccess>(_onRevokePageAccess);
    on<AddWidgetToPage>(_onAddWidgetToPage);
    on<UpdateWidgetInPage>(_onUpdateWidgetInPage);
    on<RemoveWidgetFromPage>(_onRemoveWidgetFromPage);
    on<SelectPageWidget>(_onSelectPageWidget);
    on<ClearPageState>(_onClearPageState);

    // WebSocket event handlers
    on<ApplyIncomingPatch>(_onApplyIncomingPatch);
    on<ConfirmPatchApplied>(_onConfirmPatchApplied);
    on<HandlePatchConflict>(_onHandlePatchConflict);

    // Cursor & Presence handlers
    on<SendCursorPosition>(_onSendCursorPosition);
    on<UpdateRemoteCursor>(_onUpdateRemoteCursor);
    on<UpdateRemoteSelection>(_onUpdateRemoteSelection);
    on<UpdateActiveUsers>(_onUpdateActiveUsers);

    // Undo/Redo handlers
    on<UndoRequested>(_onUndoRequested);
    on<RedoRequested>(_onRedoRequested);
    on<UndoApplied>(_onUndoApplied);
    on<RedoApplied>(_onRedoApplied);
    on<UndoRedoStateUpdated>(_onUndoRedoStateUpdated);
    on<UndoFailed>(_onUndoFailed);
    on<RedoFailed>(_onRedoFailed);

    // ✨ NEW: Nested widget handlers
    on<MoveWidgetToParent>(_onMoveWidgetToParent);
    on<RemoveWidgetWithChildren>(_onRemoveWidgetWithChildren);

    // Initialize WebSocket
    _wsClient.connect();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen to incoming patches from other users
    _patchReceivedSubscription = _wsClient.patchReceivedEvents.listen((event) {
      add(ApplyIncomingPatch(event));
    });

    // Listen to patch confirmations
    _patchAppliedSubscription = _wsClient.patchAppliedEvents.listen((event) {
      add(ConfirmPatchApplied(event));
    });

    // Listen to conflicts
    _conflictSubscription = _wsClient.conflictEvents.listen((event) {
      add(HandlePatchConflict(event));
    });

    // Listen to page joined event to get initial active users list
    _pageJoinedSubscription = _wsClient.pageJoinedEvents.listen((event) {
      print('📄 Joined page: ${event.pageId}');
      print('👥 Active users received: ${event.activeUsers.length}');

      // Convert to List<Map<String, dynamic>> for UpdateActiveUsers
      final usersData = event.activeUsers
          .map((user) => {'userId': user.userId, 'name': user.name})
          .toList();

      add(UpdateActiveUsers(usersData));
    });

    // Listen to user presence
    _userJoinedSubscription = _wsClient.userJoinedEvents.listen((event) {
      print('👤 User joined: ${event.user?.name}');
      // The page:joined event will update the full active users list
    });

    _userLeftSubscription = _wsClient.userLeftEvents.listen((event) {
      final userId = event.userId;
      if (userId != null) {
        print('👤 User left: $userId');
        // Remove cursor when user leaves
        _cursorManager.removeCursor(userId);
      }
    });

    // Listen to cursor updates
    _cursorUpdatedSubscription = _wsClient.cursorEvents.listen((event) {
      add(UpdateRemoteCursor(event));
    });

    // Listen to selection updates
    _selectionUpdatedSubscription = _wsClient.selectionEvents.listen((event) {
      add(UpdateRemoteSelection(event));
    });

    // Listen to undo/redo events
    _undoAppliedSubscription = _wsClient.undoAppliedEvents.listen((event) {
      add(UndoApplied(event));
    });

    _redoAppliedSubscription = _wsClient.redoAppliedEvents.listen((event) {
      add(RedoApplied(event));
    });

    _undoRedoStateSubscription = _wsClient.undoRedoStateEvents.listen((event) {
      add(UndoRedoStateUpdated(canUndo: event.canUndo, canRedo: event.canRedo));
    });

    _undoErrorSubscription = _wsClient.undoErrorEvents.listen((message) {
      add(UndoFailed(message));
    });

    _redoErrorSubscription = _wsClient.redoErrorEvents.listen((message) {
      add(RedoFailed(message));
    });
  }

  // ==================== WEBSOCKET EVENT HANDLERS ====================

  void _onApplyIncomingPatch(
    ApplyIncomingPatch event,
    Emitter<PageState> emit,
  ) {
    final patchEvent = event.patchEvent as PagePatchReceivedEvent;

    if (state.currentPage == null ||
        state.currentPage!.id != patchEvent.pageId) {
      return;
    }

    print('🔄 Applying incoming patch from user ${patchEvent.userId}');

    // Apply patch to current page data
    final patchedData = _patchService.applyPatch(
      state.currentPage!.pageData,
      patchEvent.patches,
    );

    if (patchedData != null) {
      final updatedPage = PageModel(
        id: state.currentPage!.id,
        name: state.currentPage!.name,
        ownerId: state.currentPage!.ownerId,
        pageData: patchedData,
        version: patchEvent.version,
        createdAt: state.currentPage!.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: state.currentPage!.deletedAt,
      );

      emit(state.copyWith(currentPage: updatedPage, isSyncing: false));
    }
  }

  void _onConfirmPatchApplied(
    ConfirmPatchApplied event,
    Emitter<PageState> emit,
  ) {
    final patchEvent = event.patchEvent as PagePatchAppliedEvent;

    print('✅ Patch confirmed: version ${patchEvent.version}');

    if (state.currentPage != null &&
        state.currentPage!.id == patchEvent.pageId) {
      final updatedPage = PageModel(
        id: state.currentPage!.id,
        name: state.currentPage!.name,
        ownerId: state.currentPage!.ownerId,
        pageData: state.currentPage!.pageData,
        version: patchEvent.version,
        createdAt: state.currentPage!.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: state.currentPage!.deletedAt,
      );

      emit(state.copyWith(currentPage: updatedPage, isSyncing: false));
    }
  }

  void _onHandlePatchConflict(
    HandlePatchConflict event,
    Emitter<PageState> emit,
  ) {
    print('🔀 Server resolving conflict with Operational Transformation...');
    // Server will auto-resolve with OT
    // Just wait for transformed patch confirmation
    // No user action needed!
    emit(
      state.copyWith(
        isSyncing: true, // Keep syncing indicator
      ),
    );
  }

  // ==================== CURSOR & PRESENCE HANDLERS ====================

  void _onSendCursorPosition(
    SendCursorPosition event,
    Emitter<PageState> emit,
  ) {
    // Throttle cursor updates to avoid flooding the server
    if (_cursorThrottleTimer?.isActive ?? false) {
      return;
    }

    _cursorThrottleTimer = Timer(_cursorThrottleDuration, () {
      _wsClient.sendCursorPosition(
        pageId: event.pageId,
        position: Offset(event.x, event.y),
      );
    });
  }

  void _onUpdateRemoteCursor(
    UpdateRemoteCursor event,
    Emitter<PageState> emit,
  ) {
    try {
      final cursorEvent = event.cursorEvent as PageCursorEvent;

      // Parse color from hex string
      Color userColor = Colors.blue; // Default fallback
      if (cursorEvent.userColor != null) {
        try {
          final colorString = cursorEvent.userColor!.replaceAll('#', '');
          userColor = Color(int.parse('FF$colorString', radix: 16));
        } catch (e) {
          print('⚠️ Failed to parse color: ${cursorEvent.userColor}');
        }
      }

      // Ensure position is a proper Offset (not a JS object)
      final position = cursorEvent.position is Offset
          ? cursorEvent.position
          : Offset(
              (cursorEvent.position as dynamic).dx?.toDouble() ?? 0.0,
              (cursorEvent.position as dynamic).dy?.toDouble() ?? 0.0,
            );

      // Ensure timestamp is a proper DateTime (not a JS object)
      final timestamp = cursorEvent.timestamp is DateTime
          ? cursorEvent.timestamp
          : DateTime.now();

      // Parse cursor data with actual userName and userColor from backend
      final cursorData = RemoteCursorData(
        userId: cursorEvent.userId,
        userName: cursorEvent.userName ?? 'Unknown User',
        userColor: userColor,
        position: position,
        timestamp: timestamp,
      );

      // Update cursor in BLoC-managed cursor manager
      _cursorManager.updateCursor(cursorData);
    } catch (e, stack) {
      print('❌ Error updating remote cursor: $e');
      print(stack);
    }

    // No need to emit state - cursor manager has its own stream
  }

  void _onUpdateRemoteSelection(
    UpdateRemoteSelection event,
    Emitter<PageState> emit,
  ) {
    try {
      final selectionEvent = event.selectionEvent as PageSelectionEvent;

      // Update other users' selections map
      final updatedSelections = Map<String, String?>.from(
        state.otherUsersSelections,
      );

      // Update users names map
      final updatedUserNames = Map<String, String>.from(state.otherUsersNames);

      if (selectionEvent.widgetId == null) {
        // Remove selection if widgetId is null
        updatedSelections.remove(selectionEvent.userId);
        updatedUserNames.remove(selectionEvent.userId);
      } else {
        // Update selection and store userName
        updatedSelections[selectionEvent.userId] = selectionEvent.widgetId;
        updatedUserNames[selectionEvent.userId] =
            selectionEvent.userName ?? 'Unknown User';
      }

      emit(
        state.copyWith(
          otherUsersSelections: updatedSelections,
          otherUsersNames: updatedUserNames,
        ),
      );

      print(
        '✨ Updated selection for user ${selectionEvent.userId} (${selectionEvent.userName}): ${selectionEvent.widgetId}',
      );
    } catch (e, stack) {
      print('❌ Error updating remote selection: $e');
      print(stack);
    }
  }

  void _onUpdateActiveUsers(UpdateActiveUsers event, Emitter<PageState> emit) {
    final activeUsers = event.users
        .map((user) => aul.ActiveUser.fromJson(user as Map<String, dynamic>))
        .toList();

    emit(state.copyWith(activeUsers: activeUsers));
  }

  // ==================== UNDO/REDO HANDLERS ====================

  void _onUndoRequested(UndoRequested event, Emitter<PageState> emit) {
    if (state.currentPage == null) return;
    if (!state.canUndo) {
      print('⚠️ Cannot undo: nothing to undo');
      return;
    }

    print('↩️ Requesting undo for page ${event.pageId}');
    emit(state.copyWith(isUndoing: true));
    _wsClient.sendUndo(pageId: event.pageId);
  }

  void _onRedoRequested(RedoRequested event, Emitter<PageState> emit) {
    if (state.currentPage == null) return;
    if (!state.canRedo) {
      print('⚠️ Cannot redo: nothing to redo');
      return;
    }

    print('↪️ Requesting redo for page ${event.pageId}');
    emit(state.copyWith(isRedoing: true));
    _wsClient.sendRedo(pageId: event.pageId);
  }

  void _onUndoApplied(UndoApplied event, Emitter<PageState> emit) {
    final undoEvent = event.undoEvent as PageUndoAppliedEvent;

    if (state.currentPage == null ||
        state.currentPage!.id != undoEvent.pageId) {
      return;
    }

    print(
      '✅ Undo applied: ${undoEvent.operationDescription ?? "operation"} (v${undoEvent.version})',
    );

    // Apply patches to current page data
    final patchedData = _patchService.applyPatch(
      state.currentPage!.pageData,
      undoEvent.patches,
    );

    if (patchedData != null) {
      final updatedPage = PageModel(
        id: state.currentPage!.id,
        name: state.currentPage!.name,
        ownerId: state.currentPage!.ownerId,
        pageData: patchedData,
        version: undoEvent.version,
        createdAt: state.currentPage!.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: state.currentPage!.deletedAt,
      );

      emit(
        state.copyWith(
          currentPage: updatedPage,
          canUndo: undoEvent.canUndo,
          canRedo: undoEvent.canRedo,
          isUndoing: false,
        ),
      );
    } else {
      emit(state.copyWith(isUndoing: false));
    }
  }

  void _onRedoApplied(RedoApplied event, Emitter<PageState> emit) {
    final redoEvent = event.redoEvent as PageRedoAppliedEvent;

    if (state.currentPage == null ||
        state.currentPage!.id != redoEvent.pageId) {
      return;
    }

    print(
      '✅ Redo applied: ${redoEvent.operationDescription ?? "operation"} (v${redoEvent.version})',
    );

    // Apply patches to current page data
    final patchedData = _patchService.applyPatch(
      state.currentPage!.pageData,
      redoEvent.patches,
    );

    if (patchedData != null) {
      final updatedPage = PageModel(
        id: state.currentPage!.id,
        name: state.currentPage!.name,
        ownerId: state.currentPage!.ownerId,
        pageData: patchedData,
        version: redoEvent.version,
        createdAt: state.currentPage!.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: state.currentPage!.deletedAt,
      );

      emit(
        state.copyWith(
          currentPage: updatedPage,
          canUndo: redoEvent.canUndo,
          canRedo: redoEvent.canRedo,
          isRedoing: false,
        ),
      );
    } else {
      emit(state.copyWith(isRedoing: false));
    }
  }

  void _onUndoRedoStateUpdated(
    UndoRedoStateUpdated event,
    Emitter<PageState> emit,
  ) {
    print(
      '🔄 Undo/Redo state updated: canUndo=${event.canUndo}, canRedo=${event.canRedo}',
    );
    emit(state.copyWith(canUndo: event.canUndo, canRedo: event.canRedo));
  }

  void _onUndoFailed(UndoFailed event, Emitter<PageState> emit) {
    print('❌ Undo failed: ${event.message}');
    emit(
      state.copyWith(isUndoing: false, error: 'Undo failed: ${event.message}'),
    );
  }

  void _onRedoFailed(RedoFailed event, Emitter<PageState> emit) {
    print('❌ Redo failed: ${event.message}');
    emit(
      state.copyWith(isRedoing: false, error: 'Redo failed: ${event.message}'),
    );
  }

  @override
  Future<void> close() {
    _patchReceivedSubscription?.cancel();
    _patchAppliedSubscription?.cancel();
    _conflictSubscription?.cancel();
    _pageJoinedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _cursorUpdatedSubscription?.cancel();
    _selectionUpdatedSubscription?.cancel();
    _cursorThrottleTimer?.cancel();
    _syncTimeoutTimer?.cancel();
    _undoAppliedSubscription?.cancel();
    _redoAppliedSubscription?.cancel();
    _undoRedoStateSubscription?.cancel();
    _undoErrorSubscription?.cancel();
    _redoErrorSubscription?.cancel();
    _cursorManager.dispose();
    return super.close();
  }

  // Helper to send patch and auto-clear syncing state
  void _sendPatchAndClearSync(
    String pageId,
    List<Map<String, dynamic>> patches,
    int clientVersion,
  ) {
    _wsClient.sendPatch(
      pageId: pageId,
      patches: patches,
      clientVersion: clientVersion,
    );

    // Backend doesn't send patch:applied confirmation yet
    // Clear syncing after delay as workaround
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(milliseconds: 800), () {
      if (!isClosed && state.isSyncing) {
        emit(state.copyWith(isSyncing: false));
      }
    });
  }

  Future<void> _onLoadPages(LoadPages event, Emitter<PageState> emit) async {
    emit(state.copyWith(pagesLoading: true, clearError: true));

    try {
      final pages = await _pageService.getUserPages();
      emit(state.copyWith(pages: pages, pagesLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          pagesLoading: false,
          error: 'Failed to load pages: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadPage(LoadPage event, Emitter<PageState> emit) async {
    emit(
      state.copyWith(
        currentPageLoading: true,
        currentPageId: event.pageId,
        clearError: true,
      ),
    );

    try {
      // Load page via HTTP first
      final page = await _pageService.getPageById(event.pageId);

      // Clear existing cursors for new page
      _cursorManager.clearAll();

      emit(
        state.copyWith(
          currentPage: page,
          currentPageLoading: false,
          currentPageId: page.id,
        ),
      );

      // Join page via WebSocket for real-time updates
      _wsClient.joinPage(page.id);
    } catch (e) {
      emit(
        state.copyWith(
          currentPageLoading: false,
          error: 'Failed to load page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreatePage(CreatePage event, Emitter<PageState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final newPage = await _pageService.createPage(
        name: event.name,
        metadata: event.metadata,
      );

      // ✨ V2.1: Add default container to new pages
      final defaultContainer = PageWidget(
        id: const Uuid().v4(),
        type: 'Container',
        position: const Offset(50, 50),
        size: const Size(400, 150),
        properties: {'color': '#2196F3', 'borderRadius': 8.0, 'opacity': 1.0},
        isContainer: true,
        zIndex: 0,
        isDefaultContainer: true, // ✨ NEW: Mark as non-deletable
      );

      // Add the default container to the page
      final updatedPageData = newPage.pageData.copyWith(
        widgets: [defaultContainer],
        version: newPage.version + 1,
      );

      final pageWithContainer = PageModel(
        id: newPage.id,
        name: newPage.name,
        ownerId: newPage.ownerId,
        pageData: updatedPageData,
        version: newPage.version + 1,
        createdAt: newPage.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: newPage.deletedAt,
      );

      // Save the container to backend
      await _pageService.updatePage(newPage.id, pageData: updatedPageData);

      // Reload pages list
      final pages = await _pageService.getUserPages();

      emit(
        state.copyWith(
          pages: pages,
          currentPage: pageWithContainer,
          currentPageId: newPage.id,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to create page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUpdatePage(UpdatePage event, Emitter<PageState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final updatedPage = await _pageService.updatePage(
        event.pageId,
        pageData: event.pageData,
      );

      emit(state.copyWith(currentPage: updatedPage, isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: 'Failed to update page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRenamePage(RenamePage event, Emitter<PageState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final updatedPage = await _pageService.renamePage(
        event.pageId,
        event.newName,
      );

      // Update in pages list
      final updatedPages = state.pages.map((page) {
        if (page.id == event.pageId) {
          return PageListItem(
            id: page.id,
            name: event.newName,
            ownerId: page.ownerId,
            version: page.version,
            permission: page.permission,
            updatedAt: DateTime.now(),
            createdAt: page.createdAt,
          );
        }
        return page;
      }).toList();

      emit(
        state.copyWith(
          pages: updatedPages,
          currentPage: state.currentPage?.id == event.pageId
              ? updatedPage
              : state.currentPage,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to rename page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeletePage(DeletePage event, Emitter<PageState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _pageService.deletePage(event.pageId);

      // Remove from pages list
      final updatedPages = state.pages
          .where((page) => page.id != event.pageId)
          .toList();

      emit(
        state.copyWith(
          pages: updatedPages,
          isLoading: false,
          clearCurrentPage: state.currentPageId == event.pageId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to delete page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSharePage(SharePage event, Emitter<PageState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _pageService.sharePage(
        pageId: event.pageId,
        email: event.email,
        permissionType: event.permissionType,
      );

      // Reload permissions
      final permissions = await _pageService.getPagePermissions(event.pageId);

      emit(state.copyWith(permissions: permissions, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to share page: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadPagePermissions(
    LoadPagePermissions event,
    Emitter<PageState> emit,
  ) async {
    emit(state.copyWith(permissionsLoading: true, clearError: true));

    try {
      final permissions = await _pageService.getPagePermissions(event.pageId);

      emit(state.copyWith(permissions: permissions, permissionsLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          permissionsLoading: false,
          error: 'Failed to load permissions: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRevokePageAccess(
    RevokePageAccess event,
    Emitter<PageState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _pageService.revokeAccess(
        pageId: event.pageId,
        userId: event.userId,
      );

      // Remove from permissions list
      final updatedPermissions = state.permissions
          .where((perm) => perm.userId != event.userId)
          .toList();

      emit(state.copyWith(permissions: updatedPermissions, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to revoke access: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onAddWidgetToPage(
    AddWidgetToPage event,
    Emitter<PageState> emit,
  ) async {
    if (state.currentPage == null) return;

    // Store old data for patch generation and current version BEFORE incrementing
    final oldData = state.currentPage!.pageData;
    final currentVersion = state.currentPage!.version;

    // Add widget locally first (optimistic update)
    final updatedWidgets = [
      ...state.currentPage!.pageData.widgets,
      event.widget,
    ];

    final updatedPageData = state.currentPage!.pageData.copyWith(
      widgets: updatedWidgets,
      version: currentVersion + 1,
    );

    final updatedPage = PageModel(
      id: state.currentPage!.id,
      name: state.currentPage!.name,
      ownerId: state.currentPage!.ownerId,
      pageData: updatedPageData,
      version: currentVersion + 1,
      createdAt: state.currentPage!.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: state.currentPage!.deletedAt,
    );

    emit(state.copyWith(currentPage: updatedPage, isSyncing: true));

    // Generate patch
    final patches = _patchService.generatePatch(oldData, updatedPageData);

    // Send patch via WebSocket with the ORIGINAL version (before increment)
    _sendPatchAndClearSync(
      state.currentPage!.id,
      patches,
      currentVersion, // Use the version BEFORE incrementing
    );
  }

  Future<void> _onUpdateWidgetInPage(
    UpdateWidgetInPage event,
    Emitter<PageState> emit,
  ) async {
    if (state.currentPage == null) return;

    // Store old data for patch generation and current version BEFORE incrementing
    final oldData = state.currentPage!.pageData;
    final currentVersion = state.currentPage!.version;

    // Update widget locally first (optimistic update)
    final updatedWidgets = state.currentPage!.pageData.widgets.map((widget) {
      return widget.id == event.widgetId ? event.updatedWidget : widget;
    }).toList();

    final updatedPageData = state.currentPage!.pageData.copyWith(
      widgets: updatedWidgets,
      version: currentVersion + 1,
    );

    final updatedPage = PageModel(
      id: state.currentPage!.id,
      name: state.currentPage!.name,
      ownerId: state.currentPage!.ownerId,
      pageData: updatedPageData,
      version: currentVersion + 1,
      createdAt: state.currentPage!.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: state.currentPage!.deletedAt,
    );

    emit(state.copyWith(currentPage: updatedPage, isSyncing: true));

    // Generate patch
    final patches = _patchService.generatePatch(oldData, updatedPageData);

    // Send patch via WebSocket with the ORIGINAL version (before increment)
    _sendPatchAndClearSync(
      state.currentPage!.id,
      patches,
      currentVersion, // Use the version BEFORE incrementing
    );
  }

  Future<void> _onRemoveWidgetFromPage(
    RemoveWidgetFromPage event,
    Emitter<PageState> emit,
  ) async {
    if (state.currentPage == null) return;

    // ✨ NEW: Prevent deletion of default container
    final widgetToDelete = state.currentPage!.pageData.widgets.firstWhere(
      (w) => w.id == event.widgetId,
      orElse: () => PageWidget(
        id: '',
        type: '',
        position: Offset.zero,
        size: Size.zero,
        properties: {},
      ),
    );

    if (widgetToDelete.isDefaultContainer) {
      print('⚠️ Cannot delete the default container');
      emit(state.copyWith(error: 'Cannot delete the default container'));
      return;
    }

    // Store old data for patch generation and current version BEFORE incrementing
    final oldData = state.currentPage!.pageData;
    final currentVersion = state.currentPage!.version;

    // Remove widget locally first (optimistic update)
    final updatedWidgets = state.currentPage!.pageData.widgets
        .where((widget) => widget.id != event.widgetId)
        .toList();

    final updatedPageData = state.currentPage!.pageData.copyWith(
      widgets: updatedWidgets,
      version: currentVersion + 1,
    );

    final updatedPage = PageModel(
      id: state.currentPage!.id,
      name: state.currentPage!.name,
      ownerId: state.currentPage!.ownerId,
      pageData: updatedPageData,
      version: currentVersion + 1,
      createdAt: state.currentPage!.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: state.currentPage!.deletedAt,
    );

    emit(
      state.copyWith(
        currentPage: updatedPage,
        isSyncing: true,
        clearSelection: state.selectedWidgetId == event.widgetId,
      ),
    );

    // Generate patch
    final patches = _patchService.generatePatch(oldData, updatedPageData);

    // Send patch via WebSocket with the ORIGINAL version (before increment)
    _sendPatchAndClearSync(
      state.currentPage!.id,
      patches,
      currentVersion, // Use the version BEFORE incrementing
    );
  }

  Future<void> _onSelectPageWidget(
    SelectPageWidget event,
    Emitter<PageState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedWidgetId: event.widgetId,
        clearSelection: event.widgetId == null,
      ),
    );

    // ✨ Sync selection to other users
    if (state.currentPageId != null) {
      _wsClient.sendSelection(
        pageId: state.currentPageId!,
        widgetId: event.widgetId,
      );
    }
  }

  Future<void> _onClearPageState(
    ClearPageState event,
    Emitter<PageState> emit,
  ) async {
    emit(PageState.initial());
  }

  // ==================== NESTED WIDGET HANDLERS ====================

  Future<void> _onMoveWidgetToParent(
    MoveWidgetToParent event,
    Emitter<PageState> emit,
  ) async {
    if (state.currentPage == null) return;

    final allWidgets = state.currentPage!.pageData.widgets;
    final widgetIndex = allWidgets.indexWhere((w) => w.id == event.widgetId);
    if (widgetIndex == -1) return;

    final widget = allWidgets[widgetIndex];
    final oldParentId = widget.parentId;

    // Calculate new position (relative to new parent or absolute)
    Offset newPosition = event.newPosition ?? widget.position;
    if (event.newParentId != null) {
      // Calculate relative position to new parent
      final absolutePos = WidgetTreeHelper.calculateAbsolutePosition(
        widget,
        allWidgets,
      );
      final newParent = allWidgets.firstWhere((w) => w.id == event.newParentId);
      newPosition = WidgetTreeHelper.calculateRelativePosition(
        absolutePos,
        newParent,
        allWidgets,
      );
    }

    // Update widget
    final updatedWidget = widget.copyWith(
      parentId: event.newParentId,
      position: newPosition,
      positionMode: event.newParentId != null
          ? PositionMode.relative
          : PositionMode.absolute,
    );

    // Remove from old parent's children list
    List<PageWidget> updatedWidgets = [...allWidgets];
    if (oldParentId != null) {
      final oldParentIndex = updatedWidgets.indexWhere(
        (w) => w.id == oldParentId,
      );
      if (oldParentIndex != -1) {
        final oldParent = updatedWidgets[oldParentIndex];
        final updatedOldParent = oldParent.copyWith(
          childrenIds: oldParent.childrenIds
              .where((id) => id != widget.id)
              .toList(),
        );
        updatedWidgets[oldParentIndex] = updatedOldParent;
      }
    }

    // Add to new parent's children list
    if (event.newParentId != null) {
      final newParentIndex = updatedWidgets.indexWhere(
        (w) => w.id == event.newParentId,
      );
      if (newParentIndex != -1) {
        final newParent = updatedWidgets[newParentIndex];
        final updatedNewParent = newParent.copyWith(
          childrenIds: [...newParent.childrenIds, widget.id],
        );
        updatedWidgets[newParentIndex] = updatedNewParent;
      }
    }

    // Update the moved widget
    updatedWidgets[widgetIndex] = updatedWidget;

    // Create updated page data
    final oldData = state.currentPage!.pageData;
    final currentVersion = state.currentPage!.version;

    final updatedPageData = oldData.copyWith(
      widgets: updatedWidgets,
      version: currentVersion + 1,
    );

    final updatedPage = PageModel(
      id: state.currentPage!.id,
      name: state.currentPage!.name,
      ownerId: state.currentPage!.ownerId,
      pageData: updatedPageData,
      version: currentVersion + 1,
      createdAt: state.currentPage!.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: state.currentPage!.deletedAt,
    );

    emit(state.copyWith(currentPage: updatedPage, isSyncing: true));

    // Generate and send patch
    final patches = _patchService.generatePatch(oldData, updatedPageData);
    _sendPatchAndClearSync(state.currentPage!.id, patches, currentVersion);
  }

  Future<void> _onRemoveWidgetWithChildren(
    RemoveWidgetWithChildren event,
    Emitter<PageState> emit,
  ) async {
    if (state.currentPage == null) return;

    final allWidgets = state.currentPage!.pageData.widgets;

    try {
      final widget = allWidgets.firstWhere((w) => w.id == event.widgetId);

      // ✨ NEW: Prevent deletion of default container
      if (widget.isDefaultContainer) {
        print('⚠️ Cannot delete the default container');
        emit(state.copyWith(error: 'Cannot delete the default container'));
        return;
      }

      // Get descendants if cascade delete
      List<PageWidget> widgetsToRemove = [widget];
      if (event.cascade) {
        final descendants = WidgetTreeHelper.getDescendants(
          event.widgetId,
          allWidgets,
        );
        widgetsToRemove = [widget, ...descendants];
      }

      final idsToRemove = widgetsToRemove.map((w) => w.id).toSet();

      // Remove from parent's children list
      List<PageWidget> updatedWidgets = [...allWidgets];
      if (widget.parentId != null) {
        final parentIndex = updatedWidgets.indexWhere(
          (w) => w.id == widget.parentId,
        );
        if (parentIndex != -1) {
          final parent = updatedWidgets[parentIndex];
          final updatedParent = parent.copyWith(
            childrenIds: parent.childrenIds
                .where((id) => id != widget.id)
                .toList(),
          );
          updatedWidgets[parentIndex] = updatedParent;
        }
      }

      // Remove widget and descendants
      updatedWidgets = updatedWidgets
          .where((w) => !idsToRemove.contains(w.id))
          .toList();

      // Create updated page data
      final oldData = state.currentPage!.pageData;
      final currentVersion = state.currentPage!.version;

      final updatedPageData = oldData.copyWith(
        widgets: updatedWidgets,
        version: currentVersion + 1,
      );

      final updatedPage = PageModel(
        id: state.currentPage!.id,
        name: state.currentPage!.name,
        ownerId: state.currentPage!.ownerId,
        pageData: updatedPageData,
        version: currentVersion + 1,
        createdAt: state.currentPage!.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: state.currentPage!.deletedAt,
      );

      emit(
        state.copyWith(
          currentPage: updatedPage,
          isSyncing: true,
          clearSelection: state.selectedWidgetId == event.widgetId,
        ),
      );

      // Generate and send patch
      final patches = _patchService.generatePatch(oldData, updatedPageData);
      _sendPatchAndClearSync(state.currentPage!.id, patches, currentVersion);
    } catch (e) {
      print('❌ Error removing widget: $e');
    }
  }
}
