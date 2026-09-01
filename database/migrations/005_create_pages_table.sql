-- Migration: 005_create_pages_table
-- Description: Create pages table to replace canvases with single JSON document architecture
-- Author: System
-- Date: 2025-01-27

-- Create pages table
CREATE TABLE IF NOT EXISTS pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  page_data JSONB NOT NULL DEFAULT '{"widgets": [], "metadata": {}}',
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP NULL,
  
  CONSTRAINT pages_name_not_empty CHECK (CHAR_LENGTH(name) > 0)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pages_owner ON pages(owner_id);
CREATE INDEX IF NOT EXISTS idx_pages_updated ON pages(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_pages_deleted ON pages(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_pages_version ON pages(version);

-- Create GIN index for JSONB page_data (for querying within JSON)
CREATE INDEX IF NOT EXISTS idx_pages_data_gin ON pages USING GIN (page_data);

-- Add comments for documentation
COMMENT ON TABLE pages IS 'Stores collaborative pages with all widgets as single JSON document';
COMMENT ON COLUMN pages.id IS 'Unique page identifier';
COMMENT ON COLUMN pages.name IS 'Page display name';
COMMENT ON COLUMN pages.owner_id IS 'User who owns this page';
COMMENT ON COLUMN pages.page_data IS 'Complete page JSON including widgets, metadata, and settings';
COMMENT ON COLUMN pages.version IS 'Incremental version number for conflict detection';
COMMENT ON COLUMN pages.deleted_at IS 'Soft delete timestamp (NULL = active)';

-- Example page_data structure:
-- {
--   "pageId": "uuid",
--   "name": "Page Name",
--   "version": 1,
--   "metadata": {
--     "width": 1920,
--     "height": 1080,
--     "backgroundColor": "#FFFFFF",
--     "gridSize": 10
--   },
--   "widgets": [
--     {
--       "id": "widget-1",
--       "type": "Container",
--       "position": { "x": 100, "y": 50 },
--       "size": { "width": 200, "height": 150 },
--       "properties": { "backgroundColor": "#FF5733" }
--     }
--   ]
-- }
