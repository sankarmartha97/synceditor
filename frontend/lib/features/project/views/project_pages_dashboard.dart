import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../../../core/models/project.dart';
import '../../../core/models/page.dart';
import '../../page/bloc/page_bloc.dart';
import '../../page/bloc/page_event.dart';
import '../../page/bloc/page_state.dart';
import '../../page/views/page_editor_screen.dart';

/// Shows the pages that belong to a specific project.
/// Uses ProjectBloc for the page list and PageBloc to open/create pages.
class ProjectPagesDashboard extends StatefulWidget {
  final ProjectListItem project;

  const ProjectPagesDashboard({super.key, required this.project});

  @override
  State<ProjectPagesDashboard> createState() => _ProjectPagesDashboardState();
}

class _ProjectPagesDashboardState extends State<ProjectPagesDashboard> {
  String? _lastNavigatedPageId;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(LoadProjectPages(widget.project.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProjectBloc>().add(
              LoadProjectPages(widget.project.id),
            ),
            tooltip: 'Refresh',
          ),
          if (widget.project.isOwner)
            IconButton(
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => _showInviteDialog(context),
              tooltip: 'Invite member',
            ),
        ],
      ),
      body: BlocListener<PageBloc, PageState>(
        // Navigate to editor when a page is created from this screen.
        listener: (context, state) {
          if (state.currentPage != null &&
              !state.isLoading &&
              state.currentPage!.id != _lastNavigatedPageId) {
            _lastNavigatedPageId = state.currentPage!.id;
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PageBloc>(),
                    child: PageEditorScreen(pageId: state.currentPage!.id),
                  ),
                ))
                .then((_) {
              _lastNavigatedPageId = null;
              context.read<PageBloc>().add(const ClearPageState());
              // Refresh project pages after returning from editor.
              context.read<ProjectBloc>().add(LoadProjectPages(widget.project.id));
            });
          }
        },
        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            if (state.pagesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.currentProjectPages.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildPageGrid(context, state.currentProjectPages);
          },
        ),
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
            'Create the first page in ${widget.project.name}',
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
        itemBuilder: (context, index) => _buildPageCard(context, pages[index]),
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
          ).then((_) {
            context.read<ProjectBloc>().add(LoadProjectPages(widget.project.id));
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Version ${page.version}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Updated ${_formatDate(page.updatedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
    String label;
    switch (permission) {
      case PermissionType.owner:
        color = Colors.blue;
        label = 'Owner';
        break;
      case PermissionType.edit:
        color = Colors.green;
        label = 'Edit';
        break;
      case PermissionType.comment:
        color = Colors.orange;
        label = 'Comment';
        break;
      case PermissionType.view:
        color = Colors.grey;
        label = 'View';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showCreatePageDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('New Page in ${widget.project.name}'),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<PageBloc>().add(
                  CreatePage(name: name, projectId: widget.project.id),
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

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    PermissionType selected = PermissionType.edit;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PermissionType>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Permission'),
                items: const [
                  DropdownMenuItem(value: PermissionType.view, child: Text('View only')),
                  DropdownMenuItem(value: PermissionType.comment, child: Text('Can comment')),
                  DropdownMenuItem(value: PermissionType.edit, child: Text('Can edit')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selected = v);
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
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  context.read<ProjectBloc>().add(AddProjectMember(
                    projectId: widget.project.id,
                    email: email,
                    permissionType: selected,
                  ));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
