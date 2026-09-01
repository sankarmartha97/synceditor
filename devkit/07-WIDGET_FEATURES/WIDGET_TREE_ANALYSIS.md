# Widget Tree Analysis - Current State & Nested Widget Support

## 📊 Current Implementation

### Widget Structure (Flat List):
```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> properties;
  // ❌ NO parent_id or children field
}
```

### Current Widget Storage:
```json
{
  "widgets": [
    { "id": "widget-1", "type": "Container", "position": {...}, "size": {...} },
    { "id": "widget-2", "type": "Button", "position": {...}, "size": {...} },
    { "id": "widget-3", "type": "Text", "position": {...}, "size": {...} }
  ]
}
```

**Problem**: All widgets are stored in a **flat list** with no hierarchy.

---

## 🎯 Required: Widget Tree (Nested Structure)

### What You Need:

#### 1. **Multi-Widget Containers**
Widgets that can contain other widgets:
- **Container** → Can hold multiple children
- **Card** → Can hold content widgets
- **Row/Column** → Layout widgets with children
- **Stack** → Overlapping widgets

#### 2. **Single Widgets**
Widgets that don't contain children:
- **Text** → Just text content
- **Button** → Standalone button
- **Image** → Single image

#### 3. **Nesting Capability**
- Single widget can be placed **inside** multi-widget container
- Multi-widget can contain other multi-widgets
- Example: Container → Card → Button

---

## 🏗️ Proposed Solution

### Enhanced PageWidget Model:

```dart
class PageWidget {
  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> properties;
  
  // NEW FIELDS for nesting:
  final String? parentId;              // Parent widget ID (null = root level)
  final List<String>? childrenIds;     // List of child widget IDs
  final bool isContainer;              // Can this widget contain children?
  
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;
}
```

### Widget Tree Structure:

```json
{
  "widgets": [
    {
      "id": "container-1",
      "type": "Container",
      "position": { "x": 100, "y": 100 },
      "size": { "width": 400, "height": 400 },
      "parentId": null,
      "childrenIds": ["card-1", "button-1"],
      "isContainer": true,
      "properties": { "color": "#FFFFFF" }
    },
    {
      "id": "card-1",
      "type": "Card",
      "position": { "x": 20, "y": 20 },
      "size": { "width": 200, "height": 150 },
      "parentId": "container-1",
      "childrenIds": ["text-1"],
      "isContainer": true,
      "properties": { "color": "#F5F5F5" }
    },
    {
      "id": "text-1",
      "type": "Text",
      "position": { "x": 10, "y": 10 },
      "size": { "width": 180, "height": 50 },
      "parentId": "card-1",
      "childrenIds": [],
      "isContainer": false,
      "properties": { "text": "Hello World" }
    },
    {
      "id": "button-1",
      "type": "Button",
      "position": { "x": 240, "y": 20 },
      "size": { "width": 140, "height": 50 },
      "parentId": "container-1",
      "childrenIds": [],
      "isContainer": false,
      "properties": { "text": "Click Me" }
    }
  ]
}
```

### Visual Representation:

```
Container (container-1)
├── Card (card-1)
│   └── Text (text-1) "Hello World"
└── Button (button-1) "Click Me"
```

---

## 🎨 Widget Types Classification

### Multi-Widget (Containers):
```dart
const multiWidgetTypes = [
  'Container',
  'Card',
  'Row',
  'Column',
  'Stack',
  'ListView',
  'GridView',
];
```

### Single-Widget (Leaf Nodes):
```dart
const singleWidgetTypes = [
  'Text',
  'Button',
  'Image',
  'Icon',
  'TextField',
  'Checkbox',
  'Radio',
];
```

---

## 🔄 Placement Rules

### Rule 1: Root Level Placement
Any widget can be placed at root level (parentId = null):
```
✅ Container → root
✅ Button → root
✅ Text → root
```

### Rule 2: Single Widget → Multi-Widget
Single widgets can be placed inside containers:
```
✅ Container → Button
✅ Card → Text
✅ Stack → Image
```

### Rule 3: Multi-Widget → Multi-Widget
Containers can be nested:
```
✅ Container → Card
✅ Card → Container
✅ Stack → Column → Row
```

### Rule 4: Invalid Placements
Single widgets CANNOT contain children:
```
❌ Button → Text (Button is not a container)
❌ Image → Button (Image is not a container)
❌ Text → Container (Text is not a container)
```

---

## 🛠️ Implementation Changes Needed

### 1. Update PageWidget Model
```dart
class PageWidget {
  // ... existing fields ...
  
  final String? parentId;
  final List<String> childrenIds;
  final bool isContainer;
  
  PageWidget({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.properties,
    this.parentId,
    List<String>? childrenIds,
    bool? isContainer,
    // ... other fields ...
  }) : childrenIds = childrenIds ?? [],
       isContainer = isContainer ?? _isContainerType(type);
  
  static bool _isContainerType(String type) {
    return ['Container', 'Card', 'Row', 'Column', 'Stack'].contains(type);
  }
}
```

### 2. Update Widget Rendering
```dart
Widget _buildWidget(BuildContext context, PageWidget widget, PageState state) {
  // Calculate absolute position (parent position + relative position)
  final absolutePosition = _calculateAbsolutePosition(widget, state.currentPage!.pageData.widgets);
  
  return Positioned(
    left: absolutePosition.dx,
    top: absolutePosition.dy,
    child: // ... widget content with nested children
  );
}

Offset _calculateAbsolutePosition(PageWidget widget, List<PageWidget> allWidgets) {
  if (widget.parentId == null) {
    return widget.position; // Root level widget
  }
  
  // Find parent and add its position
  final parent = allWidgets.firstWhere((w) => w.id == widget.parentId);
  final parentPosition = _calculateAbsolutePosition(parent, allWidgets);
  
  return Offset(
    parentPosition.dx + widget.position.dx,
    parentPosition.dy + widget.position.dy,
  );
}
```

### 3. Add Drop Target for Containers
```dart
Widget _buildContainerWidget(PageWidget widget, List<PageWidget> children) {
  return DragTarget<PageWidget>(
    onWillAccept: (data) => widget.isContainer, // Only accept if container
    onAccept: (droppedWidget) {
      // Update droppedWidget.parentId = widget.id
      // Update widget.childrenIds.add(droppedWidget.id)
      _handleNestedDrop(widget, droppedWidget);
    },
    builder: (context, candidateData, rejectedData) {
      return Stack(
        children: [
          // Container background
          _buildWidgetContent(widget),
          // Render children
          ...children.map((child) => _buildWidget(context, child, state)),
        ],
      );
    },
  );
}
```

### 4. Add Widget Tree Helper Functions
```dart
// Get all children of a widget
List<PageWidget> getChildren(String widgetId, List<PageWidget> allWidgets) {
  return allWidgets.where((w) => w.parentId == widgetId).toList();
}

// Get parent of a widget
PageWidget? getParent(String widgetId, List<PageWidget> allWidgets) {
  final widget = allWidgets.firstWhere((w) => w.id == widgetId);
  if (widget.parentId == null) return null;
  return allWidgets.firstWhere((w) => w.id == widget.parentId);
}

// Get all descendants (recursive)
List<PageWidget> getDescendants(String widgetId, List<PageWidget> allWidgets) {
  final children = getChildren(widgetId, allWidgets);
  final descendants = <PageWidget>[];
  
  for (final child in children) {
    descendants.add(child);
    descendants.addAll(getDescendants(child.id, allWidgets));
  }
  
  return descendants;
}

// Check if widget can accept children
bool canAcceptChildren(String widgetType) {
  return ['Container', 'Card', 'Row', 'Column', 'Stack'].contains(widgetType);
}
```

---

## 🎯 UI/UX Changes

### 1. Widget Library
Add visual indicator for container widgets:
```dart
ListTile(
  leading: Icon(item.icon),
  title: Text(item.name),
  trailing: item.isContainer 
    ? Chip(label: Text('Container'))  // Show "Container" badge
    : null,
)
```

### 2. Canvas Drop Zones
- **Root Canvas**: Blue dashed border when dragging
- **Container Widgets**: Green dashed border when hovering
- **Single Widgets**: Red indicator (cannot drop here)

### 3. Widget Tree Panel (New)
Add a tree view showing widget hierarchy:
```
📦 Page
├── 📦 Container (container-1)
│   ├── 🎴 Card (card-1)
│   │   └── 📝 Text (text-1)
│   └── 🔘 Button (button-1)
└── 📝 Text (text-2)
```

### 4. Properties Panel
Show parent info:
```
Widget: Button
Parent: Container (container-1)
Position: Relative to parent
  X: 20px
  Y: 30px
```

---

## 📋 Backend Changes

### Database Schema (Already Supports It!):
The database `widgets` table in the old architecture had `parent_id`:
```sql
CREATE TABLE widgets (
  id UUID PRIMARY KEY,
  canvas_id UUID,
  type VARCHAR(50),
  parent_id UUID REFERENCES widgets(id) ON DELETE CASCADE,  -- ✅ Already has this!
  position JSONB,
  size JSONB,
  properties JSONB
);
```

### New Page Data Structure:
Since you're using JSONB `page_data`, you just need to update the widget JSON:
```json
{
  "widgets": [
    {
      "id": "widget-1",
      "parentId": null,           // NEW
      "childrenIds": ["widget-2"], // NEW
      "isContainer": true,         // NEW
      // ... rest of fields
    }
  ]
}
```

---

## 🚀 Implementation Steps

### Phase 1: Data Model (1-2 hours)
1. ✅ Update `PageWidget` model with `parentId`, `childrenIds`, `isContainer`
2. ✅ Add helper functions for tree operations
3. ✅ Update JSON serialization/deserialization

### Phase 2: Rendering (2-3 hours)
1. ✅ Implement recursive widget rendering
2. ✅ Calculate absolute positions for nested widgets
3. ✅ Add drop target for container widgets
4. ✅ Update drag feedback to show nesting capability

### Phase 3: UI/UX (2-3 hours)
1. ✅ Add container indicators in widget library
2. ✅ Add drop zone visual feedback
3. ✅ Create widget tree panel (optional)
4. ✅ Update properties panel to show parent info

### Phase 4: Sync & Backend (1-2 hours)
1. ✅ Test JSON Patch with nested structure
2. ✅ Ensure OT handles parent-child updates
3. ✅ Test multi-user nested widget editing

---

## 📊 Summary

### Current State:
❌ Flat widget list  
❌ No parent-child relationships  
❌ Cannot nest widgets  
❌ All widgets are at root level  

### After Implementation:
✅ Hierarchical widget tree  
✅ Parent-child relationships  
✅ Nested widget support  
✅ Container widgets can hold children  
✅ Single widgets placed inside containers  
✅ Recursive rendering  
✅ Real-time sync for nested structures  

### Benefits:
1. **More Powerful**: Build complex UIs like Figma
2. **Better Organization**: Group related widgets
3. **Reusability**: Move container with all children at once
4. **Professional**: Industry-standard widget tree approach
5. **Sync-Friendly**: JSON Patch works perfectly with nested JSON

---

## 🎯 Next Steps

**Do you want me to implement nested widget support?**

This would allow:
- Containers to hold multiple widgets
- Dragging widgets into containers
- Moving entire widget trees
- Professional widget hierarchy like Figma/Framer

**Estimated Time**: 6-10 hours of development
**Impact**: Major feature enhancement
**Complexity**: Medium (requires careful state management)
