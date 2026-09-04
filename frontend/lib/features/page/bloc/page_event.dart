import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/models/page.dart';

abstract class PageEvent extends Equatable {
  const PageEvent();

  @override
  List<Object?> get props => [];
}

/// Load all pages for dashboard
class LoadPages extends PageEvent {
  const LoadPages();
}

/// Load specific page for editing
class LoadPage extends PageEvent {
  final String pageId;

  const LoadPage(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Create new page
class CreatePage extends PageEvent {
  final String name;
  final PageMetadata? metadata;

  const CreatePage({required this.name, this.metadata});

  @override
  List<Object?> get props => [name, metadata];
}

/// Update page (sync to backend)
class UpdatePage extends PageEvent {
  final String pageId;
  final PageData pageData;

  const UpdatePage({required this.pageId, required this.pageData});

  @override
  List<Object?> get props => [pageId, pageData];
}

/// Rename page
class RenamePage extends PageEvent {
  final String pageId;
  final String newName;

  const RenamePage({required this.pageId, required this.newName});

  @override
  List<Object?> get props => [pageId, newName];
}

/// Delete page
class DeletePage extends PageEvent {
  final String pageId;

  const DeletePage(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Share page
class SharePage extends PageEvent {
  final String pageId;
  final String email;
  final PermissionType permissionType;

  const SharePage({
    required this.pageId,
    required this.email,
    required this.permissionType,
  });

  @override
  List<Object?> get props => [pageId, email, permissionType];
}

/// Load page permissions
class LoadPagePermissions extends PageEvent {
  final String pageId;

  const LoadPagePermissions(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Revoke access
class RevokePageAccess extends PageEvent {
  final String pageId;
  final String userId;

  const RevokePageAccess({required this.pageId, required this.userId});

  @override
  List<Object?> get props => [pageId, userId];
}

/// Add widget to page
class AddWidgetToPage extends PageEvent {
  final PageWidget widget;

  const AddWidgetToPage(this.widget);

  @override
  List<Object?> get props => [widget];
}

/// Update widget in page
class UpdateWidgetInPage extends PageEvent {
  final String widgetId;
  final PageWidget updatedWidget;

  const UpdateWidgetInPage({
    required this.widgetId,
    required this.updatedWidget,
  });

  @override
  List<Object?> get props => [widgetId, updatedWidget];
}

/// Remove widget from page
class RemoveWidgetFromPage extends PageEvent {
  final String widgetId;

  const RemoveWidgetFromPage(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

/// Select widget
class SelectPageWidget extends PageEvent {
  final String? widgetId;

  const SelectPageWidget(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

/// Clear page state
class ClearPageState extends PageEvent {
  const ClearPageState();
}

// ==================== WEBSOCKET EVENTS ====================

/// Apply incoming patch from another user
class ApplyIncomingPatch extends PageEvent {
  final dynamic patchEvent; // PagePatchReceivedEvent from page_websocket_client

  const ApplyIncomingPatch(this.patchEvent);

  @override
  List<Object?> get props => [patchEvent];
}

/// Confirm patch was applied by server
class ConfirmPatchApplied extends PageEvent {
  final dynamic patchEvent; // PagePatchAppliedEvent from page_websocket_client

  const ConfirmPatchApplied(this.patchEvent);

  @override
  List<Object?> get props => [patchEvent];
}

/// Handle patch conflict
class HandlePatchConflict extends PageEvent {
  final dynamic conflictEvent; // PageConflictEvent from page_websocket_client

  const HandlePatchConflict(this.conflictEvent);

  @override
  List<Object?> get props => [conflictEvent];
}

// ==================== CURSOR & PRESENCE EVENTS ====================

/// Send cursor position to other users
class SendCursorPosition extends PageEvent {
  final String pageId;
  final double x;
  final double y;

  const SendCursorPosition({
    required this.pageId,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [pageId, x, y];
}

/// Update remote cursor (from another user)
class UpdateRemoteCursor extends PageEvent {
  final dynamic
  cursorEvent; // PageCursorUpdatedEvent from page_websocket_client

  const UpdateRemoteCursor(this.cursorEvent);

  @override
  List<Object?> get props => [cursorEvent];
}

/// Update remote selection (from another user)
class UpdateRemoteSelection extends PageEvent {
  final dynamic selectionEvent; // PageSelectionEvent from page_websocket_client

  const UpdateRemoteSelection(this.selectionEvent);

  @override
  List<Object?> get props => [selectionEvent];
}

/// Update active users list
class UpdateActiveUsers extends PageEvent {
  final List<dynamic> users;

  const UpdateActiveUsers(this.users);

  @override
  List<Object?> get props => [users];
}

// ==================== UNDO/REDO EVENTS ====================

/// Request undo operation
class UndoRequested extends PageEvent {
  final String pageId;

  const UndoRequested(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Request redo operation
class RedoRequested extends PageEvent {
  final String pageId;

  const RedoRequested(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Undo operation was applied successfully
class UndoApplied extends PageEvent {
  final dynamic undoEvent; // PageUndoAppliedEvent from page_websocket_client

  const UndoApplied(this.undoEvent);

  @override
  List<Object?> get props => [undoEvent];
}

/// Redo operation was applied successfully
class RedoApplied extends PageEvent {
  final dynamic redoEvent; // PageRedoAppliedEvent from page_websocket_client

  const RedoApplied(this.redoEvent);

  @override
  List<Object?> get props => [redoEvent];
}

/// Undo/redo state update from server
class UndoRedoStateUpdated extends PageEvent {
  final bool canUndo;
  final bool canRedo;

  const UndoRedoStateUpdated({required this.canUndo, required this.canRedo});

  @override
  List<Object?> get props => [canUndo, canRedo];
}

/// Undo operation failed
class UndoFailed extends PageEvent {
  final String message;

  const UndoFailed(this.message);

  @override
  List<Object?> get props => [message];
}

/// Redo operation failed
class RedoFailed extends PageEvent {
  final String message;

  const RedoFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== NESTED WIDGET EVENTS ====================

/// Move widget to a different parent
class MoveWidgetToParent extends PageEvent {
  final String widgetId;
  final String? newParentId; // null = move to root
  final Offset? newPosition; // optional new position

  const MoveWidgetToParent({
    required this.widgetId,
    this.newParentId,
    this.newPosition,
  });

  @override
  List<Object?> get props => [widgetId, newParentId, newPosition];
}

/// Remove widget and all its descendants
class RemoveWidgetWithChildren extends PageEvent {
  final String widgetId;
  final bool cascade; // If true, also remove children

  const RemoveWidgetWithChildren(this.widgetId, {this.cascade = true});

  @override
  List<Object?> get props => [widgetId, cascade];
}

// ==================== FOLLOW FEATURE EVENTS ====================

/// Start following another user's viewport
class StartFollowingUser extends PageEvent {
  final String pageId;
  final String targetUserId;

  const StartFollowingUser({required this.pageId, required this.targetUserId});

  @override
  List<Object?> get props => [pageId, targetUserId];
}

/// Stop following user
class StopFollowingUser extends PageEvent {
  final String pageId;

  const StopFollowingUser(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Followed user's viewport was updated
class FollowedUserViewportUpdated extends PageEvent {
  final dynamic
  viewportEvent; // PageViewportUpdatedEvent from page_websocket_client

  const FollowedUserViewportUpdated(this.viewportEvent);

  @override
  List<Object?> get props => [viewportEvent];
}

/// User manually exited follow mode (by interacting with canvas)
class FollowModeExitedByUser extends PageEvent {
  final String pageId;

  const FollowModeExitedByUser(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Send viewport update to followers
class SendViewportUpdate extends PageEvent {
  final String pageId;
  final dynamic viewport; // ViewportData

  const SendViewportUpdate({required this.pageId, required this.viewport});

  @override
  List<Object?> get props => [pageId, viewport];
}

/// Follow started confirmation
class FollowStarted extends PageEvent {
  final dynamic
  followEvent; // PageFollowStartedEvent from page_websocket_client

  const FollowStarted(this.followEvent);

  @override
  List<Object?> get props => [followEvent];
}

/// Follow stopped confirmation
class FollowStopped extends PageEvent {
  final dynamic
  followEvent; // PageFollowStoppedEvent from page_websocket_client

  const FollowStopped(this.followEvent);

  @override
  List<Object?> get props => [followEvent];
}

/// Follow error
class FollowError extends PageEvent {
  final String message;

  const FollowError(this.message);

  @override
  List<Object?> get props => [message];
}
