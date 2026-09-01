-- Migration: Create Widgets Table
-- Version: 003
-- Description: Creates the widgets table with position, size, and properties

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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_widgets_canvas_id ON widgets(canvas_id);
CREATE INDEX IF NOT EXISTS idx_widgets_parent_id ON widgets(parent_id);
CREATE INDEX IF NOT EXISTS idx_widgets_type ON widgets(type);

-- Apply updated_at trigger
DROP TRIGGER IF EXISTS update_widgets_updated_at ON widgets;
CREATE TRIGGER update_widgets_updated_at
    BEFORE UPDATE ON widgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE widgets IS 'Stores individual widgets on canvases';
COMMENT ON COLUMN widgets.position IS 'Widget position {x, y, z_index}';
COMMENT ON COLUMN widgets.size IS 'Widget size {width, height, units}';
COMMENT ON COLUMN widgets.properties IS 'Widget-specific properties (color, style, etc.)';
