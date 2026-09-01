-- Migration: Create Canvases Table
-- Version: 002
-- Description: Creates the canvases table with settings and relationships

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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_canvases_owner_id ON canvases(owner_id);
CREATE INDEX IF NOT EXISTS idx_canvases_created_at ON canvases(created_at DESC);

-- Apply updated_at trigger
DROP TRIGGER IF EXISTS update_canvases_updated_at ON canvases;
CREATE TRIGGER update_canvases_updated_at
    BEFORE UPDATE ON canvases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comment
COMMENT ON TABLE canvases IS 'Stores canvas documents with settings';
COMMENT ON COLUMN canvases.settings IS 'Canvas-level settings (background, grid, zoom)';
