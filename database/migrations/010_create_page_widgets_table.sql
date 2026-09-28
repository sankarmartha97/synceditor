-- Migration: Create page_widgets table (Track B -- devkit/13-SCALING_AND_COLLABORATION)
-- Purpose: Normalize widgets out of pages.page_data JSONB into one row per widget,
--          so a single edit touches one small row instead of rewriting the whole page.
-- Note: named page_widgets, NOT widgets -- a legacy "widgets" table already exists
--       from the old canvas/widgets schema (canvas_id-based, migration 003) and is
--       unrelated to the page-based architecture. Do not reuse that name.
-- Date: 2026

CREATE TABLE IF NOT EXISTS page_widgets (
    id UUID PRIMARY KEY,
    page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,

    -- Adjacency-list tree: the container this widget sits inside, NULL = top-level.
    -- Structural moves (reparenting) touch only this one row -- no shared "structure" document.
    parent_id UUID REFERENCES page_widgets(id) ON DELETE CASCADE,

    -- Sibling order under the same parent_id. Insert between two widgets by
    -- averaging their order_keys (e.g. between 1000 and 2000 -> 1500) --
    -- never needs renumbering the rest of the siblings.
    order_key NUMERIC NOT NULL DEFAULT 0,

    type VARCHAR(50) NOT NULL,
    position JSONB NOT NULL DEFAULT '{"x": 0, "y": 0}',
    size JSONB NOT NULL DEFAULT '{"width": 0, "height": 0}',
    properties JSONB NOT NULL DEFAULT '{}',
    children_ids JSONB NOT NULL DEFAULT '[]',
    is_container BOOLEAN NOT NULL DEFAULT false,
    z_index INTEGER NOT NULL DEFAULT 0,
    position_mode VARCHAR(20) NOT NULL DEFAULT 'absolute',
    is_default_container BOOLEAN NOT NULL DEFAULT false,

    -- Optimistic concurrency for per-row writes, used starting in Track B2:
    -- UPDATE page_widgets SET ... WHERE id = $1 AND version = $2
    version INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

-- Index for fast "all widgets on this page" lookup
CREATE INDEX IF NOT EXISTS idx_page_widgets_page_id ON page_widgets(page_id);

-- Index for fast "children of this container" lookup
CREATE INDEX IF NOT EXISTS idx_page_widgets_parent_id ON page_widgets(parent_id);

-- Composite index for rendering a page in sibling order
CREATE INDEX IF NOT EXISTS idx_page_widgets_page_order ON page_widgets(page_id, order_key);

-- Add comments
COMMENT ON TABLE page_widgets IS 'One row per design widget, normalized out of pages.page_data (Track B)';
COMMENT ON COLUMN page_widgets.parent_id IS 'Self-referential: the container widget this widget sits inside, NULL for top-level';
COMMENT ON COLUMN page_widgets.order_key IS 'Sibling order under the same parent_id; insert between two widgets by averaging their order_keys, no renumbering needed';
COMMENT ON COLUMN page_widgets.version IS 'Optimistic concurrency check for per-row writes (Track B2): UPDATE ... WHERE id = $1 AND version = $2';

-- Example query: all top-level widgets on a page, in order
-- SELECT * FROM page_widgets WHERE page_id = 'uuid' AND parent_id IS NULL ORDER BY order_key ASC;

-- Example query: children of a specific container, in order
-- SELECT * FROM page_widgets WHERE parent_id = 'uuid' ORDER BY order_key ASC;
