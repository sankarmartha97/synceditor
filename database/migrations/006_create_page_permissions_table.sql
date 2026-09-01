-- Migration: 006_create_page_permissions_table
-- Description: Create page permissions table for sharing and access control
-- Author: System
-- Date: 2025-01-27

-- Create permission type enum
DO $$ BEGIN
  CREATE TYPE permission_type AS ENUM ('owner', 'edit', 'comment', 'view');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create page_permissions table
CREATE TABLE IF NOT EXISTS page_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_type permission_type NOT NULL DEFAULT 'view',
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  granted_by UUID NOT NULL REFERENCES users(id),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Ensure one permission per user per page
  CONSTRAINT unique_page_user UNIQUE (page_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_permissions_page ON page_permissions(page_id);
CREATE INDEX IF NOT EXISTS idx_permissions_user ON page_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_permissions_type ON page_permissions(permission_type);
CREATE INDEX IF NOT EXISTS idx_permissions_granted ON page_permissions(granted_at DESC);

-- Add comments
COMMENT ON TABLE page_permissions IS 'Stores page sharing permissions and access control';
COMMENT ON COLUMN page_permissions.page_id IS 'Reference to the shared page';
COMMENT ON COLUMN page_permissions.user_id IS 'User who has been granted access';
COMMENT ON COLUMN page_permissions.permission_type IS 'Level of access: owner, edit, comment, or view';
COMMENT ON COLUMN page_permissions.granted_by IS 'User who granted this permission';

-- Permission hierarchy:
-- owner   > edit    > comment  > view
-- (Full)   (Edit)    (Comment)  (Read-only)

COMMENT ON TYPE permission_type IS 'Permission levels: owner (full control), edit (can edit), comment (can add comments), view (read-only)';
