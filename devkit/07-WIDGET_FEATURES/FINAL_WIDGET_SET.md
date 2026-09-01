# Final Widget Set - Simplified

## 🎯 Widget Classification

### Multi-Widgets (Can Accept Children) - 5 Widgets

| Widget | Icon | Color | Behavior | Description |
|--------|------|-------|----------|-------------|
| **Container** | crop_square | Blue | Column | Vertical layout (default container) |
| **Card** | credit_card | Purple | Column | Material card with vertical layout |
| **Row** | view_week | Teal | Row | Horizontal layout |
| **Column** | view_column | Cyan | Column | Vertical layout |
| **Stack** | layers | Indigo | Stack | Overlapping/layered layout |

### Single Widgets (No Children) - 3 Widgets

| Widget | Icon | Color | Description |
|--------|------|-------|-------------|
| **Text** | text_fields | Green | Text display |
| **Button** | smart_button | Red | Interactive button |
| **Image** | image | Orange | Image display |

---

## 📐 Layout Behaviors

### Container & Card (Column Behavior)
- Children stack **vertically**
- 16px spacing between children
- 20px left padding
- Default on new pages

### Row
- Children arrange **horizontally**
- Left to right
- Can contain multi-widgets or single widgets

### Column
- Children stack **vertically**
- Same as Container behavior
- Explicit vertical layout

### Stack
- Children **overlay** each other
- Z-index determines layering
- Positioned absolutely within Stack

---

## 🎨 Visual Structure

```
Widget Library
├─ LAYOUT (Multi-Widget) - 5 widgets
│  ├─ Container (Column behavior) [CONTAINER]
│  ├─ Card (Column behavior)      [CONTAINER]
│  ├─ Row                          [CONTAINER]
│  ├─ Column                       [CONTAINER]
│  └─ Stack                        [CONTAINER]
│
└─ BASIC (Single Widget) - 3 widgets
   ├─ Text
   ├─ Button
   └─ Image
```

---

## ✅ Design Decisions

### Why Container = Column?
- **Simplicity**: Container naturally contains children vertically
- **Common use case**: Most layouts stack vertically
- **Default behavior**: New pages start with Container (vertical layout)
- **Consistency**: Container and Column behave the same

### Why Remove ListView/GridView?
- **Complexity**: These require special scrolling/grid logic
- **Not needed yet**: Basic layouts covered by existing widgets
- **Future addition**: Can add later if needed

### Why Keep These 5?
- **Container**: Default container, vertical layout
- **Card**: Visual grouping with elevation
- **Row**: Horizontal arrangements
- **Column**: Explicit vertical layout
- **Stack**: Overlapping elements (floating buttons, badges, etc.)

---

## 🧪 Example Layouts

### Simple Vertical Layout (Container)
```
Container
├─ Text (title)
├─ Button (action 1)
├─ Button (action 2)
└─ Image (banner)
```
*Children stack vertically with 16px spacing*

### Horizontal Layout (Row)
```
Row
├─ Button (left)
├─ Text (center)
└─ Button (right)
```
*Children arrange horizontally*

### Mixed Layout
```
Container
├─ Text (header)
├─ Row
│  ├─ Button (cancel)
│  └─ Button (confirm)
└─ Card
   ├─ Text (info)
   └─ Image (preview)
```
*Vertical container with horizontal row inside*

### Overlay Layout (Stack)
```
Stack
├─ Image (background)
├─ Container
│  └─ Text (overlay text)
└─ Button (floating action button)
```
*Elements overlay each other*

---

## 🔧 Technical Details

### Container Types Array
```dart
static bool _isContainerType(String type) {
  const containerTypes = [
    'Container',
    'Card',
    'Row',
    'Column',
    'Stack',
  ];
  return containerTypes.contains(type);
}
```

### Default Container on New Pages
```dart
final defaultContainer = PageWidget(
  type: 'Container',
  position: const Offset(50, 50),
  size: const Size(800, 600),
  isContainer: true,
);
```

### Vertical Spacing (Container, Card, Column)
```dart
// Calculate Y position for vertical stacking
double yPosition = 20.0; // First child
if (existingChildren.isNotEmpty) {
  yPosition = maxBottom + 16.0; // 16px spacing
}
```

---

## 📊 Summary

**Total Widgets**: 8
- **5 Multi-Widgets**: Container, Card, Row, Column, Stack
- **3 Single Widgets**: Text, Button, Image

**Key Features**:
- ✅ Container behaves like Column (vertical layout)
- ✅ Simple, intuitive widget set
- ✅ Covers common layout patterns
- ✅ Easy to understand and use
- ✅ Room for future expansion

**Layout Patterns Supported**:
- ✅ Vertical layouts (Container, Card, Column)
- ✅ Horizontal layouts (Row)
- ✅ Overlapping layouts (Stack)
- ✅ Nested combinations
- ✅ Multi-level hierarchies

---

*Final widget set defined - December 2024*
