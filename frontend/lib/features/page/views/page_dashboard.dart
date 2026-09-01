import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/page_bloc.dart';
import '../bloc/page_event.dart';
import '../bloc/page_state.dart';
import '../../../core/models/page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import 'page_editor_screen.dart';

class PageDashboard extends StatefulWidget {
  const PageDashboard({super.key});

  @override
  State<PageDashboard> createState() => _PageDashboardState();
}

class _PageDashboardState extends State<PageDashboard> {
  String? _lastNavigatedPageId;

  @override
  void initState() {
    super.initState();
    // Load pages on init
    context.read<PageBloc>().add(const LoadPages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PageBloc>().add(const LoadPages());
            },
            tooltip: 'Refresh',
          ),
          // User profile
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
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
                        Text(
                          authState.user.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: BlocConsumer<PageBloc, PageState>(
        listener: (context, state) {
          // Show error messages
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Navigate to editor when page is created (only once per page)
          if (state.currentPage != null &&
              !state.isLoading &&
              state.currentPage!.id != _lastNavigatedPageId) {
            _lastNavigatedPageId = state.currentPage!.id;
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<PageBloc>(),
                      child: PageEditorScreen(pageId: state.currentPage!.id),
                    ),
                  ),
                )
                .then((_) {
                  // Clear tracking when returning from editor
                  _lastNavigatedPageId = null;
                  // Clear currentPage from state
                  context.read<PageBloc>().add(const ClearPageState());
                });
          }
        },
        builder: (context, state) {
          if (state.pagesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!state.hasPages) {
            return _buildEmptyState(context);
          }

          return _buildPageGrid(context, state.pages);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePageDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Page'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No pages yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first page to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreatePageDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Page'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageGrid(BuildContext context, List<PageListItem> pages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          return _buildPageCard(context, page);
        },
      ),
    );
  }

  Widget _buildPageCard(BuildContext context, PageListItem page) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PageBloc>(),
                child: PageEditorScreen(pageId: page.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with permission badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      page.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPermissionBadge(page.permission),
                ],
              ),
              const Spacer(),
              // Version info
              Text(
                'Version ${page.version}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              // Last updated
              Text(
                'Updated ${_formatDate(page.updatedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  if (page.isOwner) ...[
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () => _showShareDialog(context, page),
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showRenameDialog(context, page),
                      tooltip: 'Rename',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteDialog(context, page),
                      tooltip: 'Delete',
                      color: Colors.red,
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBadge(PermissionType permission) {
    Color color;
    IconData icon;
    String label;

    switch (permission) {
      case PermissionType.owner:
        color = Colors.blue;
        icon = Icons.star;
        label = 'Owner';
        break;
      case PermissionType.edit:
        color = Colors.green;
        icon = Icons.edit;
        label = 'Edit';
        break;
      case PermissionType.comment:
        color = Colors.orange;
        icon = Icons.comment;
        label = 'Comment';
        break;
      case PermissionType.view:
        color = Colors.grey;
        icon = Icons.visibility;
        label = 'View';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showCreatePageDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Page'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Page Name',
            hintText: 'Enter page name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<PageBloc>().add(
                  CreatePage(name: nameController.text.trim()),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PageListItem page) {
    final nameController = TextEditingController(text: page.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Page'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Page Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<PageBloc>().add(
                  RenamePage(
                    pageId: page.id,
                    newName: nameController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, PageListItem page) {
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
                      pageId: page.id,
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

  void _showDeleteDialog(BuildContext context, PageListItem page) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Are you sure you want to delete "${page.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PageBloc>().add(DeletePage(page.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
