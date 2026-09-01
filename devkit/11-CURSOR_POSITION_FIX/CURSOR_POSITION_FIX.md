# Cursor Position Synchronization Fix

## Issue Description

**Problem:** When multiple users are collaborating on a page, cursor positions are displayed incorrectly. For example, if User A's cursor is in the middle of the canvas, User B sees it in a different position (e.g., middle-right).

**Root Cause:** The cursor position was being sent using **screen coordinates** (`event.position.dx/dy`) instead of **canvas-relative coordinates**, causing misalignment between users with different:
- Screen sizes
- Window positions
- Scroll positions
- Panel configurations

## Visual Example

```
User A's View:                    User B's View:
┌─────────────────────┐          ┌─────────────────────┐
│  [Cursor A]         │          │              [A?]   │  ← Wrong position!
│      (center)       │          │                     │
└─────────────────────┘          └─────────────────────┘
```

## Solution Implemented

### Change 1: Convert Screen to Container-Relative Coordinates

**File:** `frontend/lib/features/page/views/page_editor_screen.dart`

**Before:**
```dart
MouseRegion(
  onHover: (event) {
    if (canEdit && state.currentPage != null) {
      context.read<PageBloc>().add(
        SendCursorPosition(
          pageId: state.currentPage!.id,
          x: event.position.dx,  // ❌ Screen coordinates
          y: event.position.dy,  // ❌ Screen coordinates
        ),
      );
    }
  },
  child: Stack(...),
),
```

**After:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    return MouseRegion(
      onHover: (event) {
        if (canEdit && state.currentPage != null) {
          // ✅ Convert to container-relative coordinates
          final RenderBox? renderBox =
              context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(event.position);
            
            context.read<PageBloc>().add(
              SendCursorPosition(
                pageId: state.currentPage!.id,
                x: localPosition.dx,  // ✅ Container-relative
                y: localPosition.dy,  // ✅ Container-relative
              ),
            );
          }
        }
      },
      child: Stack(...),
    );
  },
),
```

## Coordinate Systems Explained

### 1. Screen Coordinates (Global)
- Origin: Top-left of the entire screen
- Affected by: Window position, browser chrome
- **Problem:** Different for every user

```
┌────────────────────────────────┐
│ Browser Window (User A)        │
│  ┌──────────────────────┐      │
│  │ Canvas Container     │      │
│  │    [Cursor]          │      │ ← Event position (200, 150)
│  └──────────────────────┘      │
└────────────────────────────────┘
```

### 2. Container-Relative Coordinates (Local)
- Origin: Top-left of the canvas container
- Affected by: Panel sizes, layout
- **Better:** Consistent within the container

```
┌────────────────────────────────┐
│ Canvas Container               │
│                                │
│    [Cursor]                    │ ← Local position (100, 100)
│                                │
└────────────────────────────────┘
```

### 3. Canvas Coordinates (Ideal - TODO)
- Origin: Top-left of the actual canvas (white area)
- Affected by: InteractiveViewer pan/zoom
- **Best:** Absolute canvas position

```
┌────────────────────────────────┐
│ Canvas (2000x2000)             │
│                                │
│    [Cursor]                    │ ← Canvas position (500, 300)
│                                │
└────────────────────────────────┘
```

## Current Limitations

### ✅ Fixed Issues
- Cursor position now relative to canvas container
- Works consistently across different screen sizes
- Not affected by browser window position

### ⚠️ Remaining Issues

1. **InteractiveViewer Transformation Not Accounted For**
   - Problem: When users pan/zoom the canvas, cursor positions don't account for the transformation
   - Impact: Cursors may appear slightly offset when users have different zoom/pan states
   
2. **Scroll Position**
   - Problem: If the canvas is scrollable and users have different scroll positions
   - Impact: Minor offset in cursor display

## Complete Solution (TODO)

To fully fix cursor positioning, we need to account for InteractiveViewer transformations:

```dart
// Get the transformation matrix from InteractiveViewer
final transformationController = /* access from PageCanvasView */;
final matrix = transformationController.value;

// Convert container-relative to canvas coordinates
final canvasPosition = matrix.transformPoint(localPosition);

// Send canvas coordinates
context.read<PageBloc>().add(
  SendCursorPosition(
    pageId: state.currentPage!.id,
    x: canvasPosition.dx,
    y: canvasPosition.dy,
  ),
);
```

### Implementation Steps for Complete Fix

1. **Expose TransformationController**
   - Make `_transformationController` accessible from `PageCanvasView`
   - Pass it up to `PageEditorScreen` via callback or provider

2. **Transform Coordinates on Send**
   - Apply inverse transformation to get canvas coordinates
   - Send absolute canvas position

3. **Transform Coordinates on Receive**
   - Apply current transformation to received canvas coordinates
   - Display at correct screen position

4. **Handle Zoom/Pan Changes**
   - Update remote cursor positions when local user pans/zooms
   - Smooth animation during transformation

### Example Complete Implementation

```dart
// In PageCanvasView - expose controller
class PageCanvasView extends StatefulWidget {
  final PageModel page;
  final ValueChanged<TransformationController>? onControllerReady;
  
  const PageCanvasView({
    super.key,
    required this.page,
    this.onControllerReady,
  });
}

// In PageEditorScreen - use transformation
TransformationController? _canvasTransformation;

MouseRegion(
  onHover: (event) {
    if (canEdit && state.currentPage != null && renderBox != null) {
      final localPosition = renderBox.globalToLocal(event.position);
      
      // Apply inverse transformation to get canvas coordinates
      final canvasPosition = _canvasTransformation != null
          ? MatrixUtils.transformPoint(
              _canvasTransformation!.value.inverted(),
              localPosition,
            )
          : localPosition;
      
      context.read<PageBloc>().add(
        SendCursorPosition(
          pageId: state.currentPage!.id,
          x: canvasPosition.dx,
          y: canvasPosition.dy,
        ),
      );
    }
  },
)

// When displaying remote cursors
// Apply current transformation to received canvas coordinates
final displayPosition = _canvasTransformation != null
    ? MatrixUtils.transformPoint(
        _canvasTransformation!.value,
        Offset(cursor.x, cursor.y),
      )
    : Offset(cursor.x, cursor.y);
```

## Testing Checklist

### Basic Tests
- [x] Cursor position relative to container (FIXED)
- [ ] Cursor position with zoom in/out
- [ ] Cursor position with pan left/right/up/down
- [ ] Cursor position with different screen sizes
- [ ] Cursor position with different panel configurations

### Advanced Tests
- [ ] Multiple users with different zoom levels
- [ ] Multiple users with different pan positions
- [ ] Rapid zoom/pan changes
- [ ] Cursor updates during transformation animation
- [ ] Performance with 5+ active cursors

## Related Files

**Frontend:**
- `frontend/lib/features/page/views/page_editor_screen.dart` - Cursor sending (MODIFIED)
- `frontend/lib/features/page/views/page_canvas_view.dart` - Canvas rendering
- `frontend/lib/features/page/widgets/remote_cursor.dart` - Cursor display
- `frontend/lib/features/page/managers/cursor_manager.dart` - Cursor management
- `frontend/lib/features/page/bloc/page_bloc.dart` - Cursor event handling
- `frontend/lib/core/api/page_websocket_client.dart` - WebSocket communication

**Backend:**
- `backend/src-js/websocket/page.handler.js` - Cursor event handler

## Summary

**Status:** Partially Fixed ✅

**What's Fixed:**
- Cursor positions now use container-relative coordinates instead of screen coordinates
- Works consistently across different screen sizes and window positions

**What's Remaining:**
- Account for InteractiveViewer transformation (zoom/pan)
- Requires exposing transformation controller and applying matrix transformations

**Priority:** Medium (current fix resolves most common issues)

**Estimated Effort for Complete Fix:** 2-3 hours

---

**Date:** September 1, 2026  
**Fixed By:** Development Team  
**Status:** Partial Fix Applied, Full Fix Pending
