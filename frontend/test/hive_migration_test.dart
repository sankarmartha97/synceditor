import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/models/page.dart';
import 'package:frontend/core/models/position_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Model Serialization Tests (Hive Compatibility)', () {
    test('User Model Serialization', () {
      final user = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      // Test toJson
      final json = user.toJson();
      expect(json['id'], equals('user123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['name'], equals('Test User'));
      expect(json['created_at'], isNotNull);

      // Test fromJson
      final userFromJson = User.fromJson(json);
      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.name, equals(user.name));
    });

    test('AuthResponse Model Serialization', () {
      final user = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final authResponse = AuthResponse(token: 'test_token_12345', user: user);

      // Test toJson
      final json = authResponse.toJson();
      expect(json['token'], equals('test_token_12345'));
      expect(json['user'], isA<Map>());
      expect(json['user']['id'], equals('user123'));

      // Test fromJson
      final authFromJson = AuthResponse.fromJson(json);
      expect(authFromJson.token, equals(authResponse.token));
      expect(authFromJson.user.id, equals(user.id));
    });

    test('PageWidget Model Serialization', () {
      final widget = PageWidget(
        id: 'widget1',
        type: 'Container',
        position: const Offset(10, 20),
        size: const Size(100, 100),
        properties: {'color': 'blue', 'opacity': 1.0},
        zIndex: 5,
        positionMode: PositionMode.absolute,
        isContainer: true,
      );

      // Test toJson
      final json = widget.toJson();
      expect(json['id'], equals('widget1'));
      expect(json['type'], equals('Container'));
      expect(json['position']['x'], equals(10.0));
      expect(json['position']['y'], equals(20.0));
      expect(json['size']['width'], equals(100.0));
      expect(json['size']['height'], equals(100.0));
      expect(json['zIndex'], equals(5));
      expect(json['positionMode'], equals('absolute'));
      expect(json['isContainer'], equals(true));
      expect(json['properties'], isA<Map>());

      // Test fromJson
      final widgetFromJson = PageWidget.fromJson(json);
      expect(widgetFromJson.id, equals(widget.id));
      expect(widgetFromJson.type, equals(widget.type));
      expect(widgetFromJson.position.dx, equals(10.0));
      expect(widgetFromJson.position.dy, equals(20.0));
      expect(widgetFromJson.size.width, equals(100.0));
      expect(widgetFromJson.size.height, equals(100.0));
      expect(widgetFromJson.zIndex, equals(5));
      expect(widgetFromJson.positionMode, equals(PositionMode.absolute));
      expect(widgetFromJson.isContainer, equals(true));
    });

    test('PageMetadata Model Serialization', () {
      final metadata = PageMetadata(
        width: 2000,
        height: 1500,
        backgroundColor: '#FFFFFF',
        gridSize: 10,
        showGrid: true,
        snapToGrid: false,
        zoom: 1.5,
      );

      // Test toJson
      final json = metadata.toJson();
      expect(json['width'], equals(2000.0));
      expect(json['height'], equals(1500.0));
      expect(json['backgroundColor'], equals('#FFFFFF'));
      expect(json['gridSize'], equals(10.0));
      expect(json['showGrid'], equals(true));
      expect(json['snapToGrid'], equals(false));
      expect(json['zoom'], equals(1.5));

      // Test fromJson
      final metadataFromJson = PageMetadata.fromJson(json);
      expect(metadataFromJson.width, equals(metadata.width));
      expect(metadataFromJson.height, equals(metadata.height));
      expect(
        metadataFromJson.backgroundColor,
        equals(metadata.backgroundColor),
      );
      expect(metadataFromJson.gridSize, equals(metadata.gridSize));
      expect(metadataFromJson.showGrid, equals(metadata.showGrid));
      expect(metadataFromJson.snapToGrid, equals(metadata.snapToGrid));
      expect(metadataFromJson.zoom, equals(metadata.zoom));
    });

    test('PageData Model Serialization', () {
      final pageData = PageData(
        pageId: 'page123',
        name: 'Test Page',
        version: 1,
        metadata: PageMetadata(),
        widgets: {
          'widget1': PageWidget(
            id: 'widget1',
            type: 'Container',
            position: const Offset(10, 20),
            size: const Size(100, 100),
            properties: {'color': 'blue'},
          ),
          'widget2': PageWidget(
            id: 'widget2',
            type: 'Text',
            position: const Offset(50, 60),
            size: const Size(200, 50),
            properties: {'text': 'Hello World'},
          ),
        },
      );

      // Test toJson
      final json = pageData.toJson();
      expect(json['pageId'], equals('page123'));
      expect(json['name'], equals('Test Page'));
      expect(json['version'], equals(1));
      expect(json['metadata'], isA<Map>());
      expect(json['widgets'], isA<List>());
      expect(json['widgets'].length, equals(2));

      // Test fromJson
      final pageDataFromJson = PageData.fromJson(json);
      expect(pageDataFromJson.pageId, equals(pageData.pageId));
      expect(pageDataFromJson.name, equals(pageData.name));
      expect(pageDataFromJson.version, equals(pageData.version));
      expect(pageDataFromJson.widgets.length, equals(2));
      expect(pageDataFromJson.widgetList[0].id, equals('widget1'));
      expect(pageDataFromJson.widgetList[1].id, equals('widget2'));
    });

    test('PageModel Complete Serialization', () {
      final now = DateTime.now();
      final page = PageModel(
        id: 'page123',
        name: 'Test Page',
        ownerId: 'user123',
        pageData: PageData(
          pageId: 'page123',
          name: 'Test Page',
          version: 1,
          metadata: PageMetadata(
            width: 2000,
            height: 2000,
            backgroundColor: '#FFFFFF',
            zoom: 1.0,
          ),
          widgets: {
            'widget1': PageWidget(
              id: 'widget1',
              type: 'Container',
              position: const Offset(10, 20),
              size: const Size(100, 100),
              properties: {'color': 'blue'},
            ),
          },
        ),
        version: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Test toJson
      final json = page.toJson();
      expect(json['id'], equals('page123'));
      expect(json['name'], equals('Test Page'));
      expect(json['ownerId'], equals('user123'));
      expect(json['version'], equals(1));
      expect(json['pageData'], isA<Map>());
      expect(json['pageData']['widgets'], isA<List>());
      expect(json['pageData']['widgets'].length, equals(1));
      expect(json['createdAt'], isNotNull);
      expect(json['updatedAt'], isNotNull);

      // Test fromJson
      final pageFromJson = PageModel.fromJson(json);
      expect(pageFromJson.id, equals(page.id));
      expect(pageFromJson.name, equals(page.name));
      expect(pageFromJson.ownerId, equals(page.ownerId));
      expect(pageFromJson.version, equals(page.version));
      expect(pageFromJson.pageData.widgets.length, equals(1));
      expect(pageFromJson.pageData.widgetList[0].id, equals('widget1'));
      expect(pageFromJson.createdAt, isA<DateTime>());
      expect(pageFromJson.updatedAt, isA<DateTime>());
    });
  });

  group('PositionMode Tests', () {
    test('PositionMode toJsonString', () {
      expect(PositionMode.absolute.toJsonString(), equals('absolute'));
      expect(PositionMode.relative.toJsonString(), equals('relative'));
      expect(PositionMode.fixed.toJsonString(), equals('fixed'));
    });

    test('PositionMode fromString', () {
      expect(
        PositionModeExtension.fromString('absolute'),
        equals(PositionMode.absolute),
      );
      expect(
        PositionModeExtension.fromString('relative'),
        equals(PositionMode.relative),
      );
      expect(
        PositionModeExtension.fromString('fixed'),
        equals(PositionMode.fixed),
      );
      expect(
        PositionModeExtension.fromString('invalid'),
        equals(PositionMode.absolute), // Default fallback
      );
      expect(
        PositionModeExtension.fromString(null),
        equals(PositionMode.absolute), // Default fallback
      );
    });
  });

  group('PageWidget Tests', () {
    test('PageWidget copyWith', () {
      final widget = PageWidget(
        id: 'widget1',
        type: 'Container',
        position: const Offset(10, 20),
        size: const Size(100, 100),
        properties: {'color': 'blue'},
        zIndex: 5,
      );

      // Test copyWith position
      final movedWidget = widget.copyWith(position: const Offset(50, 60));
      expect(movedWidget.position.dx, equals(50.0));
      expect(movedWidget.position.dy, equals(60.0));
      expect(movedWidget.id, equals(widget.id)); // Other properties unchanged

      // Test copyWith size
      final resizedWidget = widget.copyWith(size: const Size(200, 200));
      expect(resizedWidget.size.width, equals(200.0));
      expect(resizedWidget.size.height, equals(200.0));

      // Test copyWith zIndex
      final reorderedWidget = widget.copyWith(zIndex: 10);
      expect(reorderedWidget.zIndex, equals(10));
    });

    test('PageWidget isContainer Detection', () {
      final containerWidget = PageWidget(
        id: 'widget1',
        type: 'Container',
        position: const Offset(0, 0),
        size: const Size(100, 100),
        properties: {},
      );
      expect(containerWidget.isContainer, isTrue);

      final cardWidget = PageWidget(
        id: 'widget2',
        type: 'Card',
        position: const Offset(0, 0),
        size: const Size(100, 100),
        properties: {},
      );
      expect(cardWidget.isContainer, isTrue);

      final textWidget = PageWidget(
        id: 'widget3',
        type: 'Text',
        position: const Offset(0, 0),
        size: const Size(100, 100),
        properties: {},
      );
      expect(textWidget.isContainer, isFalse);
    });

    test('PageWidget with nesting', () {
      final parent = PageWidget(
        id: 'parent1',
        type: 'Container',
        position: const Offset(0, 0),
        size: const Size(400, 400),
        properties: {},
        isContainer: true,
        childrenIds: ['child1', 'child2'],
      );

      expect(parent.isContainer, isTrue);
      expect(parent.childrenIds.length, equals(2));
      expect(parent.parentId, isNull);

      final child = PageWidget(
        id: 'child1',
        type: 'Text',
        position: const Offset(10, 10),
        size: const Size(100, 50),
        properties: {},
        parentId: 'parent1',
        positionMode: PositionMode.relative,
      );

      expect(child.parentId, equals('parent1'));
      expect(child.positionMode, equals(PositionMode.relative));
    });
  });

  group('User Model Tests', () {
    test('User copyWith', () {
      final user = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(name: 'Updated Name');
      expect(updatedUser.name, equals('Updated Name'));
      expect(updatedUser.id, equals(user.id));
      expect(updatedUser.email, equals(user.email));
    });

    test('User Equatable props', () {
      final now = DateTime.now();
      final user1 = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: now,
      );

      final user2 = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: now,
      );

      expect(user1, equals(user2)); // Equatable comparison
    });
  });

  group('PageMetadata Tests', () {
    test('PageMetadata copyWith', () {
      final metadata = PageMetadata(width: 2000, height: 1500, zoom: 1.0);

      final zoomedMetadata = metadata.copyWith(zoom: 1.5);
      expect(zoomedMetadata.zoom, equals(1.5));
      expect(zoomedMetadata.width, equals(metadata.width));
      expect(zoomedMetadata.height, equals(metadata.height));
    });

    test('PageMetadata defaults', () {
      final metadata = PageMetadata();
      expect(metadata.width, equals(2000.0));
      expect(metadata.height, equals(2000.0));
      expect(metadata.backgroundColor, equals('#FFFFFF'));
      expect(metadata.gridSize, equals(10.0));
      expect(metadata.showGrid, equals(true));
      expect(metadata.snapToGrid, equals(false));
      expect(metadata.zoom, equals(1.0));
    });
  });
}
