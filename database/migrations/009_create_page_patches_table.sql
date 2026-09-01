-- Migration: Create page_patches table for patch history
-- Purpose: Track all incremental changes (JSON Patches) to pages
-- Date: 2024

CREATE TABLE IF NOT EXISTS page_patches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- JSON Patch operations (RFC 6902)
    patches JSONB NOT NULL,
    
    -- Version tracking
    from_version INT NOT NULL,
    to_version INT NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for efficient querying
    CONSTRAINT page_patches_version_check CHECK (to_version > from_version)
);

-- Index for fast page lookup
CREATE INDEX idx_page_patches_page_id ON page_patches(page_id);

-- Index for user lookup
CREATE INDEX idx_page_patches_user_id ON page_patches(user_id);

-- Index for version lookup
CREATE INDEX idx_page_patches_version ON page_patches(page_id, to_version DESC);

-- Index for time-based queries
CREATE INDEX idx_page_patches_created_at ON page_patches(created_at DESC);

-- Composite index for page history queries
CREATE INDEX idx_page_patches_page_time ON page_patches(page_id, created_at DESC);

-- Add comment
COMMENT ON TABLE page_patches IS 'Stores JSON Patch history for incremental sync';
COMMENT ON COLUMN page_patches.patches IS 'Array of JSON Patch operations (RFC 6902)';
COMMENT ON COLUMN page_patches.from_version IS 'Page version before applying patches';
COMMENT ON COLUMN page_patches.to_version IS 'Page version after applying patches';

-- Example query: Get recent patches for a page
-- SELECT * FROM page_patches WHERE page_id = 'uuid' ORDER BY created_at DESC LIMIT 50;

-- Example query: Rebuild page at specific version
-- SELECT patches FROM page_patches 
-- WHERE page_id = 'uuid' AND to_version <= 10 
-- ORDER BY to_version ASC;
