-- Migration: 007_create_page_versions_table
-- Description: Create page versions table for version history and restore capability
-- Author: System
-- Date: 2025-01-27

-- Create page_versions table
CREATE TABLE IF NOT EXISTS page_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  page_data JSONB NOT NULL,
  operations JSONB NULL,
  description TEXT NULL,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Ensure unique version per page
  CONSTRAINT unique_page_version UNIQUE (page_id, version)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_versions_page ON page_versions(page_id);
CREATE INDEX IF NOT EXISTS idx_versions_page_version ON page_versions(page_id, version DESC);
CREATE INDEX IF NOT EXISTS idx_versions_created ON page_versions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_versions_user ON page_versions(created_by);

-- Create GIN index for operations JSONB
CREATE INDEX IF NOT EXISTS idx_versions_ops_gin ON page_versions USING GIN (operations);

-- Add comments
COMMENT ON TABLE page_versions IS 'Stores historical snapshots of pages for version control';
COMMENT ON COLUMN page_versions.page_id IS 'Reference to the page';
COMMENT ON COLUMN page_versions.version IS 'Version number (matches page.version at time of save)';
COMMENT ON COLUMN page_versions.page_data IS 'Complete page JSON snapshot at this version';
COMMENT ON COLUMN page_versions.operations IS 'JSON Patch operations that created this version (optional)';
COMMENT ON COLUMN page_versions.description IS 'Human-readable description of changes';
COMMENT ON COLUMN page_versions.created_by IS 'User who created this version';

-- Example operations structure (JSON Patch format):
-- [
--   { "op": "add", "path": "/widgets/-", "value": {...} },
--   { "op": "replace", "path": "/widgets/0/position/x", "value": 150 },
--   { "op": "remove", "path": "/widgets/1" }
-- ]
