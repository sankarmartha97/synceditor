import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/canvas/bloc/canvas_bloc.dart';
import '../features/canvas/bloc/canvas_event.dart';
import '../features/canvas/bloc/canvas_state.dart';
import '../features/widget_library/views/left_panel_tabs.dart';
import '../features/canvas/views/canvas_view.dart';
import '../features/properties/views/properties_panel.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../core/services/sync_service.dart';
import '../features/canvas/widgets/user_presence_indicator.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Check URL for canvas ID or auto-create canvas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final canvasBloc = context.read<CanvasBloc>();
      if (canvasBloc.state.currentCanvasId == null) {
        // Check if canvas ID is in URL query params
        final uri = Uri.base;
        final canvasId = uri.queryParameters['canvas'];

        if (canvasId != null && canvasId.isNotEmpty) {
          print('🔗 Loading canvas from URL: $canvasId');
          canvasBloc.add(LoadCanvas(canvasId));
        } else {
          print('🎨 Creating default PUBLIC canvas...');
          canvasBloc.add(const CreateNewCanvas(name: 'Shared Canvas'));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Canvas Editor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Share Canvas button
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              if (state.currentCanvasId == null) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final canvasId = state.currentCanvasId!;
                  final shareUrl = '${Uri.base.origin}?canvas=$canvasId';

                  // Show dialog with shareable URL
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.share, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Share Canvas'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share this URL with others to collaborate:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              shareUrl,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '✨ This canvas is PUBLIC - anyone with this link can view and edit!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Copy to clipboard would need clipboard package
                            // For now, user can select and copy
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select and copy the URL above!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Link'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Share Canvas',
              );
            },
          ),
          // Save status indicator
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              // Access sync service to show save status
              return StreamBuilder<SyncState>(
                stream: context.read<CanvasBloc>().syncService.syncState,
                initialData: SyncState.synced,
                builder: (context, snapshot) {
                  final syncState = snapshot.data ?? SyncState.synced;

                  IconData icon;
                  Color color;
                  String tooltip;

                  switch (syncState) {
                    case SyncState.syncing:
                      icon = Icons.sync;
                      color = Colors.orange;
                      tooltip = 'Saving...';
                      break;
                    case SyncState.pending:
                      icon = Icons.schedule;
                      color = Colors.blue;
                      tooltip = 'Changes pending...';
                      break;
                    case SyncState.failed:
                      icon = Icons.error;
                      color = Colors.red;
                      tooltip = 'Save failed';
                      break;
                    case SyncState.synced:
                    default:
                      icon = Icons.cloud_done;
                      color = Colors.green;
                      tooltip = 'All changes saved';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Tooltip(
                      message: tooltip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            tooltip,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              final canUndo = state.undoHistory.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: canUndo
                    ? () => context.read<CanvasBloc>().add(const UndoAction())
                    : null,
                tooltip: 'Undo (Ctrl+Z)',
              );
            },
          ),
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              final canRedo = state.redoHistory.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.redo),
                onPressed: canRedo
                    ? () => context.read<CanvasBloc>().add(const RedoAction())
                    : null,
                tooltip: 'Redo (Ctrl+Y)',
              );
            },
          ),
          const SizedBox(width: 8),
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              return Chip(
                avatar: const Icon(Icons.widgets, size: 16),
                label: Text('${state.widgets.length} widgets'),
              );
            },
          ),
          const SizedBox(width: 16),
          // User presence indicator
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              return UserPresenceIndicator(activeUsers: state.activeUsers);
            },
          ),
          const SizedBox(width: 16),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AuthBloc>().add(const LogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Widget Library
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const LeftPanelTabs(),
          ),

          // Center Panel - Canvas
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: const CanvasView(),
            ),
          ),

          // Right Panel - Properties
          BlocBuilder<CanvasBloc, CanvasState>(
            builder: (context, state) {
              if (state.selectedWidget != null) {
                return Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: const PropertiesPanel(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
