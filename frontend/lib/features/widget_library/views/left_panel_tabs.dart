import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/page.dart';
import '../../page/bloc/page_bloc.dart';
import '../../page/bloc/page_event.dart';
import '../../page/bloc/page_state.dart';
import 'widget_library_panel.dart';

class LeftPanelTabs extends StatefulWidget {
  const LeftPanelTabs({super.key});

  @override
  State<LeftPanelTabs> createState() => _LeftPanelTabsState();
}

class _LeftPanelTabsState extends State<LeftPanelTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.widgets, size: 20), text: 'Widgets'),
              Tab(
                icon: Icon(Icons.account_tree, size: 20),
                text: 'Widget Tree',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Widget Library
              const WidgetLibraryPanel(),

              // Tab 2: Widget Tree
              const WidgetTreeView(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget Tree View - Shows hierarchical structure of widgets
class WidgetTreeView extends StatefulWidget {
  const WidgetTreeView({super.key});

  @override
  State<WidgetTreeView> createState() => _WidgetTreeViewState();
}

class _WidgetTreeViewState extends State<WidgetTreeView> {
  // Track collapsed state of each widget (empty = all expanded by default)
  final Set<String> _collapsedNodes = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        final page = state.currentPage;

        if (page == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No page loaded',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final widgets = page.pageData.widgets;
        final rootWidgets = widgets.where((w) => w.parentId == null).toList();

        if (rootWidgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.widgets_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No widgets on canvas',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag widgets from the Widgets tab',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey[50],
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: rootWidgets.map((widget) {
              return _buildTreeNode(
                context,
                widget,
                widgets,
                state.selectedWidgetId,
                0,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTreeNode(
    BuildContext context,
    PageWidget widget,
    List<PageWidget> allWidgets,
    String? selectedWidgetId,
    int depth,
  ) {
    final isSelected = widget.id == selectedWidgetId;

    // Check if selected by other users
    final state = context.read<PageBloc>().state;
    final selectedByOthers = state.otherUsersSelections.entries
        .where((entry) => entry.value == widget.id)
        .toList();
    final hasOtherUserSelection = selectedByOthers.isNotEmpty;

    final children = allWidgets.where((w) => w.parentId == widget.id).toList();
    final hasChildren = children.isNotEmpty;
    final isExpanded = !_collapsedNodes.contains(
      widget.id,
    ); // ✨ NEW: Expanded by default

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Widget Node
        InkWell(
          onTap: () {
            context.read<PageBloc>().add(SelectPageWidget(widget.id));
          },
          child: Container(
            margin: EdgeInsets.only(left: depth * 16.0, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : hasOtherUserSelection
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : hasOtherUserSelection
                    ? Colors.orange
                    : Colors.grey[300]!,
                width: isSelected
                    ? 2
                    : hasOtherUserSelection
                    ? 2
                    : 1,
              ),
            ),
            child: Row(
              children: [
                // Expand/Collapse Icon
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _collapsedNodes.add(
                            widget.id,
                          ); // ✨ NEW: Add to collapsed
                        } else {
                          _collapsedNodes.remove(
                            widget.id,
                          ); // ✨ NEW: Remove from collapsed
                        }
                      });
                    },
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  const SizedBox(width: 20),

                const SizedBox(width: 4),

                // Widget Icon
                Icon(
                  _getWidgetIcon(widget.type),
                  size: 18,
                  color: _getWidgetColor(widget.type),
                ),
                const SizedBox(width: 8),

                // Widget Type
                Expanded(
                  child: Text(
                    widget.type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                ),

                // Children Count
                if (hasChildren) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${children.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],

                // Other user selection indicator
                if (hasOtherUserSelection) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Selected by another user',
                    child: Icon(Icons.person, size: 16, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Render Children Recursively (only if expanded)
        if (hasChildren && isExpanded)
          ...children.map((child) {
            return _buildTreeNode(
              context,
              child,
              allWidgets,
              selectedWidgetId,
              depth + 1,
            );
          }),
      ],
    );
  }

  IconData _getWidgetIcon(String type) {
    switch (type) {
      case 'Container':
        return Icons.crop_square;
      case 'Card':
        return Icons.credit_card;
      case 'Row':
        return Icons.view_week;
      case 'Column':
        return Icons.view_column;
      case 'Stack':
        return Icons.layers;
      case 'Text':
        return Icons.text_fields;
      case 'Button':
        return Icons.smart_button;
      case 'Image':
        return Icons.image;
      default:
        return Icons.widgets;
    }
  }

  Color _getWidgetColor(String type) {
    switch (type) {
      case 'Container':
        return Colors.blue[400]!;
      case 'Card':
        return Colors.purple[400]!;
      case 'Row':
        return Colors.teal[400]!;
      case 'Column':
        return Colors.cyan[400]!;
      case 'Stack':
        return Colors.indigo[400]!;
      case 'Text':
        return Colors.green[400]!;
      case 'Button':
        return Colors.red[400]!;
      case 'Image':
        return Colors.orange[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
}
