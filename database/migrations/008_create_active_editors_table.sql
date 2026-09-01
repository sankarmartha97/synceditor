-- Migration: 008_create_active_editors_table
-- Description: Create active editors table for real-time presence tracking
-- Author: System
-- Date: 2025-01-27

-- Create active_editors table
CREATE TABLE IF NOT EXISTS active_editors (
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cursor_position JSONB NULL DEFAULT '{}',
  selected_widget_id VARCHAR(255) NULL,
  last_active TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Composite primary key
  PRIMARY KEY (page_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_active_last_active ON active_editors(last_active);
CREATE INDEX IF NOT EXISTS idx_active_page ON active_editors(page_id);
CREATE INDEX IF NOT EXISTS idx_active_user ON active_editors(user_id);

-- Add comments
COMMENT ON TABLE active_editors IS 'Tracks currently active users on each page for real-time collaboration';
COMMENT ON COLUMN active_editors.page_id IS 'Page being edited';
COMMENT ON COLUMN active_editors.user_id IS 'User who is active on this page';
COMMENT ON COLUMN active_editors.cursor_position IS 'Current cursor position { x, y }';
COMMENT ON COLUMN active_editors.selected_widget_id IS 'ID of widget currently selected by user';
COMMENT ON COLUMN active_editors.last_active IS 'Last activity timestamp (used for cleanup)';

-- Example cursor_position structure:
-- { "x": 150.5, "y": 200.3 }

-- Create function to clean up inactive editors
CREATE OR REPLACE FUNCTION cleanup_inactive_editors()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete editors inactive for more than 5 minutes
  DELETE FROM active_editors
  WHERE last_active < NOW() - INTERVAL '5 minutes';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_inactive_editors IS 'Removes editors who have been inactive for more than 5 minutes';

-- Note: Run this periodically (e.g., every minute via cron job or scheduler)
-- Example: SELECT cleanup_inactive_editors();
