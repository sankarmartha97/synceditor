// WebSocket event names

// Client -> Server events
export const CLIENT_EVENTS = {
  CANVAS_JOIN: 'canvas:join',
  CANVAS_LEAVE: 'canvas:leave',
  WIDGET_ADD: 'widget:add',
  WIDGET_UPDATE: 'widget:update',
  WIDGET_DELETE: 'widget:delete',
  WIDGET_MOVE: 'widget:move',
  CURSOR_MOVE: 'cursor:move',
  CURSOR_HIDE: 'cursor:hide',
} as const;

// Server -> Client events
export const SERVER_EVENTS = {
  CANVAS_JOINED: 'canvas:joined',
  CANVAS_LEFT: 'canvas:left',
  WIDGET_ADDED: 'widget:added',
  WIDGET_UPDATED: 'widget:updated',
  WIDGET_DELETED: 'widget:deleted',
  WIDGET_MOVED: 'widget:moved',
  USER_JOINED: 'user:joined',
  USER_LEFT: 'user:left',
  CURSOR_UPDATED: 'cursor:updated',
  CURSOR_HIDDEN: 'cursor:hidden',
  SYNC_ERROR: 'sync:error',
  CONNECTION_ERROR: 'connection:error',
} as const;

// Event payload interfaces
export interface CanvasJoinPayload {
  canvasId: string;
}

export interface CanvasLeavePayload {
  canvasId: string;
}

export interface WidgetAddPayload {
  canvasId: string;
  widget: {
    type: string;
    position: any;
    size: any;
    properties: any;
    parent_id?: string;
  };
}

export interface WidgetUpdatePayload {
  canvasId: string;
  widgetId: string;
  updates: any;
}

export interface WidgetDeletePayload {
  canvasId: string;
  widgetId: string;
}

export interface WidgetMovePayload {
  canvasId: string;
  widgetId: string;
  position: {
    x: number;
    y: number;
    z_index?: number;
  };
}

export interface CursorMovePayload {
  canvasId: string;
  position: {
    x: number;
    y: number;
  };
}

export interface UserInfo {
  userId: string;
  name: string;
  email: string;
  avatarUrl?: string;
}
