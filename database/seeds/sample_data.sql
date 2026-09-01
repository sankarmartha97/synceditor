-- Sample Data for Development
-- This file populates the database with test data

-- Insert sample users (password: "password123" for all)
INSERT INTO users (id, email, password_hash, name, avatar_url) VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'john@example.com', '$2b$10$rKvVPqWzYKABLQnBxqZYLOH7tQ9n8Hy8LXJ7zC8mZqP1qVxGJQK6m', 'John Doe', 'https://i.pravatar.cc/150?img=1'),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'jane@example.com', '$2b$10$rKvVPqWzYKABLQnBxqZYLOH7tQ9n8Hy8LXJ7zC8mZqP1qVxGJQK6m', 'Jane Smith', 'https://i.pravatar.cc/150?img=5'),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'bob@example.com', '$2b$10$rKvVPqWzYKABLQnBxqZYLOH7tQ9n8Hy8LXJ7zC8mZqP1qVxGJQK6m', 'Bob Johnson', 'https://i.pravatar.cc/150?img=12')
ON CONFLICT (email) DO NOTHING;

-- Insert sample canvases
INSERT INTO canvases (id, owner_id, name, description, settings, is_public) VALUES
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'My First Canvas', 'A simple canvas for testing', '{"backgroundColor": "#f0f0f0", "gridSize": 20, "showGrid": true, "zoom": 1.0}'::jsonb, false),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Design System', 'Component library canvas', '{"backgroundColor": "#ffffff", "gridSize": 10, "showGrid": false, "zoom": 1.2}'::jsonb, true)
ON CONFLICT (id) DO NOTHING;

-- Insert sample widgets
INSERT INTO widgets (id, canvas_id, type, position, size, properties) VALUES
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Container', 
     '{"x": 100, "y": 100, "z_index": 1}'::jsonb,
     '{"width": 200, "height": 150, "width_unit": "px", "height_unit": "px"}'::jsonb,
     '{"backgroundColor": "#3498db", "opacity": 1.0, "rotation": 0, "isLocked": false, "isVisible": true, "borderRadius": 8}'::jsonb),
    
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Text', 
     '{"x": 350, "y": 100, "z_index": 1}'::jsonb,
     '{"width": 150, "height": 50, "width_unit": "px", "height_unit": "px"}'::jsonb,
     '{"backgroundColor": "#2ecc71", "opacity": 1.0, "rotation": 0, "isLocked": false, "isVisible": true, "text": "Hello World", "fontSize": 18, "fontWeight": "bold", "color": "#ffffff"}'::jsonb),
    
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Button', 
     '{"x": 200, "y": 200, "z_index": 1}'::jsonb,
     '{"width": 120, "height": 40, "width_unit": "px", "height_unit": "px"}'::jsonb,
     '{"backgroundColor": "#e74c3c", "opacity": 1.0, "rotation": 0, "isLocked": false, "isVisible": true, "text": "Click Me", "borderRadius": 4}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Insert sample collaborators
INSERT INTO canvas_collaborators (canvas_id, user_id, role) VALUES
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'editor'),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'viewer')
ON CONFLICT (canvas_id, user_id) DO NOTHING;

-- Display summary
SELECT 'Database seeded successfully!' as message;
SELECT 'Users created: ' || COUNT(*) as summary FROM users;
SELECT 'Canvases created: ' || COUNT(*) as summary FROM canvases;
SELECT 'Widgets created: ' || COUNT(*) as summary FROM widgets;
