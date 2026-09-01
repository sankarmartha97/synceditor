import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/page.dart';
import '../bloc/page_bloc.dart';
import '../bloc/page_event.dart';
import '../bloc/page_state.dart';
import '../managers/cursor_manager.dart';
import '../widgets/active_users_list.dart';
import '../../widget_library/views/left_panel_tabs.dart';
import '../../properties/views/properties_panel.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'page_canvas_view.dart';

// Intent classes for keyboard shortcuts
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class PageEditorScreen extends StatefulWidget {
  final String pageId;

  const PageEditorScreen({super.key, required this.pageId});

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  bool _showActiveUsers = true;
  TransformationController? _canvasTransformationController;

  // Static shortcuts to avoid rebuilding on every build
  static final Map<LogicalKeySet, Intent> _shortcuts = {
    // Undo: Ctrl+Z
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
        const UndoIntent(),
    // Redo: Ctrl+Shift+Z
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.keyZ,
    ): const RedoIntent(),
    // Redo: Ctrl+Y (Windows/Linux/Web)
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
        const RedoIntent(),
  };

  @override
  void initState() {
    super.initState();
    // Load the page
    context.read<PageBloc>().add(LoadPage(widget.pageId));
  }

  /// Convert screen coordinates to canvas coordinates accounting for zoom/pan
  Offset? _screenToCanvasCoordinates(Offset screenPosition) {
    if (_canvasTransformationController == null) {
      return screenPosition; // Fallback if controller not ready
    }

    try {
      final matrix = _canvasTransformationController!.value;
      final invertedMatrix = Matrix4.inverted(matrix);
      final canvasPosition = MatrixUtils.transformPoint(
        invertedMatrix,
        screenPosition,
      );
      return canvasPosition;
    } catch (e) {
      print('⚠️ Error transforming coordinates: $e');
      return screenPosition; // Fallback on error
    }
  }

  /// Convert canvas coordinates to screen coordinates for display
  Offset? _canvasToScreenCoordinates(Offset canvasPosition) {
    if (_canvasTransformationController == null) {
      return canvasPosition; // Fallback if controller not ready
    }

    try {
      final matrix = _canvasTransformationController!.value;
      final screenPosition = MatrixUtils.transformPoint(matrix, canvasPosition);
      return screenPosition;
    } catch (e) {
      print('⚠️ Error transforming coordinates: $e');
      return canvasPosition; // Fallback on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PageBloc, PageState>(
      listener: (context, state) {
        // Show error messages
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }

        // Show saving indicator
        if (state.isSaving) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Saving...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.currentPageLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!state.hasCurrentPage) {
          return Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('Page not found or you don\'t have access.'),
            ),
          );
        }

        return _buildEditor(context, state);
      },
    );
  }

  Widget _buildEditor(BuildContext context, PageState state) {
    final page = state.currentPage!;
    final canEdit = state.canEdit;

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (UndoIntent intent) {
              if (canEdit && state.canUndo && !state.isUndoing) {
                context.read<PageBloc>().add(UndoRequested(page.id));
              }
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (RedoIntent intent) {
              if (canEdit && state.canRedo && !state.isRedoing) {
                context.read<PageBloc>().add(RedoRequested(page.id));
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    canEdit ? 'Editing' : 'View only',
                    style: TextStyle(
                      fontSize: 12,
                      color: canEdit ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              actions: [
                // Active users indicator/toggle
                if (state.activeUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showActiveUsers = !_showActiveUsers;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${state.activeUsers.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Icon(
                              _showActiveUsers
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Sync status indicator
                if (state.isSyncing)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[300]!,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Syncing...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Synced indicator (show briefly after sync completes)
                if (!state.isSyncing && state.hasCurrentPage)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Synced',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Undo/Redo buttons (if can edit)
                if (canEdit) ...[
                  // Undo button
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: state.canUndo && !state.isUndoing
                        ? () {
                            context.read<PageBloc>().add(
                              UndoRequested(page.id),
                            );
                          }
                        : null,
                    tooltip: state.canUndo
                        ? 'Undo (Ctrl+Z)'
                        : 'Nothing to undo',
                    color: state.canUndo ? null : Colors.grey[400],
                    disabledColor: Colors.grey[300],
                  ),
                  // Redo button
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: state.canRedo && !state.isRedoing
                        ? () {
                            context.read<PageBloc>().add(
                              RedoRequested(page.id),
                            );
                          }
                        : null,
                    tooltip: state.canRedo
                        ? 'Redo (Ctrl+Y or Ctrl+Shift+Z)'
                        : 'Nothing to redo',
                    color: state.canRedo ? null : Colors.grey[400],
                    disabledColor: Colors.grey[300],
                  ),
                ],
                // Version indicator
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'v${page.version}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ),
                // Share button (owner only)
                if (state.isOwner)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showShareDialog(context, page.id),
                    tooltip: 'Share',
                  ),
                // Permissions button (owner only)
                if (state.isOwner)
                  IconButton(
                    icon: const Icon(Icons.people),
                    onPressed: () {
                      context.read<PageBloc>().add(
                        LoadPagePermissions(page.id),
                      );
                      _showPermissionsDialog(context);
                    },
                    tooltip: 'Manage Access',
                  ),
                // User profile indicator
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState is AuthAuthenticated) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, right: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade300,
                                child: Text(
                                  authState.user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authState.user.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    authState.user.email,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Row(
              children: [
                // Widget Library Panel (if can edit)
                if (canEdit)
                  Container(
                    width: 250,
                    color: Colors.white,
                    child: const LeftPanelTabs(),
                  ),
                // Canvas with cursor tracking and overlay
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return MouseRegion(
                        onHover: (event) {
                          // Send cursor position to other users
                          if (canEdit && state.currentPage != null) {
                            // Convert screen position to container-relative position
                            final RenderBox? renderBox =
                                context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              final localPosition = renderBox.globalToLocal(
                                event.position,
                              );

                              // Transform to canvas coordinates (accounting for zoom/pan)
                              final canvasPosition = _screenToCanvasCoordinates(
                                localPosition,
                              );

                              if (canvasPosition != null) {
                                context.read<PageBloc>().add(
                                  SendCursorPosition(
                                    pageId: state.currentPage!.id,
                                    x: canvasPosition.dx,
                                    y: canvasPosition.dy,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            // Main canvas
                            PageCanvasView(
                              page: page,
                              onTransformationControllerReady: (controller) {
                                setState(() {
                                  _canvasTransformationController = controller;
                                });
                              },
                            ),
                            // Remote cursors overlay
                            CursorOverlay(
                              cursorManager: context
                                  .read<PageBloc>()
                                  .cursorManager,
                              showAnimations: true,
                              transformationController:
                                  _canvasTransformationController,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Properties Panel
                if (state.selectedWidget != null)
                  Container(
                    width: 300,
                    color: Colors.white,
                    child: const PropertiesPanel(),
                  ),
                // Active Users List (sidebar)
                if (_showActiveUsers)
                  ActiveUsersList(
                    users: state.activeUsers,
                    currentUserId: null, // TODO: Get current user ID from auth
                    isCollapsed: false,
                    onToggleCollapse: () {
                      setState(() {
                        _showActiveUsers = !_showActiveUsers;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, String pageId) {
    final emailController = TextEditingController();
    PermissionType selectedPermission = PermissionType.view;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Share Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PermissionType>(
                value: selectedPermission,
                decoration: const InputDecoration(labelText: 'Permission'),
                items: const [
                  DropdownMenuItem(
                    value: PermissionType.view,
                    child: Text('View only'),
                  ),
                  DropdownMenuItem(
                    value: PermissionType.comment,
                    child: Text('Can comment'),
                  ),
                  DropdownMenuItem(
                    value: PermissionType.edit,
                    child: Text('Can edit'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedPermission = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.trim().isNotEmpty) {
                  context.read<PageBloc>().add(
                    SharePage(
                      pageId: pageId,
                      email: emailController.text.trim(),
                      permissionType: selectedPermission,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<PageBloc, PageState>(
        builder: (context, state) {
          if (state.permissionsLoading) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return AlertDialog(
            title: const Text('Manage Access'),
            content: SizedBox(
              width: 400,
              child: state.permissions.isEmpty
                  ? const Text('No shared users yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.permissions.length,
                      itemBuilder: (context, index) {
                        final perm = state.permissions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (perm.userName ?? perm.userEmail ?? 'U')[0]
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(
                            perm.userName ?? perm.userEmail ?? 'User',
                          ),
                          subtitle: Text(perm.userEmail ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(perm.permissionType.name)),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  context.read<PageBloc>().add(
                                    RevokePageAccess(
                                      pageId: perm.pageId,
                                      userId: perm.userId,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
