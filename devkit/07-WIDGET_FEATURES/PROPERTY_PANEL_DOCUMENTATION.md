# Property Panel - Enhanced Editable Properties with Real-Time Sync

## 📋 Overview

The **Property Panel** is a crucial UI component in SyncEditor that allows users to view and edit properties of selected widgets in real-time. All changes are automatically synchronized across all connected users through WebSocket connections.

---

## ✨ Features

### 1. **Real-Time Editing**
- Edit widget position (X, Y coordinates)
- Edit widget size (Width, Height)
- Edit custom widget properties
- All changes sync instantly with other users

### 2. **Type-Aware Property Inputs**
The panel automatically renders appropriate input controls based on property types:
- **Numbers**: Text input with validation
- **Booleans**: Toggle switches
- **Colors**: Color preview with hex value
- **Strings**: Text input fields

### 3. **Sync Indicators**
- Loading spinner shows when changes are being synced
- Green success message indicates real-time sync is active
- No manual "Save" button needed - everything auto-saves

### 4. **Input Validation**
- Position: Any numeric value (can be negative)
- Size: Minimum 10px, Maximum 2000px
- Number inputs: Allows decimals and negative values
- Invalid inputs revert to previous values

---

## 🎯 How It Works

### Architecture Flow:

```
User edits property
    ↓
Update local state (optimistic update)
    ↓
Dispatch UpdateWidgetInPage event
    ↓
PageBloc handles event
    ↓
Generate JSON Patch (difference)
    ↓
Send patch via WebSocket
    ↓
Backend applies OT (Operational Transformation)
    ↓
Broadcast to all connected users
    ↓
Other users receive patch
    ↓
Apply patch to their local state
    ↓
UI updates automatically
```

---

## 🔧 Component Structure

### File Location:
```
frontend/lib/features/properties/views/properties_panel.dart
```

### Key Components:

#### 1. **PropertiesPanel** (StatefulWidget)
- Main container for property editing
- Manages text field controllers
- Handles property updates

#### 2. **Text Field Controllers**
```dart
final Map<String, TextEditingController> _controllers = {};
```
- Dynamically created for each editable field
- Properly disposed when widget is destroyed
- Synced with incoming updates from other users

#### 3. **Property Input Widgets**
- `_buildNumberInput()` - Numeric inputs with validation
- `_buildPropertyInput()` - Smart input based on property type
- `_buildSection()` - Organized sections with headers

---

## 📝 Editable Properties

### Position Section
```dart
X: [Input Field] px
Y: [Input Field] px
```
- Updates `widget.position` (Offset)
- Allows negative values
- Instant sync on Enter key

### Size Section
```dart
Width:  [Input Field] px  (min: 10, max: 2000)
Height: [Input Field] px  (min: 10, max: 2000)
```
- Updates `widget.size` (Size)
- Enforces minimum/maximum constraints
- Instant sync on Enter key

### Widget Properties Section
Dynamically rendered based on `widget.properties` map:

#### Boolean Properties
```dart
isVisible: [Toggle Switch]
isLocked:  [Toggle Switch]
```

#### Number Properties
```dart
opacity:   [Input Field] (0.0 - 1.0)
rotation:  [Input Field] (degrees)
fontSize:  [Input Field] px
```

#### String Properties
```dart
text:       [Text Input]
fontFamily: [Text Input]
```

#### Color Properties
```dart
backgroundColor: [Color Preview] #FF5733
borderColor:     [Color Preview] #000000
```

---

## 🚀 Usage Example

### 1. Select a Widget
```dart
// User clicks on a widget in the canvas
context.read<PageBloc>().add(
  SelectPageWidget(widgetId),
);
```

### 2. Edit Property
```dart
// User changes width from 100 to 150
_updateWidgetSize(
  context,
  widget,
  150.0,  // new width
  widget.size.height,
);
```

### 3. Sync Happens Automatically
```dart
void _updateWidgetSize(BuildContext context, PageWidget widget, double newWidth, double newHeight) {
  // Create updated widget
  final updatedWidget = widget.copyWith(
    size: Size(newWidth, newHeight),
  );

  // Dispatch event (BLoC handles sync)
  context.read<PageBloc>().add(
    UpdateWidgetInPage(
      widgetId: widget.id,
      updatedWidget: updatedWidget,
    ),
  );
}
```

### 4. Backend Sync Flow
```dart
// In PageBloc:
Future<void> _onUpdateWidgetInPage(UpdateWidgetInPage event, Emitter<PageState> emit) async {
  // 1. Store old data
  final oldData = state.currentPage!.pageData;
  final currentVersion = state.currentPage!.version;

  // 2. Update locally (optimistic)
  final updatedWidgets = state.currentPage!.pageData.widgets.map((widget) {
    return widget.id == event.widgetId ? event.updatedWidget : widget;
  }).toList();

  final updatedPageData = state.currentPage!.pageData.copyWith(
    widgets: updatedWidgets,
    version: currentVersion + 1,
  );

  // 3. Emit new state
  emit(state.copyWith(currentPage: updatedPage, isSyncing: true));

  // 4. Generate JSON Patch
  final patches = _patchService.generatePatch(oldData, updatedPageData);

  // 5. Send via WebSocket
  _wsClient.sendPatch(
    pageId: state.currentPage!.id,
    patches: patches,
    clientVersion: currentVersion,
  );
}
```

---

## 🎨 Property Types Supported

### 1. **Position Properties**
```json
{
  "position": {
    "x": 150.5,
    "y": 200.3
  }
}
```
**Rendering**: Two number inputs (X, Y)

### 2. **Size Properties**
```json
{
  "size": {
    "width": 200,
    "height": 150
  }
}
```
**Rendering**: Two number inputs with min/max validation

### 3. **Boolean Properties**
```json
{
  "properties": {
    "isVisible": true,
    "isLocked": false,
    "hasShadow": true
  }
}
```
**Rendering**: Toggle switches

### 4. **Number Properties**
```json
{
  "properties": {
    "opacity": 0.8,
    "rotation": 45,
    "fontSize": 16,
    "borderWidth": 2
  }
}
```
**Rendering**: Number input fields

### 5. **String Properties**
```json
{
  "properties": {
    "text": "Hello World",
    "fontFamily": "Arial",
    "placeholder": "Enter text"
  }
}
```
**Rendering**: Text input fields

### 6. **Color Properties**
```json
{
  "properties": {
    "backgroundColor": "#FF5733",
    "borderColor": "#000000",
    "textColor": "#FFFFFF"
  }
}
```
**Rendering**: Color preview box + hex value display

---

## 🔄 Real-Time Sync Behavior

### Scenario 1: User A Edits Position
```
User A: Changes X from 100 → 150
    ↓
Local State Updates Immediately (Optimistic)
    ↓
JSON Patch Generated: [{ "op": "replace", "path": "/widgets/0/position/x", "value": 150 }]
    ↓
Sent to Backend via WebSocket
    ↓
Backend applies OT if conflict
    ↓
Broadcast to User B, User C
    ↓
User B & C see widget move to X=150
```

### Scenario 2: Concurrent Edits (Conflict Resolution)
```
User A: Changes width to 200 (version 5 → 6)
User B: Changes height to 150 (version 5 → 6)
    ↓
Both send patches with clientVersion=5
    ↓
Backend receives User A's patch first
    ↓
Backend increments version to 6
    ↓
Backend receives User B's patch (expecting v5, but now v6)
    ↓
Backend applies OT to transform User B's patch
    ↓
Backend applies transformed patch (v6 → v7)
    ↓
Both changes applied correctly
    ↓
Final result: width=200, height=150
```

### Scenario 3: External Update While Editing
```
User A: Typing in X field (not submitted yet)
User B: Changes X to 200 and submits
    ↓
User B's patch arrives via WebSocket
    ↓
PageBloc updates state with X=200
    ↓
PropertiesPanel detects value change
    ↓
Updates controller text (if different)
    ↓
User A sees X field update to 200
    ↓
User A can continue editing
```

---

## 🛠️ Implementation Details

### Controller Management
```dart
TextEditingController _getController(String key, String initialValue) {
  if (!_controllers.containsKey(key)) {
    // Create new controller
    _controllers[key] = TextEditingController(text: initialValue);
  } else {
    // Update if value changed externally (from sync)
    if (_controllers[key]!.text != initialValue) {
      _controllers[key]!.text = initialValue;
    }
  }
  return _controllers[key]!;
}
```
**Purpose**: Ensure text fields stay in sync with incoming updates while preserving user's current input.

### Input Validation
```dart
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
    // Invalid input, revert to original value
    controller.text = value.toStringAsFixed(0);
  }
}
```
**Purpose**: Validate numeric inputs and enforce min/max constraints.

### Property Type Detection
```dart
if (value is bool) {
  return Switch(...);
} else if (value is num) {
  return _buildNumberInput(...);
} else if (value is String && key.contains('color') && value.startsWith('#')) {
  return ColorPreview(...);
} else if (value is String) {
  return TextField(...);
}
```
**Purpose**: Render appropriate input widget based on property type.

---

## 📊 Performance Optimizations

### 1. **Throttling Cursor Updates**
While property edits are instant, cursor position updates are throttled to 100ms to prevent network flooding.

### 2. **Optimistic Updates**
UI updates immediately before backend confirmation, providing instant feedback.

### 3. **Minimal Patches**
Only differences are sent, not entire widget data:
```json
// Instead of sending entire widget (inefficient):
{
  "id": "widget-1",
  "type": "Container",
  "position": { "x": 150, "y": 200 },
  "size": { "width": 200, "height": 150 },
  "properties": { ... }
}

// We send only the change (efficient):
[
  { "op": "replace", "path": "/widgets/0/position/x", "value": 150 }
]
```

### 4. **Controller Reuse**
Text field controllers are reused and only updated when values change, preventing unnecessary rebuilds.

---

## 🎯 Future Enhancements

### 1. **Color Picker**
- Click color preview to open color picker
- Live preview while selecting
- Support for RGBA values

### 2. **Batch Editing**
- Select multiple widgets
- Edit shared properties at once
- Preview changes before applying

### 3. **Property Presets**
- Save common property combinations
- Quick apply presets to widgets
- Share presets with team

### 4. **Property History**
- Show recent values for properties
- Quick revert to previous values
- Property change timeline

### 5. **Smart Constraints**
- Lock aspect ratio for size changes
- Snap to grid values
- Relative positioning (align to other widgets)

### 6. **Advanced Property Types**
- Gradient editors
- Shadow editors
- Border style editors
- Animation property editors

---

## 🐛 Debugging

### Enable Debug Logs
```dart
// In page_bloc.dart
print('🔄 Applying incoming patch from user ${patchEvent.userId}');
print('✅ Patch confirmed: version ${patchEvent.version}');
```

### Check WebSocket Connection
```dart
// In page_websocket_client.dart
print('🔌 WebSocket connected');
print('📤 Sending patch: ${patches}');
print('📥 Received patch: ${event}');
```

### Verify State Updates
```dart
// In properties_panel.dart
print('Updated widget position: ${updatedWidget.position}');
print('Current page version: ${state.currentPage!.version}');
```

---

## ✅ Testing Checklist

### Manual Testing:
- [ ] Select widget → properties panel opens
- [ ] Edit X position → widget moves horizontally
- [ ] Edit Y position → widget moves vertically
- [ ] Edit width → widget resizes
- [ ] Edit height → widget resizes
- [ ] Toggle boolean property → widget updates
- [ ] Edit number property → widget updates
- [ ] Edit string property → widget updates
- [ ] Open two browsers → edit in one → see update in other
- [ ] Concurrent edits → no conflicts
- [ ] Delete widget → panel closes
- [ ] Deselect widget → panel shows empty state

### Edge Cases:
- [ ] Invalid number input (text) → reverts
- [ ] Size below minimum (10px) → clamps to 10px
- [ ] Size above maximum (2000px) → clamps to 2000px
- [ ] Negative position → allows
- [ ] Edit while receiving update → handles gracefully
- [ ] Disconnect/reconnect → sync resumes

---

## 📚 Related Documentation

- **Database Schema**: `DATABASE_SCHEMA_DOCUMENTATION.md`
- **WebSocket Events**: `backend/src/websocket/events.ts`
- **Page BLoC**: `frontend/lib/features/page/bloc/page_bloc.dart`
- **Patch Service**: `frontend/lib/core/services/patch_service.dart`

---

## 🎉 Summary

The **Property Panel** provides a seamless, real-time collaborative editing experience where:

✅ **Instant Feedback** - Local updates happen immediately  
✅ **Auto-Sync** - Changes automatically sync to all users  
✅ **Conflict-Free** - OT ensures concurrent edits work correctly  
✅ **Type-Safe** - Smart inputs based on property types  
✅ **Validated** - Input validation prevents invalid values  
✅ **Performant** - Minimal data transfer, optimistic updates  

The panel is a core component that enables SyncEditor's Figma-like collaborative editing experience!
