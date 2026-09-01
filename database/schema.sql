-- Canvas Editor Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================
-- CANVASES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS canvases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    settings JSONB DEFAULT '{
        "backgroundColor": "#ffffff",
        "gridSize": 20,
        "showGrid": true,
        "zoom": 1.0
    }'::jsonb,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_canvases_owner_id ON canvases(owner_id);
CREATE INDEX IF NOT EXISTS idx_canvases_created_at ON canvases(created_at DESC);

-- ============================================
-- WIDGETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    parent_id UUID REFERENCES widgets(id) ON DELETE CASCADE,
    
    -- Position data
    position JSONB NOT NULL DEFAULT '{
        "x": 0,
        "y": 0,
        "z_index": 0
    }'::jsonb,
    
    -- Size data
    size JSONB NOT NULL DEFAULT '{
        "width": 100,
        "height": 100,
        "width_unit": "px",
        "height_unit": "px"
    }'::jsonb,
    
    -- Widget properties (flexible JSON)
    properties JSONB NOT NULL DEFAULT '{
        "backgroundColor": "#ffffff",
        "opacity": 1.0,
        "rotation": 0,
        "isLocked": false,
        "isVisible": true
    }'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_widgets_canvas_id ON widgets(canvas_id);
CREATE INDEX IF NOT EXISTS idx_widgets_parent_id ON widgets(parent_id);
CREATE INDEX IF NOT EXISTS idx_widgets_type ON widgets(type);

-- ============================================
-- WIDGET VERSIONS TABLE (for undo/redo)
-- ============================================
CREATE TABLE IF NOT EXISTS widget_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    widget_id UUID NOT NULL REFERENCES widgets(id) ON DELETE CASCADE,
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    data JSONB NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_widget_versions_widget_id ON widget_versions(widget_id);
CREATE INDEX IF NOT EXISTS idx_widget_versions_canvas_id ON widget_versions(canvas_id);
CREATE INDEX IF NOT EXISTS idx_widget_versions_created_at ON widget_versions(created_at DESC);

-- ============================================
-- CANVAS COLLABORATORS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS canvas_collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner', 'editor', 'viewer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(canvas_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_canvas_collaborators_canvas_id ON canvas_collaborators(canvas_id);
CREATE INDEX IF NOT EXISTS idx_canvas_collaborators_user_id ON canvas_collaborators(user_id);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to canvases table
DROP TRIGGER IF EXISTS update_canvases_updated_at ON canvases;
CREATE TRIGGER update_canvases_updated_at
    BEFORE UPDATE ON canvases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to widgets table
DROP TRIGGER IF EXISTS update_widgets_updated_at ON widgets;
CREATE TRIGGER update_widgets_updated_at
    BEFORE UPDATE ON widgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS
-- ============================================

-- View for canvas with widget count and collaborator count
CREATE OR REPLACE VIEW canvas_overview AS
SELECT 
    c.id,
    c.owner_id,
    c.name,
    c.description,
    c.settings,
    c.is_public,
    c.created_at,
    c.updated_at,
    u.name as owner_name,
    u.email as owner_email,
    COUNT(DISTINCT w.id) as widget_count,
    COUNT(DISTINCT cc.id) as collaborator_count
FROM canvases c
LEFT JOIN users u ON c.owner_id = u.id
LEFT JOIN widgets w ON c.id = w.canvas_id
LEFT JOIN canvas_collaborators cc ON c.id = cc.canvas_id
GROUP BY c.id, u.name, u.email;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE users IS 'Stores user accounts and authentication information';
COMMENT ON TABLE canvases IS 'Stores canvas documents with settings';
COMMENT ON TABLE widgets IS 'Stores individual widgets on canvases';
COMMENT ON TABLE widget_versions IS 'Version history for undo/redo functionality';
COMMENT ON TABLE canvas_collaborators IS 'Manages canvas sharing and permissions';

COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password';
COMMENT ON COLUMN canvases.settings IS 'Canvas-level settings (background, grid, zoom)';
COMMENT ON COLUMN widgets.position IS 'Widget position {x, y, z_index}';
COMMENT ON COLUMN widgets.size IS 'Widget size {width, height, units}';
COMMENT ON COLUMN widgets.properties IS 'Widget-specific properties (color, style, etc.)';
