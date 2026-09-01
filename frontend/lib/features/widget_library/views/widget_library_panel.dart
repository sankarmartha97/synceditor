import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../canvas/bloc/canvas_bloc.dart';
import '../../canvas/bloc/canvas_event.dart';
import '../../canvas/models/canvas_widget.dart';

class WidgetLibraryPanel extends StatelessWidget {
  const WidgetLibraryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory(context, 'LAYOUT (Multi-Widget)', [
            _WidgetItem(
              name: 'Container',
              icon: Icons.crop_square,
              color: Colors.blue[400]!,
              type: 'Container',
              isContainer: true,
            ),
            _WidgetItem(
              name: 'Card',
              icon: Icons.credit_card,
              color: Colors.purple[400]!,
              type: 'Card',
              isContainer: true,
            ),
            _WidgetItem(
              name: 'Row',
              icon: Icons.view_week,
              color: Colors.teal[400]!,
              type: 'Row',
              isContainer: true,
            ),
            _WidgetItem(
              name: 'Column',
              icon: Icons.view_column,
              color: Colors.cyan[400]!,
              type: 'Column',
              isContainer: true,
            ),
            _WidgetItem(
              name: 'Stack',
              icon: Icons.layers,
              color: Colors.indigo[400]!,
              type: 'Stack',
              isContainer: true,
            ),
          ]),
          const SizedBox(height: 20),
          _buildCategory(context, 'BASIC (Single Widget)', [
            _WidgetItem(
              name: 'Text',
              icon: Icons.text_fields,
              color: Colors.green[400]!,
              type: 'Text',
            ),
            _WidgetItem(
              name: 'Button',
              icon: Icons.smart_button,
              color: Colors.red[400]!,
              type: 'Button',
            ),
            _WidgetItem(
              name: 'Image',
              icon: Icons.image,
              color: Colors.orange[400]!,
              type: 'Image',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String title,
    List<_WidgetItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDraggableWidget(context, item),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableWidget(BuildContext context, _WidgetItem item) {
    // Build widget data with proper defaults based on widget type
    double defaultWidth;
    double defaultHeight;

    // Set sizes based on widget type
    if (item.type == 'Container' ||
        item.type == 'Card' ||
        item.type == 'Row' ||
        item.type == 'Column' ||
        item.type == 'Stack') {
      // Multi-widgets: 400x150
      defaultWidth = 400.0;
      defaultHeight = 150.0;
    } else if (item.type == 'Image') {
      // Image: 150x150
      defaultWidth = 150.0;
      defaultHeight = 150.0;
    } else {
      // Text, Button: 150x50
      defaultWidth = 150.0;
      defaultHeight = 50.0;
    }

    final widgetData = {
      'type': item.type,
      'defaultWidth': defaultWidth,
      'defaultHeight': defaultHeight,
      'properties': _getDefaultProperties(item.type),
    };

    return Draggable<Map<String, dynamic>>(
      data: widgetData,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: item.color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: 20),
              const SizedBox(width: 8),
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildWidgetCard(item)),
      child: _buildWidgetCard(item),
    );
  }

  Map<String, dynamic> _getDefaultProperties(String type) {
    switch (type) {
      case 'Text':
        return {
          'text': 'Sample Text',
          'color': '#2196F3',
          'borderRadius': 8.0,
          'opacity': 1.0,
        };
      case 'Button':
        return {
          'text': 'Click Me',
          'color': '#F44336',
          'borderRadius': 8.0,
          'opacity': 1.0,
        };
      case 'Container':
        return {'color': '#2196F3', 'borderRadius': 8.0, 'opacity': 1.0};
      case 'Card':
        return {'color': '#9C27B0', 'borderRadius': 12.0, 'opacity': 1.0};
      case 'Row':
        return {
          'color': '#26A69A',
          'borderRadius': 8.0,
          'opacity': 1.0,
          'text': 'Row',
        };
      case 'Column':
        return {
          'color': '#00ACC1',
          'borderRadius': 8.0,
          'opacity': 1.0,
          'text': 'Column',
        };
      case 'Stack':
        return {
          'color': '#5C6BC0',
          'borderRadius': 8.0,
          'opacity': 1.0,
          'text': 'Stack',
        };
      case 'Image':
        return {
          'text': '🖼️ Image',
          'color': '#FF9800',
          'borderRadius': 8.0,
          'opacity': 1.0,
        };
      default:
        return {'color': '#2196F3', 'borderRadius': 0.0, 'opacity': 1.0};
    }
  }

  Widget _buildWidgetCard(_WidgetItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [item.color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            item.isContainer ? 'Can hold child widgets' : 'Drag to canvas',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          dense: true,
        ),
      ),
    );
  }
}

class _WidgetItem {
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final bool isContainer; // ✨ NEW

  _WidgetItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isContainer = false, // ✨ NEW
  });
}
