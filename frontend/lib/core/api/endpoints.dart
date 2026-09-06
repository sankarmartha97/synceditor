class ApiEndpoints {
  // Base URL - can be configured via environment variables
  static const String baseUrl = 'http://localhost:5000';
  static const String wsUrl = 'ws://localhost:5000';

  // API Version
  static const String apiVersion = '/api';

  // Auth Endpoints
  static const String login = '$apiVersion/auth/login';
  static const String register = '$apiVersion/auth/register';
  static const String logout = '$apiVersion/auth/logout';
  static const String currentUser = '$apiVersion/auth/me';

  // Canvas Endpoints (Legacy - deprecated)
  static const String canvases = '$apiVersion/canvases';
  static String canvasById(String id) => '$apiVersion/canvases/$id';
  static String canvasCollaborators(String id) =>
      '$apiVersion/canvases/$id/collaborators';
  static String addCollaborator(String id) =>
      '$apiVersion/canvases/$id/collaborators';
  static String removeCollaborator(String canvasId, String userId) =>
      '$apiVersion/canvases/$canvasId/collaborators/$userId';

  // Page Endpoints (New standard)
  static const String pages = '$apiVersion/pages';
  static String pageById(String id) => '$apiVersion/pages/$id';
  static String pageName(String id) => '$apiVersion/pages/$id/name';
  static String pageShare(String id) => '$apiVersion/pages/$id/share';
  static String pagePermissions(String id) =>
      '$apiVersion/pages/$id/permissions';
  static String pagePermissionForUser(String pageId, String userId) =>
      '$apiVersion/pages/$pageId/permissions/$userId';
  static String pageVersions(String id) => '$apiVersion/pages/$id/versions';

  // Comments Endpoints
  static String pageComments(String pageId) =>
      '$apiVersion/pages/$pageId/comments';
  static String commentById(String commentId) =>
      '$apiVersion/comments/$commentId';
  static String commentThread(String commentId) =>
      '$apiVersion/comments/$commentId/thread';
  static String commentResolve(String commentId) =>
      '$apiVersion/comments/$commentId/resolve';
  static String commentMentionsRead(String commentId) =>
      '$apiVersion/comments/$commentId/mentions/read';
  static String userMentions = '$apiVersion/users/me/mentions';
  static String pageCommentStats(String pageId) =>
      '$apiVersion/pages/$pageId/comments/stats';

  // Widget Endpoints
  static String canvasWidgets(String canvasId) =>
      '$apiVersion/canvases/$canvasId/widgets';
  static String widgetById(String canvasId, String widgetId) =>
      '$apiVersion/canvases/$canvasId/widgets/$widgetId';
  static String batchUpdateWidgets(String canvasId) =>
      '$apiVersion/canvases/$canvasId/widgets/batch';

  // Health Check
  static const String health = '/health';
}
