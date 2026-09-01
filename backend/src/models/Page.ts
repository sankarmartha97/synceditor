/**
 * Page Model
 * Represents a collaborative page with widgets as a single JSON document
 */

export enum PermissionType {
  OWNER = 'owner',
  EDIT = 'edit',
  COMMENT = 'comment',
  VIEW = 'view',
}

export interface PageMetadata {
  width: number;
  height: number;
  backgroundColor: string;
  gridSize: number;
  showGrid?: boolean;
  snapToGrid?: boolean;
  zoom?: number;
  createdAt?: string;
  updatedAt?: string;
  createdBy?: {
    userId: string;
    name: string;
  };
}

export interface WidgetPosition {
  x: number;
  y: number;
}

export interface WidgetSize {
  width: number;
  height: number;
}

export interface WidgetProperties {
  backgroundColor?: string;
  borderRadius?: number;
  opacity?: number;
  rotation?: number;
  zIndex?: number;
  text?: string;
  fontSize?: number;
  fontWeight?: string;
  color?: string;
  textAlign?: string;
  shadow?: {
    enabled: boolean;
    blur: number;
    color: string;
  };
  [key: string]: any; // Allow additional properties
}

export interface Widget {
  id: string;
  type: string;
  position: WidgetPosition;
  size: WidgetSize;
  properties: WidgetProperties;
  createdAt?: string;
  createdBy?: string;
  updatedAt?: string;
  updatedBy?: string;
}

export interface PageData {
  pageId: string;
  name: string;
  version: number;
  metadata: PageMetadata;
  widgets: Widget[];
}

export interface Page {
  id: string;
  name: string;
  ownerId: string;
  pageData: PageData;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
}

export interface PagePermission {
  id: string;
  pageId: string;
  userId: string;
  permissionType: PermissionType;
  grantedAt: Date;
  grantedBy: string;
  updatedAt: Date;
}

export interface PageVersion {
  id: string;
  pageId: string;
  version: number;
  pageData: PageData;
  operations?: any[]; // JSON Patch operations
  description?: string;
  createdBy: string;
  createdAt: Date;
}

export interface ActiveEditor {
  pageId: string;
  userId: string;
  cursorPosition?: { x: number; y: number };
  selectedWidgetId?: string;
  lastActive: Date;
}

// DTOs (Data Transfer Objects)

export interface CreatePageDTO {
  name: string;
  metadata?: Partial<PageMetadata>;
}

export interface UpdatePageDTO {
  name?: string;
  pageData?: Partial<PageData>;
}

export interface SharePageDTO {
  email: string;
  permissionType: PermissionType;
}

export interface PageListItem {
  id: string;
  name: string;
  ownerId: string;
  version: number;
  permission: PermissionType;
  updatedAt: Date;
  createdAt: Date;
}

// Helper type for permission checks
export interface UserPermission {
  pageId: string;
  userId: string;
  permissionType: PermissionType;
  isOwner: boolean;
  canEdit: boolean;
  canComment: boolean;
  canView: boolean;
}
