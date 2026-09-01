-- Migration: Create Widget Versions and Canvas Collaborators Tables
-- Version: 004
-- Description: Creates tables for version history and collaboration

-- Widget Versions Table (for undo/redo)
CREATE TABLE IF NOT EXISTS widget_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    widget_id UUID NOT NULL REFERENCES widgets(id) ON DELETE CASCADE,
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    data JSONB NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for widget_versions
CREATE INDEX IF NOT EXISTS idx_widget_versions_widget_id ON widget_versions(widget_id);
CREATE INDEX IF NOT EXISTS idx_widget_versions_canvas_id ON widget_versions(canvas_id);
CREATE INDEX IF NOT EXISTS idx_widget_versions_created_at ON widget_versions(created_at DESC);

-- Canvas Collaborators Table
CREATE TABLE IF NOT EXISTS canvas_collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner', 'editor', 'viewer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(canvas_id, user_id)
);

-- Indexes for canvas_collaborators
CREATE INDEX IF NOT EXISTS idx_canvas_collaborators_canvas_id ON canvas_collaborators(canvas_id);
CREATE INDEX IF NOT EXISTS idx_canvas_collaborators_user_id ON canvas_collaborators(user_id);

-- Add comments
COMMENT ON TABLE widget_versions IS 'Version history for undo/redo functionality';
COMMENT ON TABLE canvas_collaborators IS 'Manages canvas sharing and permissions';
