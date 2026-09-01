import 'package:equatable/equatable.dart';
import '../../../core/models/page.dart';
import '../managers/cursor_manager.dart';
import '../widgets/active_users_list.dart' as aul;

class PageState extends Equatable {
  // Page list (for dashboard)
  final List<PageListItem> pages;
  final bool pagesLoading;

  // Current page (for editor)
  final PageModel? currentPage;
  final bool currentPageLoading;
  final String? currentPageId;

  // Selected widget
  final String? selectedWidgetId;

  // Other users' selections (Map of userId -> widgetId)
  final Map<String, String?> otherUsersSelections;

  // Permissions
  final List<PagePermission> permissions;
  final bool permissionsLoading;

  // Error handling
  final String? error;

  // Loading states
  final bool isLoading;
  final bool isSaving;
  final bool isSyncing;

  // Presence & Cursors
  final List<aul.ActiveUser> activeUsers;

  // Undo/Redo state
  final bool canUndo;
  final bool canRedo;
  final bool isUndoing;
  final bool isRedoing;

  const PageState({
    this.pages = const [],
    this.pagesLoading = false,
    this.currentPage,
    this.currentPageLoading = false,
    this.currentPageId,
    this.selectedWidgetId,
    this.otherUsersSelections = const {},
    this.permissions = const [],
    this.permissionsLoading = false,
    this.error,
    this.isLoading = false,
    this.isSaving = false,
    this.isSyncing = false,
    this.activeUsers = const [],
    this.canUndo = false,
    this.canRedo = false,
    this.isUndoing = false,
    this.isRedoing = false,
  });

  // Initial state
  factory PageState.initial() {
    return const PageState();
  }

  // Getters
  bool get hasCurrentPage => currentPage != null;
  bool get hasError => error != null;
  bool get hasPages => pages.isNotEmpty;

  PageWidget? get selectedWidget {
    if (selectedWidgetId == null || currentPage == null) return null;
    try {
      return currentPage!.pageData.widgets.firstWhere(
        (w) => w.id == selectedWidgetId,
      );
    } catch (e) {
      return null;
    }
  }

  PermissionType? get currentPagePermission {
    if (currentPageId == null) return null;
    try {
      final page = pages.firstWhere((p) => p.id == currentPageId);
      return page.permission;
    } catch (e) {
      return null;
    }
  }

  bool get canEdit {
    final permission = currentPagePermission;
    return permission == PermissionType.owner ||
        permission == PermissionType.edit;
  }

  bool get isOwner {
    return currentPagePermission == PermissionType.owner;
  }

  // Copy with
  PageState copyWith({
    List<PageListItem>? pages,
    bool? pagesLoading,
    PageModel? currentPage,
    bool? currentPageLoading,
    String? currentPageId,
    String? selectedWidgetId,
    Map<String, String?>? otherUsersSelections,
    List<PagePermission>? permissions,
    bool? permissionsLoading,
    String? error,
    bool? isLoading,
    bool? isSaving,
    bool? isSyncing,
    List<aul.ActiveUser>? activeUsers,
    bool? canUndo,
    bool? canRedo,
    bool? isUndoing,
    bool? isRedoing,
    bool clearError = false,
    bool clearSelection = false,
    bool clearCurrentPage = false,
  }) {
    return PageState(
      pages: pages ?? this.pages,
      pagesLoading: pagesLoading ?? this.pagesLoading,
      currentPage: clearCurrentPage ? null : (currentPage ?? this.currentPage),
      currentPageLoading: currentPageLoading ?? this.currentPageLoading,
      currentPageId: currentPageId ?? this.currentPageId,
      selectedWidgetId: clearSelection
          ? null
          : (selectedWidgetId ?? this.selectedWidgetId),
      otherUsersSelections: otherUsersSelections ?? this.otherUsersSelections,
      permissions: permissions ?? this.permissions,
      permissionsLoading: permissionsLoading ?? this.permissionsLoading,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSyncing: isSyncing ?? this.isSyncing,
      activeUsers: activeUsers ?? this.activeUsers,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isUndoing: isUndoing ?? this.isUndoing,
      isRedoing: isRedoing ?? this.isRedoing,
    );
  }

  @override
  List<Object?> get props => [
    pages,
    pagesLoading,
    currentPage,
    currentPageLoading,
    currentPageId,
    selectedWidgetId,
    otherUsersSelections,
    permissions,
    permissionsLoading,
    error,
    isLoading,
    isSaving,
    isSyncing,
    activeUsers,
    canUndo,
    canRedo,
    isUndoing,
    isRedoing,
  ];
}
