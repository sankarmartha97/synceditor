-- Track E: Add project_id FK to pages.
-- Nullable so all existing pages (which have no project) remain valid.

ALTER TABLE pages
  ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_pages_project_id ON pages(project_id) WHERE project_id IS NOT NULL;
