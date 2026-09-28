-- Track E: Project-level permissions.
-- When a user is added to a project, page_permissions rows are written for
-- every page currently in that project (see project.service.js).  When a new
-- page is created inside a project, page_permissions rows are written for every
-- current project member.  This keeps the existing page-level permission check
-- (used in REST handlers, socket handlers, etc.) as the single authoritative
-- gate — project_permissions is a bookkeeping table that drives that fan-out,
-- not a separate runtime check.

CREATE TABLE IF NOT EXISTS project_permissions (
  project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_type VARCHAR(20) NOT NULL DEFAULT 'edit'
                    CHECK (permission_type IN ('owner','edit','comment','view')),
  granted_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  granted_by      UUID REFERENCES users(id),
  PRIMARY KEY (project_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_project_permissions_user_id ON project_permissions(user_id);
