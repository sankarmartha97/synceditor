import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/page.dart';
import 'package:frontend/core/models/position_mode.dart';
import 'package:frontend/core/services/patch_service.dart';

PageWidget makeWidget({
  Offset position = const Offset(10, 10),
  Size size = const Size(100, 50),
  Map<String, dynamic>? properties,
}) {
  return PageWidget(
    id: 'w1',
    type: 'Container',
    position: position,
    size: size,
    properties: properties ?? {'color': '#FFFFFF'},
    parentId: null,
    isContainer: false,
    zIndex: 0,
    positionMode: PositionMode.absolute,
  );
}

void main() {
  final service = PatchService();

  test('position-only change produces exactly one patch, for position', () {
    final oldW = makeWidget();
    final newW = makeWidget(position: const Offset(99, 99));

    final patches = service.generateWidgetFieldPatch(0, oldW, newW);

    expect(patches.length, 1);
    expect(patches.first['path'], '/widgets/0/position');
    expect(patches.first['op'], 'replace');
    expect(patches.first['value'], {'x': 99.0, 'y': 99.0});
  });

  test('no change produces zero patches', () {
    final oldW = makeWidget();
    final newW = makeWidget();

    final patches = service.generateWidgetFieldPatch(0, oldW, newW);

    expect(patches, isEmpty);
  });

  test('nested properties change is detected via deep equality', () {
    final oldW = makeWidget(properties: {'color': '#FFFFFF', 'opacity': 1.0});
    final newW = makeWidget(properties: {'color': '#000000', 'opacity': 1.0});

    final patches = service.generateWidgetFieldPatch(0, oldW, newW);

    expect(patches.length, 1);
    expect(patches.first['path'], '/widgets/0/properties');
    expect(patches.first['value'], {'color': '#000000', 'opacity': 1.0});
  });

  test('id is never included even if somehow different', () {
    final oldW = makeWidget();
    final newW = makeWidget(position: const Offset(5, 5));

    final patches = service.generateWidgetFieldPatch(0, oldW, newW);

    expect(patches.any((p) => (p['path'] as String).endsWith('/id')), isFalse);
  });

  test('multiple changed fields produce one patch per field', () {
    final oldW = makeWidget();
    final newW = makeWidget(position: const Offset(1, 1), size: const Size(1, 1));

    final patches = service.generateWidgetFieldPatch(0, oldW, newW);
    final paths = patches.map((p) => p['path']).toSet();

    expect(paths, {'/widgets/0/position', '/widgets/0/size'});
  });
}
