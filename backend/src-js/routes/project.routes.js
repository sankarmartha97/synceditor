const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth.middleware');
const projectService = require('../services/project.service');

router.use(authMiddleware);

// ── Projects CRUD ────────────────────────────────────────────────────────────

router.post('/', async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Project name is required' });
    }
    const project = await projectService.createProject(req.user.userId, {
      name: name.trim(),
      description,
    });
    res.status(201).json({ success: true, data: project });
  } catch (err) {
    console.error('POST /api/projects error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.get('/', async (req, res) => {
  try {
    const projects = await projectService.getUserProjects(req.user.userId);
    res.json({ success: true, data: projects });
  } catch (err) {
    console.error('GET /api/projects error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const project = await projectService.getProjectById(req.params.id, req.user.userId);
    if (!project) return res.status(404).json({ success: false, message: 'Project not found' });
    res.json({ success: true, data: project });
  } catch (err) {
    console.error('GET /api/projects/:id error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    const project = await projectService.updateProject(
      req.params.id,
      req.user.userId,
      req.body,
    );
    if (!project) {
      return res.status(404).json({ success: false, message: 'Project not found or permission denied' });
    }
    res.json({ success: true, data: project });
  } catch (err) {
    console.error('PATCH /api/projects/:id error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const deleted = await projectService.deleteProject(req.params.id, req.user.userId);
    if (!deleted) {
      return res.status(403).json({ success: false, message: 'Permission denied or project not found' });
    }
    res.json({ success: true, message: 'Project deleted' });
  } catch (err) {
    console.error('DELETE /api/projects/:id error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ── Pages inside a project ───────────────────────────────────────────────────

router.get('/:id/pages', async (req, res) => {
  try {
    const pages = await projectService.getProjectPages(req.params.id, req.user.userId);
    res.json({ success: true, data: pages });
  } catch (err) {
    console.error('GET /api/projects/:id/pages error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// ── Members ──────────────────────────────────────────────────────────────────

router.get('/:id/members', async (req, res) => {
  try {
    const members = await projectService.getMembers(req.params.id, req.user.userId);
    res.json({ success: true, data: members });
  } catch (err) {
    console.error('GET /api/projects/:id/members error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.post('/:id/members', async (req, res) => {
  try {
    const { email, permissionType } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'email is required' });
    }
    const result = await projectService.addMember(req.params.id, req.user.userId, {
      email,
      permissionType,
    });
    if (result.error === 'user_not_found') {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('POST /api/projects/:id/members error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

router.delete('/:id/members/:userId', async (req, res) => {
  try {
    await projectService.removeMember(req.params.id, req.user.userId, req.params.userId);
    res.json({ success: true, message: 'Member removed' });
  } catch (err) {
    console.error('DELETE /api/projects/:id/members/:userId error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

module.exports = router;
