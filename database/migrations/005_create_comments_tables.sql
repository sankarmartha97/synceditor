-- Migration 005: Comments and Annotations System
-- Phase 3.3: Enable collaborative feedback with threaded comments, @mentions, and canvas annotations

-- ============================================
-- Comments Table
-- ============================================

CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Reference
  page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Content
  content TEXT NOT NULL CHECK (LENGTH(content) > 0 AND LENGTH(content) <= 5000),
  
  -- Position (for canvas annotations, optional)
  position_x FLOAT,
  position_y FLOAT,
  
  -- Widget reference (for widget-specific comments, optional)
  widget_id VARCHAR(255),
  
  -- Threading support
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  -- Status
  resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMP,
  
  -- Metadata
  edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  -- Constraints
  CONSTRAINT valid_position CHECK (
    (position_x IS NULL AND position_y IS NULL) OR 
    (position_x IS NOT NULL AND position_y IS NOT NULL)
  ),
  
  -- Indexes
  INDEX idx_comments_page (page_id),
  INDEX idx_comments_user (user_id),
  INDEX idx_comments_widget (widget_id),
  INDEX idx_comments_thread (parent_comment_id),
  INDEX idx_comments_created (created_at DESC),
  INDEX idx_comments_resolved (resolved, page_id)
);

COMMENT ON TABLE comments IS 'User comments and annotations on pages with thread support';
COMMENT ON COLUMN comments.content IS 'Comment text content, max 5000 characters';
COMMENT ON COLUMN comments.position_x IS 'X coordinate for canvas annotation (optional)';
COMMENT ON COLUMN comments.position_y IS 'Y coordinate for canvas annotation (optional)';
COMMENT ON COLUMN comments.widget_id IS 'Widget ID for widget-specific comments (optional)';
COMMENT ON COLUMN comments.parent_comment_id IS 'Parent comment for thread replies (NULL for root comments)';
COMMENT ON COLUMN comments.resolved IS 'Whether the comment thread is resolved';
COMMENT ON COLUMN comments.deleted_at IS 'Soft delete timestamp (NULL = not deleted)';

-- ============================================
-- Comment Mentions Table
-- ============================================

CREATE TABLE IF NOT EXISTS comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Reference
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Status
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(comment_id, user_id),
  
  -- Indexes
  INDEX idx_mentions_user (user_id, read),
  INDEX idx_mentions_comment (comment_id)
);

COMMENT ON TABLE comment_mentions IS '@mentions in comments for notifications';
COMMENT ON COLUMN comment_mentions.read IS 'Whether the mentioned user has seen the notification';

-- ============================================
-- Comment Reactions Table (Optional - for future)
-- ============================================

CREATE TABLE IF NOT EXISTS comment_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Reference
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Reaction type (emoji)
  reaction VARCHAR(50) NOT NULL, -- 👍 👎 ❤️ 😄 🎉 🚀 etc.
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(comment_id, user_id, reaction),
  
  -- Indexes
  INDEX idx_reactions_comment (comment_id)
);

COMMENT ON TABLE comment_reactions IS 'Emoji reactions to comments (future enhancement)';

-- ============================================
-- Comment Stats View (for performance)
-- ============================================

CREATE OR REPLACE VIEW comment_stats AS
SELECT 
  c.id,
  c.page_id,
  COUNT(DISTINCT r.id) as reply_count,
  COUNT(DISTINCT m.id) as mention_count,
  COUNT(DISTINCT cr.id) as reaction_count,
  MAX(COALESCE(r.created_at, c.created_at)) as last_activity_at
FROM comments c
LEFT JOIN comments r ON r.parent_comment_id = c.id AND r.deleted_at IS NULL
LEFT JOIN comment_mentions m ON m.comment_id = c.id
LEFT JOIN comment_reactions cr ON cr.comment_id = c.id
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.page_id;

COMMENT ON VIEW comment_stats IS 'Aggregated comment statistics for quick queries';

-- ============================================
-- Triggers for updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_comment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comment_timestamp
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_updated_at();

-- ============================================
-- Sample Data (for testing)
-- ============================================

-- Sample comments will be added via API during testing
-- No seed data needed for comments (user-generated content)

-- ============================================
-- Indexes for Performance
-- ============================================

-- Composite index for thread queries
CREATE INDEX idx_comments_thread_page ON comments(page_id, parent_comment_id, created_at DESC)
WHERE deleted_at IS NULL;

-- Index for unread mentions
CREATE INDEX idx_mentions_unread ON comment_mentions(user_id, created_at DESC)
WHERE read = false;

-- Index for resolved comments
CREATE INDEX idx_comments_unresolved ON comments(page_id, resolved, created_at DESC)
WHERE deleted_at IS NULL AND resolved = false;

-- ============================================
-- Grant Permissions
-- ============================================

-- Grant permissions to application user (if exists)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON comments TO sync_editor_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON comment_mentions TO sync_editor_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON comment_reactions TO sync_editor_user;
-- GRANT SELECT ON comment_stats TO sync_editor_user;

-- ============================================
-- Migration Complete
-- ============================================

-- Version: 005
-- Description: Comments and Annotations System
-- Tables: comments, comment_mentions, comment_reactions
-- Views: comment_stats
-- Features: Threading, @mentions, Canvas annotations, Soft deletes, Reactions (future)
