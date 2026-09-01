import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/models/page.dart';
import '../../page/bloc/page_bloc.dart';
import '../../page/bloc/page_event.dart';
import '../../page/bloc/page_state.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    } else {
      // Update controller if value changed externally (from sync)
      if (_controllers[key]!.text != initialValue) {
        _controllers[key]!.text = initialValue;
      }
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        final selectedWidget = state.selectedWidget;

        if (selectedWidget == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No widget selected',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Click on a widget to view its properties',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Properties',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (state.isSyncing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      context.read<PageBloc>().add(
                        const SelectPageWidget(null),
                      );
                    },
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Properties List
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Widget Info
                    _buildSection('Widget', [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.widgets),
                          title: Text(selectedWidget.type),
                          subtitle: Text(
                            'ID: ${selectedWidget.id.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Position - Editable
                    _buildSection('Position', [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              _buildNumberInput(
                                label: 'X',
                                value: selectedWidget.position.dx,
                                onChanged: (newX) {
                                  _updateWidgetPosition(
                                    context,
                                    selectedWidget,
                                    newX,
                                    selectedWidget.position.dy,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberInput(
                                label: 'Y',
                                value: selectedWidget.position.dy,
                                onChanged: (newY) {
                                  _updateWidgetPosition(
                                    context,
                                    selectedWidget,
                                    selectedWidget.position.dx,
                                    newY,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Size - Editable
                    _buildSection('Size', [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              _buildNumberInput(
                                label: 'Width',
                                value: selectedWidget.size.width,
                                min: 10,
                                max: 2000,
                                onChanged: (newWidth) {
                                  _updateWidgetSize(
                                    context,
                                    selectedWidget,
                                    newWidth,
                                    selectedWidget.size.height,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberInput(
                                label: 'Height',
                                value: selectedWidget.size.height,
                                min: 10,
                                max: 2000,
                                onChanged: (newHeight) {
                                  _updateWidgetSize(
                                    context,
                                    selectedWidget,
                                    selectedWidget.size.width,
                                    newHeight,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Properties - Editable
                    if (selectedWidget.properties.isNotEmpty) ...[
                      _buildSection('Widget Properties', [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: selectedWidget.properties.entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: _buildPropertyInput(
                                        context,
                                        selectedWidget,
                                        entry.key,
                                        entry.value,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Delete Button - Hide for default container
                    if (!selectedWidget.isDefaultContainer) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Widget?'),
                              content: Text(
                                'Are you sure you want to delete this ${selectedWidget.type}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    context.read<PageBloc>().add(
                                      RemoveWidgetFromPage(selectedWidget.id),
                                    );
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
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Widget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Info message
                    Card(
                      color: Colors.green.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Properties sync in real-time with other users',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required double value,
    double? min,
    double? max,
    required Function(double) onChanged,
  }) {
    final controller = _getController(label, value.toStringAsFixed(0));

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              suffixText: 'px',
              suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (text) {
              final newValue = double.tryParse(text);
              if (newValue != null) {
                if (min != null && newValue < min) {
                  controller.text = min.toStringAsFixed(0);
                  onChanged(min);
                } else if (max != null && newValue > max) {
                  controller.text = max.toStringAsFixed(0);
                  onChanged(max);
                } else {
                  onChanged(newValue);
                }
              } else {
                controller.text = value.toStringAsFixed(0);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyInput(
    BuildContext context,
    PageWidget widget,
    String key,
    dynamic value,
  ) {
    // Handle different property types
    if (value is bool) {
      return Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              _updateWidgetProperty(context, widget, key, newValue);
            },
          ),
        ],
      );
    } else if (value is num) {
      return _buildNumberInput(
        label: key,
        value: value.toDouble(),
        onChanged: (newValue) {
          _updateWidgetProperty(context, widget, key, newValue);
        },
      );
    } else if (value is String) {
      // Check if it's a color value
      if (key.toLowerCase().contains('color') && value.startsWith('#')) {
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () {
                  _showColorPicker(context, widget, key, value);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(value),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Icon(Icons.colorize, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // Regular text field
        final controller = _getController('prop_$key', value);
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (text) {
                  _updateWidgetProperty(context, widget, key, text);
                },
              ),
            ),
          ],
        );
      }
    } else {
      // Fallback for other types
      return ListTile(
        dense: true,
        title: Text(key),
        subtitle: Text(value.toString(), style: const TextStyle(fontSize: 12)),
      );
    }
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _updateWidgetPosition(
    BuildContext context,
    PageWidget widget,
    double newX,
    double newY,
  ) {
    final updatedWidget = widget.copyWith(position: Offset(newX, newY));

    context.read<PageBloc>().add(
      UpdateWidgetInPage(widgetId: widget.id, updatedWidget: updatedWidget),
    );
  }

  void _updateWidgetSize(
    BuildContext context,
    PageWidget widget,
    double newWidth,
    double newHeight,
  ) {
    final updatedWidget = widget.copyWith(size: Size(newWidth, newHeight));

    context.read<PageBloc>().add(
      UpdateWidgetInPage(widgetId: widget.id, updatedWidget: updatedWidget),
    );
  }

  void _updateWidgetProperty(
    BuildContext context,
    PageWidget widget,
    String key,
    dynamic value,
  ) {
    final updatedProperties = Map<String, dynamic>.from(widget.properties);
    updatedProperties[key] = value;

    final updatedWidget = widget.copyWith(properties: updatedProperties);

    context.read<PageBloc>().add(
      UpdateWidgetInPage(widgetId: widget.id, updatedWidget: updatedWidget),
    );
  }

  void _showColorPicker(
    BuildContext context,
    PageWidget widget,
    String propertyKey,
    String currentColorHex,
  ) {
    Color pickerColor = _parseColor(currentColorHex);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Pick $propertyKey'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Convert color to hex string
                final hex =
                    '#${pickerColor.value.toRadixString(16).substring(2).toUpperCase()}';
                _updateWidgetProperty(context, widget, propertyKey, hex);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
