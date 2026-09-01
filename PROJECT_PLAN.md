# 🚀 Full-Stack Canvas Editor - Complete Implementation Plan

## Project Overview
A complete **Flutter frontend** + **Node.js backend** solution for a collaborative canvas editor with:
- **Split-panel interface** (Widget Library | Canvas | Properties Panel)
- **Drag-and-drop widgets** with real-time updates
- **Server synchronization** via WebSocket for collaboration
- **Properties panel** for editing width, height, background color, and position
- **Real-time collaboration** with cursor tracking and presence indicators

---

## 📁 Monorepo Structure

```
SyncEditor/
├── README.md
├── docker-compose.yml
├── .gitignore
├── .env.example
│
├── frontend/                          # Flutter Application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── api/
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── websocket_client.dart
│   │   │   │   └── endpoints.dart
│   │   │   ├── models/
│   │   │   │   ├── widget_node.dart
│   │   │   │   ├── canvas_state.dart
│   │   │   │   └── user.dart
│   │   │   └── services/
│   │   │       ├── auth_service.dart
│   │   │       └── sync_service.dart
│   │   ├── features/
│   │   │   ├── canvas/
│   │   │   │   ├── bloc/
│   │   │   │   ├── views/
│   │   │   │   └── widgets/
│   │   │   ├── widget_library/
│   │   │   │   ├── bloc/
│   │   │   │   └── views/
│   │   │   ├── properties/
│   │   │   │   ├── bloc/
│   │   │   │   └── views/
│   │   │   └── auth/
│   │   │       ├── bloc/
│   │   │       └── views/
│   │   └── editor/
│   │       └── editor_screen.dart
│   ├── pubspec.yaml
│   └── test/
│
├── backend/                           # Node.js + Express API
│   ├── src/
│   │   ├── server.ts
│   │   ├── app.ts
│   │   ├── controllers/
│   │   │   ├── auth.controller.ts
│   │   │   ├── canvas.controller.ts
│   │   │   └── widget.controller.ts
│   │   ├── models/
│   │   │   ├── User.ts
│   │   │   ├── Canvas.ts
│   │   │   └── Widget.ts
│   │   ├── routes/
│   │   │   ├── auth.routes.ts
│   │   │   ├── canvas.routes.ts
│   │   │   └── widget.routes.ts
│   │   ├── services/
│   │   │   ├── canvas.service.ts
│   │   │   ├── widget.service.ts
│   │   │   └── sync.service.ts
│   │   ├── websocket/
│   │   │   ├── socket.handler.ts
│   │   │   └── events.ts
│   │   └── middleware/
│   │       ├── auth.middleware.ts
│   │       ├── validation.middleware.ts
│   │       └── error.middleware.ts
│   ├── package.json
│   ├── tsconfig.json
│   └── tests/
│
├── database/
│   ├── migrations/
│   │   ├── 001_create_users_table.sql
│   │   ├── 002_create_canvases_table.sql
│   │   └── 003_create_widgets_table.sql
│   └── schema.sql
│
└── deployment/
    ├── docker/
    │   ├── Dockerfile.backend
    │   └── Dockerfile.frontend
    └── scripts/
        └── setup.sh
```

---

## 1. Architecture Overview

### Core Components
```
lib/
├── main.dart
├── core/
│   ├── models/
│   │   ├── widget_node.dart           # Base widget model
│   │   ├── canvas_state.dart          # Canvas state model
│   │   └── sync_payload.dart          # Server sync data structure
│   ├── services/
│   │   ├── sync_service.dart          # WebSocket/HTTP sync handler
│   │   ├── canvas_storage.dart        # Local persistence
│   │   └── widget_factory.dart        # Widget creation factory
│   ├── utils/
│   │   ├── id_generator.dart          # Unique ID generation
│   │   └── position_calculator.dart   # Layout calculations
│   └── constants/
│       └── widget_types.dart          # Available widget types
├── features/
│   ├── canvas/
│   │   ├── bloc/
│   │   │   ├── canvas_bloc.dart       # Canvas state management
│   │   │   ├── canvas_event.dart
│   │   │   └── canvas_state.dart
│   │   ├── views/
│   │   │   ├── canvas_view.dart       # Main canvas area
│   │   │   ├── canvas_widget.dart     # Individual canvas widgets
│   │   │   └── canvas_overlay.dart    # Selection/transform overlay
│   │   └── widgets/
│   │       ├── drop_target.dart       # Drop zone handler
│   │       └── transform_handle.dart  # Resize/move handles
│   ├── widget_library/
│   │   ├── bloc/
│   │   │   ├── widget_library_bloc.dart
│   │   │   ├── widget_library_event.dart
│   │   │   └── widget_library_state.dart
│   │   ├── views/
│   │   │   ├── widget_library_panel.dart  # Left sidebar
│   │   │   ├── widget_category.dart       # Category sections
│   │   │   └── widget_item.dart           # Draggable widget item
│   │   └── models/
│   │       └── widget_definition.dart     # Widget metadata
│   ├── properties/
│   │   ├── bloc/
│   │   │   ├── properties_bloc.dart   # Property editor state
│   │   │   ├── properties_event.dart
│   │   │   └── properties_state.dart
│   │   └── views/
│   │       ├── properties_panel.dart  # Optional properties panel
│   │       └── property_editor.dart   # Individual property editors
│   └── sync/
│       ├── bloc/
│       │   ├── sync_bloc.dart         # Sync state management
│       │   ├── sync_event.dart
│       │   └── sync_state.dart
│       └── services/
│           ├── websocket_client.dart  # Real-time sync
│           └── conflict_resolver.dart # Handle sync conflicts
└── editor/
    └── editor_screen.dart             # Main split view container
```

---

## 2. Feature Specifications

### 2.1 Split Panel Layout

#### Left Panel - Widget Library
- **Width**: 280px (configurable)
- **Collapsible**: Yes, with toggle button
- **Scrollable**: Vertical scroll for widget categories
- **Search**: Filter widgets by name/category
- **Categories**:
  - Layout (Container, Row, Column, Stack)
  - Basic (Text, Image, Icon, Button)
  - Input (TextField, Checkbox, Radio, Switch)
  - Display (Card, List, Grid)
  - Custom (User-defined components)

#### Right Panel - Canvas
- **Infinite Canvas**: With zoom (50% - 200%) and pan
- **Grid System**: Optional snap-to-grid (configurable spacing)
- **Rulers**: Top and left rulers for measurements
- **Background**: Customizable (solid color, pattern, image)
- **Transform Controls**:
  - Selection overlay with handles
  - Resize (8 corner/edge handles)
  - Rotate (rotation handle)
  - Multi-select (Shift/Ctrl + click)

#### Panel Divider
- Resizable splitter
- Minimum widths: Left (200px), Right (400px)
- Persist user's preferred split ratio

---

### 2.2 Drag & Drop System

#### From Widget Library to Canvas
```dart
// Flow:
1. User drags widget from library
2. Widget shows feedback (semi-transparent preview)
3. Canvas highlights drop zones
4. On drop:
   - Generate unique ID
   - Calculate position
   - Create widget node
   - Add to canvas state
   - Trigger sync to server
```

#### Within Canvas
```dart
// Reordering and repositioning:
1. User drags widget on canvas
2. Show position guides (alignment, spacing)
3. On drop:
   - Update widget position
   - Update z-index if needed
   - Trigger sync to server
```

#### Drag Constraints
- Prevent widgets from being dragged outside canvas bounds
- Optional snap-to-grid during drag
- Smart guides for alignment with other widgets

---

### 2.3 Server Synchronization

#### Architecture Pattern: **Optimistic UI Updates**

```dart
// Sync Flow:
1. User action (add/move/delete widget)
   ↓
2. Update local state immediately (BLoC)
   ↓
3. Queue sync operation
   ↓
4. Send to server (WebSocket/HTTP)
   ↓
5. Server responds:
   - Success: Confirm operation
   - Failure: Rollback + show error
   ↓
6. Broadcast to other clients (if collaborative)
```

#### Sync Protocols

**Option A: WebSocket (Recommended for real-time)**
```dart
// Use: web_socket_channel package
- Persistent connection
- Bidirectional communication
- Low latency (~10-50ms)
- Best for collaborative editing
```

**Option B: HTTP REST API (Simpler)**
```dart
// Use: http or dio package
- Request/response model
- Polling for updates (every 2-5s)
- Higher latency (~500ms-2s)
- Simpler to implement
```

#### Sync Data Structure
```dart
class SyncPayload {
  String operationType; // 'add', 'update', 'delete', 'bulk'
  String widgetId;
  Map<String, dynamic>? widgetData;
  String userId;
  DateTime timestamp;
  int version; // For conflict resolution
}
```

#### Conflict Resolution
```dart
// Strategies:
1. Last-Write-Wins (simple)
2. Operational Transformation (complex, collaborative)
3. Version-based (increment version on each change)
```

#### Sync States
- **Synced**: All changes saved to server
- **Syncing**: Operation in progress (show spinner)
- **Failed**: Retry with exponential backoff
- **Offline**: Queue operations, sync when online

---

## 3. Data Models

### Widget Node Model
```dart
class WidgetNode {
  String id;                    // Unique identifier
  String type;                  // 'Container', 'Text', etc.
  String? parentId;             // For nested widgets
  List<String> childrenIds;     // Child widget IDs
  
  // Position & Size
  Offset position;              // x, y coordinates
  Size size;                    // width, height
  double rotation;              // Rotation angle
  int zIndex;                   // Stacking order
  
  // Visual Properties
  Color? backgroundColor;
  BoxBorder? border;
  BorderRadius? borderRadius;
  EdgeInsets? padding;
  EdgeInsets? margin;
  
  // Widget-Specific Props
  Map<String, dynamic> properties; // Type-specific data
  
  // State
  bool isSelected;
  bool isLocked;
  bool isVisible;
  
  // Sync
  DateTime lastModified;
  int version;
  String? serverId;             // ID from server
}
```

### Canvas State Model
```dart
class CanvasState {
  String canvasId;
  List<WidgetNode> widgets;
  WidgetNode? selectedWidget;
  List<String> selectedWidgetIds; // Multi-select
  
  // Canvas Settings
  Color backgroundColor;
  bool showGrid;
  double gridSize;
  double zoom;
  Offset panOffset;
  
  // Sync Status
  SyncStatus syncStatus;
  DateTime? lastSyncTime;
  Queue<SyncOperation> pendingOperations;
}
```

---

## 4. Technical Stack

### Core Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Networking
  web_socket_channel: ^2.4.0    # WebSocket
  dio: ^5.3.3                   # HTTP client
  
  # Storage
  hive: ^2.2.3                  # Local storage
  hive_flutter: ^1.1.0
  
  # Utilities
  uuid: ^4.0.0                  # ID generation
  intl: ^0.18.1                 # Formatting
  collection: ^1.18.0           # Data structures
  
  # UI
  flutter_svg: ^2.0.9           # SVG support
  provider: ^6.0.5              # Dependency injection
  
dev_dependencies:
  flutter_test: sdk: flutter
  bloc_test: ^9.1.4             # BLoC testing
  mockito: ^5.4.2               # Mocking
  build_runner: ^2.4.6          # Code generation
  hive_generator: ^2.0.1        # Hive adapters
```

---

## 5. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Project setup with folder structure
- [ ] Install dependencies
- [ ] Create data models (WidgetNode, CanvasState)
- [ ] Implement BLoC architecture skeleton
- [ ] Setup Hive for local storage

### Phase 2: Canvas Core (Week 2)
- [ ] Build main split-panel layout
- [ ] Implement resizable divider
- [ ] Create canvas view with zoom/pan
- [ ] Add grid and ruler overlays
- [ ] Implement selection system

### Phase 3: Widget Library (Week 3)
- [ ] Design widget library UI
- [ ] Create widget category structure
- [ ] Implement search and filtering
- [ ] Build draggable widget items
- [ ] Add widget preview icons

### Phase 4: Drag & Drop (Week 4)
- [ ] Implement drag from library to canvas
- [ ] Add drop target zones
- [ ] Create drag feedback widgets
- [ ] Implement within-canvas dragging
- [ ] Add snap-to-grid functionality

### Phase 5: Widget Manipulation (Week 5)
- [ ] Build transform handles (resize, rotate)
- [ ] Implement multi-select
- [ ] Add keyboard shortcuts (Delete, Copy, Paste)
- [ ] Create undo/redo system
- [ ] Add widget properties editor

### Phase 6: Server Sync (Week 6)
- [ ] Setup WebSocket/HTTP client
- [ ] Implement sync service
- [ ] Add optimistic UI updates
- [ ] Create conflict resolution
- [ ] Build retry mechanism with exponential backoff

### Phase 7: Polish & Testing (Week 7)
- [ ] Performance optimization
- [ ] Error handling and edge cases
- [ ] Unit tests for BLoCs
- [ ] Integration tests
- [ ] UI/UX refinements

---

## 6. Server Synchronization Implementation

### 6.1 WebSocket Approach (Recommended)

#### Client-Side
```dart
class SyncService {
  final WebSocketChannel channel;
  final CanvasBloc canvasBloc;
  
  void connect() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://your-server.com/canvas-sync')
    );
    
    // Listen to server messages
    channel.stream.listen((message) {
      final payload = jsonDecode(message);
      _handleServerUpdate(payload);
    });
  }
  
  void syncOperation(SyncPayload payload) {
    channel.sink.add(jsonEncode(payload.toJson()));
  }
  
  void _handleServerUpdate(Map<String, dynamic> data) {
    // Apply remote changes to local state
    canvasBloc.add(RemoteUpdateEvent(data));
  }
}
```

#### Server Requirements (Node.js/Python/Go)
```javascript
// Pseudo-code for server
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const canvases = {}; // In-memory or database

wss.on('connection', (ws) => {
  ws.on('message', (message) => {
    const payload = JSON.parse(message);
    
    // Save to database
    saveCanvasChange(payload);
    
    // Broadcast to all connected clients
    wss.clients.forEach((client) => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  });
});
```

### 6.2 HTTP Approach (Simpler)

```dart
class SyncService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://your-api.com',
    connectTimeout: Duration(seconds: 5),
  ));
  
  Future<void> syncCanvas(CanvasState state) async {
    try {
      await dio.post('/canvas/sync', data: {
        'canvasId': state.canvasId,
        'widgets': state.widgets.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle error, queue for retry
      throw SyncException(e.toString());
    }
  }
  
  Future<CanvasState> fetchCanvas(String canvasId) async {
    final response = await dio.get('/canvas/$canvasId');
    return CanvasState.fromJson(response.data);
  }
}
```

### 6.3 Sync Strategies

#### Debouncing
```dart
// Avoid excessive sync calls
Timer? _syncTimer;

void queueSync(CanvasState state) {
  _syncTimer?.cancel();
  _syncTimer = Timer(Duration(milliseconds: 500), () {
    _performSync(state);
  });
}
```

#### Batching
```dart
// Group multiple operations
List<SyncOperation> _pendingOps = [];

void addOperation(SyncOperation op) {
  _pendingOps.add(op);
  
  if (_pendingOps.length >= 10 || _shouldFlush()) {
    _flushOperations();
  }
}

void _flushOperations() {
  syncService.batchSync(_pendingOps);
  _pendingOps.clear();
}
```

---

## 7. Key Features from Reference Project

Based on your reference project (`website_builder_flutter`), here are key patterns to adopt:

### 7.1 Canvas Structure
```dart
// Similar to QMainCanvas
- Nested widget hierarchy (parent-child relationships)
- Position types: static, absolute, fixed
- Transform controls with handles
- Grid snapping system
```

### 7.2 Left Panel Structure
```dart
// Similar to EditorLeftPanel
- Categorized widget sections
- Icon-based navigation
- Collapsible panels
- Search functionality
- Tooltip on hover
```

### 7.3 BLoC Pattern
```dart
// Events
- AddWidgetEvent
- UpdateWidgetEvent
- DeleteWidgetEvent
- SelectWidgetEvent
- MoveWidgetEvent

// States
- CanvasLoadingState
- CanvasLoadedState
- CanvasErrorState
- CanvasSyncingState
```

### 7.4 Drag & Drop System
```dart
// Use Flutter's built-in Draggable and DragTarget
Draggable<WidgetDefinition>(
  data: widgetDef,
  feedback: WidgetPreview(widgetDef),
  child: WidgetLibraryItem(widgetDef),
)

DragTarget<WidgetDefinition>(
  onAcceptWithDetails: (details) {
    _addWidgetToCanvas(details.data, details.offset);
  },
  builder: (context, candidates, rejects) {
    return CanvasArea(
      highlighting: candidates.isNotEmpty,
    );
  },
)
```

---

## 8. Sample Implementation Code

### Main Editor Screen
```dart
class EditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Widget Library
          WidgetLibraryPanel(width: 280),
          
          // Resizable Divider
          ResizableDivider(),
          
          // Right Panel - Canvas
          Expanded(
            child: CanvasView(),
          ),
        ],
      ),
    );
  }
}
```

### Canvas BLoC
```dart
class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  final SyncService syncService;
  
  CanvasBloc(this.syncService) : super(CanvasInitial()) {
    on<AddWidgetEvent>(_onAddWidget);
    on<UpdateWidgetEvent>(_onUpdateWidget);
    on<DeleteWidgetEvent>(_onDeleteWidget);
    on<SyncCompleteEvent>(_onSyncComplete);
  }
  
  Future<void> _onAddWidget(
    AddWidgetEvent event,
    Emitter<CanvasState> emit,
  ) async {
    final currentState = state as CanvasLoaded;
    
    // 1. Optimistic update
    final newWidget = WidgetNode(
      id: Uuid().v4(),
      type: event.widgetType,
      position: event.position,
      size: event.size,
      // ... other properties
    );
    
    emit(currentState.copyWith(
      widgets: [...currentState.widgets, newWidget],
      syncStatus: SyncStatus.syncing,
    ));
    
    // 2. Sync to server
    try {
      await syncService.syncOperation(SyncPayload(
        operationType: 'add',
        widgetId: newWidget.id,
        widgetData: newWidget.toJson(),
        timestamp: DateTime.now(),
      ));
      
      emit(currentState.copyWith(
        syncStatus: SyncStatus.synced,
      ));
    } catch (e) {
      // Rollback on failure
      emit(currentState.copyWith(
        widgets: currentState.widgets.where((w) => w.id != newWidget.id).toList(),
        syncStatus: SyncStatus.failed,
        error: e.toString(),
      ));
    }
  }
}
```

---

## 9. Testing Strategy

### Unit Tests
```dart
// Test BLoCs
- Widget addition/removal
- Selection logic
- Sync operation queueing

// Test Services
- Sync service connectivity
- Conflict resolution
- Error handling
```

### Integration Tests
```dart
// Test Flows
- Drag widget from library to canvas
- Resize and move widgets
- Multi-select and delete
- Sync after offline period
```

### Performance Tests
```dart
// Benchmarks
- Canvas rendering with 100+ widgets
- Sync latency measurement
- Memory usage monitoring
```

---

## 10. Performance Considerations

### Optimization Techniques
1. **Widget Virtualization**: Only render visible canvas widgets
2. **Debounced Sync**: Batch rapid changes before syncing
3. **Lazy Loading**: Load widget library items on-demand
4. **Isolates**: Offload JSON parsing to background isolate
5. **Canvas Caching**: Cache static canvas layers

### Memory Management
- Dispose BLoC instances properly
- Clear image cache when widgets deleted
- Limit undo/redo history (e.g., 50 operations)

---

## 11. Error Handling

### Client-Side Errors
- Network timeout → Retry with backoff
- Invalid widget data → Show validation error
- Sync conflict → Offer merge/override options

### Server-Side Errors
- 401 Unauthorized → Redirect to login
- 500 Server Error → Queue operation, retry later
- 409 Conflict → Trigger conflict resolution UI

---

## 12. Future Enhancements

### Phase 2 Features
- [ ] Real-time collaboration (multiple cursors)
- [ ] Version history and time-travel debugging
- [ ] Widget grouping and components
- [ ] Custom widget creation
- [ ] Export to code (Flutter/React/HTML)
- [ ] Templates and presets
- [ ] Keyboard shortcuts
- [ ] Accessibility features

---

## 13. Deliverables

### Code Deliverables
1. Complete Flutter project with source code
2. BLoC implementation for all features
3. Sync service with WebSocket/HTTP
4. Unit and integration tests

### Documentation
1. README with setup instructions
2. API documentation for server endpoints
3. Architecture decision records (ADRs)
4. User guide for canvas editor

### Assets
1. Widget icons for library
2. UI mockups and designs
3. Demo video showing features

---

## 14. References

### Reference Project Analysis
Your `website_builder_flutter` project provides excellent patterns:

1. **Canvas System** (`q_main_canvas.dart`):
   - Nested widget hierarchy
   - Position types (static/absolute/fixed)
   - Drag target implementation
   - Section-based layout

2. **Left Panel** (`editor_left_panel.dart`):
   - Icon-based navigation with tooltips
   - State management with BLoC
   - Collapsible sections
   - Category organization

3. **Editor View** (`editor_view.dart`):
   - Split panel layout
   - Zoom and pan controls
   - Grid system
   - Transform handles

### Key Patterns to Adopt
- BLoC pattern for state management
- Draggable/DragTarget for drag-and-drop
- ValueNotifier for simple state
- Factory pattern for widget creation
- Repository pattern for data access

---

## 15. Getting Started

### Quick Start Commands
```bash
# Create new Flutter project
flutter create sync_editor
cd sync_editor

# Add dependencies
flutter pub add flutter_bloc equatable web_socket_channel dio hive hive_flutter uuid

# Create folder structure
mkdir -p lib/core/{models,services,utils,constants}
mkdir -p lib/features/{canvas,widget_library,properties,sync}/{bloc,views,widgets}

# Run project
flutter run -d chrome  # For web
flutter run            # For mobile
```

### Next Steps
1. Review this plan with team
2. Setup development environment
3. Create project scaffold
4. Begin Phase 1 implementation
5. Setup CI/CD pipeline

---

## Contact & Support
For questions or clarifications, please reach out to the development team.

**Last Updated**: 2026-08-26  
**Version**: 1.0  
**Status**: Ready for Implementation
