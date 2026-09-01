-- Migration 006: Operation History for Undo/Redo with OT
-- Phase 3.1: Track all operations for undo/redo functionality with Operational Transformation

-- ============================================
-- Operation History Table
-- ============================================

CREATE TABLE IF NOT EXISTS operation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- References
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Forward operation (what was done)
  operation JSONB NOT NULL,
  
  -- Inverse operation (for undo)
  inverse_operation JSONB NOT NULL,
  
  -- Version tracking
  from_version INT NOT NULL,
  to_version INT NOT NULL,
  
  -- Dependencies for OT (operations this depends on)
  parent_operations UUID[] DEFAULT '{}',
  
  -- Operation metadata
  operation_type VARCHAR(50), -- 'add', 'remove', 'replace', 'move', 'copy'
  affected_paths TEXT[], -- Paths affected by this operation
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CHECK (to_version > from_version),
  CHECK (to_version = from_version + 1) -- Each operation increments by 1
);

-- Create indexes separately
CREATE INDEX IF NOT EXISTS idx_operation_history_page ON operation_history(page_id);
CREATE INDEX IF NOT EXISTS idx_operation_history_user ON operation_history(page_id, user_id);
CREATE INDEX IF NOT EXISTS idx_operation_history_version ON operation_history(page_id, to_version DESC);
CREATE INDEX IF NOT EXISTS idx_operation_history_from_version ON operation_history(page_id, from_version);
CREATE INDEX IF NOT EXISTS idx_operation_history_created ON operation_history(page_id, created_at DESC);

COMMENT ON TABLE operation_history IS 'History of all operations for undo/redo functionality';
COMMENT ON COLUMN operation_history.operation IS 'Forward operation (JSON Patch) - what was applied';
COMMENT ON COLUMN operation_history.inverse_operation IS 'Inverse operation (JSON Patch) - for undo';
COMMENT ON COLUMN operation_history.from_version IS 'Page version before this operation';
COMMENT ON COLUMN operation_history.to_version IS 'Page version after this operation';
COMMENT ON COLUMN operation_history.parent_operations IS 'UUIDs of operations this one depends on (for OT)';
COMMENT ON COLUMN operation_history.operation_type IS 'Type of operation: add, remove, replace, move, copy';
COMMENT ON COLUMN operation_history.affected_paths IS 'JSON Patch paths affected by this operation';

-- ============================================
-- User Undo/Redo Stacks Table
-- ============================================

CREATE TABLE IF NOT EXISTS user_undo_stacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- References
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Undo stack (array of operation history IDs)
  undo_stack UUID[] DEFAULT '{}',
  
  -- Redo stack (array of operation history IDs)
  redo_stack UUID[] DEFAULT '{}',
  
  -- Max stack size (limit memory usage)
  max_stack_size INT DEFAULT 100,
  
  -- Timestamps
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(page_id, user_id)
);

-- Create index separately
CREATE INDEX IF NOT EXISTS idx_user_undo_stacks_page_user ON user_undo_stacks(page_id, user_id);

COMMENT ON TABLE user_undo_stacks IS 'Per-user undo/redo stacks for each page';
COMMENT ON COLUMN user_undo_stacks.undo_stack IS 'Stack of operation IDs that can be undone';
COMMENT ON COLUMN user_undo_stacks.redo_stack IS 'Stack of operation IDs that can be redone';
COMMENT ON COLUMN user_undo_stacks.max_stack_size IS 'Maximum operations to keep in stack (default 100)';

-- ============================================
-- Operation Stats View
-- ============================================

CREATE OR REPLACE VIEW operation_stats AS
SELECT 
  page_id,
  user_id,
  COUNT(*) as total_operations,
  COUNT(*) FILTER (WHERE operation_type = 'add') as add_operations,
  COUNT(*) FILTER (WHERE operation_type = 'remove') as remove_operations,
  COUNT(*) FILTER (WHERE operation_type = 'replace') as replace_operations,
  MIN(created_at) as first_operation_at,
  MAX(created_at) as last_operation_at,
  MAX(to_version) as latest_version
FROM operation_history
GROUP BY page_id, user_id;

COMMENT ON VIEW operation_stats IS 'Aggregated operation statistics per user per page';

-- ============================================
-- Triggers
-- ============================================

-- Update user_undo_stacks timestamp on modification
CREATE OR REPLACE FUNCTION update_undo_stack_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_undo_stack_timestamp
  BEFORE UPDATE ON user_undo_stacks
  FOR EACH ROW
  EXECUTE FUNCTION update_undo_stack_timestamp();

-- ============================================
-- Cleanup Functions
-- ============================================

-- Function to cleanup old operation history (keep last N days)
CREATE OR REPLACE FUNCTION cleanup_old_operations(days_to_keep INT DEFAULT 30)
RETURNS TABLE(deleted_count BIGINT) AS $$
DECLARE
  del_count BIGINT;
BEGIN
  DELETE FROM operation_history
  WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
  
  GET DIAGNOSTICS del_count = ROW_COUNT;
  
  RETURN QUERY SELECT del_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_operations IS 'Delete operation history older than specified days (default 30)';

-- Function to trim undo/redo stacks to max size
CREATE OR REPLACE FUNCTION trim_undo_stacks()
RETURNS TABLE(trimmed_users INT) AS $$
DECLARE
  trim_count INT := 0;
  stack_record RECORD;
BEGIN
  FOR stack_record IN 
    SELECT id, undo_stack, redo_stack, max_stack_size
    FROM user_undo_stacks
    WHERE array_length(undo_stack, 1) > max_stack_size 
       OR array_length(redo_stack, 1) > max_stack_size
  LOOP
    UPDATE user_undo_stacks
    SET 
      undo_stack = undo_stack[1:max_stack_size],
      redo_stack = redo_stack[1:max_stack_size]
    WHERE id = stack_record.id;
    
    trim_count := trim_count + 1;
  END LOOP;
  
  RETURN QUERY SELECT trim_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trim_undo_stacks IS 'Trim undo/redo stacks to max_stack_size';

-- ============================================
-- Indexes for Performance
-- ============================================

-- Composite index for getting recent operations
CREATE INDEX idx_operation_history_page_user_recent 
ON operation_history(page_id, user_id, created_at DESC);

-- Index for version range queries (used in OT)
CREATE INDEX idx_operation_history_version_range 
ON operation_history(page_id, from_version, to_version);

-- GIN index for parent_operations array lookups
CREATE INDEX idx_operation_history_parents 
ON operation_history USING GIN(parent_operations);

-- Index for operation type filtering
CREATE INDEX idx_operation_history_type 
ON operation_history(page_id, operation_type);

-- ============================================
-- Initial Data
-- ============================================

-- No initial data needed - populated during operations

-- ============================================
-- Permissions
-- ============================================

-- Grant permissions to application user (if exists)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON operation_history TO sync_editor_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON user_undo_stacks TO sync_editor_user;
-- GRANT SELECT ON operation_stats TO sync_editor_user;
-- GRANT EXECUTE ON FUNCTION cleanup_old_operations TO sync_editor_user;
-- GRANT EXECUTE ON FUNCTION trim_undo_stacks TO sync_editor_user;

-- ============================================
-- Migration Complete
-- ============================================

-- Version: 006
-- Description: Operation History for Undo/Redo with OT
-- Tables: operation_history, user_undo_stacks
-- Views: operation_stats
-- Functions: cleanup_old_operations, trim_undo_stacks
-- Features: Per-user undo/redo stacks, OT dependency tracking, cleanup utilities
