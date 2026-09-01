# Frontend API Endpoints Fix

## Issue
The frontend was using incorrect API endpoints without the `/api` prefix, causing 404 errors.

## Changes Made

### 1. Updated `endpoints.dart` ✅
Added all new page and comment endpoints with proper `/api` prefix:

```dart
// Page Endpoints (New standard)
static const String pages = '$apiVersion/pages';                    // /api/pages
static String pageById(String id) => '$apiVersion/pages/$id';       // /api/pages/:id
static String pageName(String id) => '$apiVersion/pages/$id/name';  // /api/pages/:id/name
static String pageShare(String id) => '$apiVersion/pages/$id/share'; // /api/pages/:id/share
static String pagePermissions(String id) => '$apiVersion/pages/$id/permissions';
static String pagePermissionForUser(String pageId, String userId) =>
    '$apiVersion/pages/$pageId/permissions/$userId';
static String pageVersions(String id) => '$apiVersion/pages/$id/versions';

// Comments Endpoints
static String pageComments(String pageId) => '$apiVersion/pages/$pageId/comments';
static String commentById(String commentId) => '$apiVersion/comments/$commentId';
static String commentThread(String commentId) => '$apiVersion/comments/$commentId/thread';
static String commentResolve(String commentId) => '$apiVersion/comments/$commentId/resolve';
static String commentMentionsRead(String commentId) => '$apiVersion/comments/$commentId/mentions/read';
static String userMentions = '$apiVersion/users/me/mentions';
static String pageCommentStats(String pageId) => '$apiVersion/pages/$pageId/comments/stats';
```

### 2. Updated `page_service.dart` ✅
Changed from hardcoded paths to using `ApiEndpoints` constants:

**Before:**
```dart
final response = await _apiClient.post('/pages', data: {...});
final response = await _apiClient.get('/pages');
final response = await _apiClient.get('/pages/$pageId');
```

**After:**
```dart
final response = await _apiClient.post(ApiEndpoints.pages, data: {...});
final response = await _apiClient.get(ApiEndpoints.pages);
final response = await _apiClient.get(ApiEndpoints.pageById(pageId));
```

### 3. Updated `comments_service.dart` ✅
Added import for ApiEndpoints (ready for future use):

```dart
import '../api/endpoints.dart';
```

Note: Comments service already had proper paths, but now has the endpoints import available.

---

## Correct API Endpoints

### Authentication (No auth required)
```
POST   http://localhost:5000/api/auth/register
POST   http://localhost:5000/api/auth/login
POST   http://localhost:5000/api/auth/logout
GET    http://localhost:5000/api/auth/me
```

### Pages (Auth required)
```
GET    http://localhost:5000/api/pages              // List all user's pages
POST   http://localhost:5000/api/pages              // Create new page
GET    http://localhost:5000/api/pages/:id          // Get page details
PATCH  http://localhost:5000/api/pages/:id          // Update page
DELETE http://localhost:5000/api/pages/:id          // Delete page
PUT    http://localhost:5000/api/pages/:id/name     // Rename page
POST   http://localhost:5000/api/pages/:id/share    // Share page
GET    http://localhost:5000/api/pages/:id/permissions
PATCH  http://localhost:5000/api/pages/:id/permissions/:userId
DELETE http://localhost:5000/api/pages/:id/permissions/:userId
GET    http://localhost:5000/api/pages/:id/versions
```

### Comments (Auth required)
```
GET    http://localhost:5000/api/pages/:pageId/comments
POST   http://localhost:5000/api/pages/:pageId/comments
GET    http://localhost:5000/api/comments/:id
PUT    http://localhost:5000/api/comments/:id
DELETE http://localhost:5000/api/comments/:id
GET    http://localhost:5000/api/comments/:id/thread
PUT    http://localhost:5000/api/comments/:id/resolve
PUT    http://localhost:5000/api/comments/:id/mentions/read
GET    http://localhost:5000/api/users/me/mentions
GET    http://localhost:5000/api/pages/:pageId/comments/stats
```

### Health & Info (No auth required)
```
GET    http://localhost:5000/health
GET    http://localhost:5000/api
```

### Legacy Canvas API (Deprecated, but still works)
```
GET    http://localhost:5000/api/canvases
POST   http://localhost:5000/api/canvases
GET    http://localhost:5000/api/canvases/:id
...
```

---

## Testing

Run Flutter analyze to verify:
```bash
cd frontend
flutter analyze
```

**Result:** ✅ No issues found!

---

## Benefits

1. ✅ **Consistent URLs** - All endpoints properly prefixed with `/api`
2. ✅ **Centralized Configuration** - All endpoints defined in one place
3. ✅ **Type Safety** - Using constants instead of string literals
4. ✅ **Maintainability** - Easy to update endpoints in future
5. ✅ **No 404 Errors** - Correct paths match backend routes

---

## Summary

All frontend services now use the correct API endpoints with the `/api` prefix:
- ✅ `endpoints.dart` - Updated with all page and comment endpoints
- ✅ `page_service.dart` - Using `ApiEndpoints` constants
- ✅ `comments_service.dart` - Import added for future use
- ✅ All other services already had correct `/api` prefix

**The frontend is now properly configured to communicate with the backend!** 🎉
