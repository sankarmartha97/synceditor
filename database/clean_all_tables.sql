-- ============================================
-- Clean All Table Data Script
-- ============================================
-- WARNING: This will delete ALL data from all tables
-- Run this only in development environment
-- ============================================

-- Disable foreign key checks temporarily (PostgreSQL uses CASCADE)
BEGIN;

-- Clean data from tables (order matters due to foreign keys)
-- Start with child tables first, then parent tables

-- Comment related tables
TRUNCATE TABLE comment_reactions CASCADE;
TRUNCATE TABLE comment_mentions CASCADE;
TRUNCATE TABLE comments CASCADE;

-- Page related tables
TRUNCATE TABLE page_patches CASCADE;
TRUNCATE TABLE active_editors CASCADE;
TRUNCATE TABLE page_versions CASCADE;
TRUNCATE TABLE page_permissions CASCADE;
TRUNCATE TABLE operation_history CASCADE;
TRUNCATE TABLE user_undo_stacks CASCADE;
TRUNCATE TABLE pages CASCADE;

-- Widget related tables
TRUNCATE TABLE widget_versions CASCADE;
TRUNCATE TABLE widgets CASCADE;

-- Canvas related tables
TRUNCATE TABLE canvas_collaborators CASCADE;
TRUNCATE TABLE canvases CASCADE;

-- User table (clean last since other tables reference it)
TRUNCATE TABLE users CASCADE;

COMMIT;

-- Verify all tables are empty
SELECT 
    'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'canvases', COUNT(*) FROM canvases
UNION ALL
SELECT 'widgets', COUNT(*) FROM widgets
UNION ALL
SELECT 'widget_versions', COUNT(*) FROM widget_versions
UNION ALL
SELECT 'canvas_collaborators', COUNT(*) FROM canvas_collaborators
UNION ALL
SELECT 'pages', COUNT(*) FROM pages
UNION ALL
SELECT 'page_versions', COUNT(*) FROM page_versions
UNION ALL
SELECT 'page_permissions', COUNT(*) FROM page_permissions
UNION ALL
SELECT 'active_editors', COUNT(*) FROM active_editors
UNION ALL
SELECT 'page_patches', COUNT(*) FROM page_patches
UNION ALL
SELECT 'operation_history', COUNT(*) FROM operation_history
UNION ALL
SELECT 'user_undo_stacks', COUNT(*) FROM user_undo_stacks
UNION ALL
SELECT 'comments', COUNT(*) FROM comments
UNION ALL
SELECT 'comment_mentions', COUNT(*) FROM comment_mentions
UNION ALL
SELECT 'comment_reactions', COUNT(*) FROM comment_reactions;

-- Success message
SELECT '✅ All table data has been cleaned successfully!' as status;
