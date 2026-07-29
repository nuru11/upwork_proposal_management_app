const projectService = require('../services/projectService');

async function list(req, res) {
  try {
    const items = await projectService.list(req.user.id, {
      type: req.query.type,
    });
    return res.json(items);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function getById(req, res) {
  try {
    const item = await projectService.getById(req.user.id, req.params.id);
    if (!item) return res.status(404).json({ error: 'Project not found' });
    return res.json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function create(req, res) {
  try {
    const item = await projectService.create(req.user.id, req.body || {});
    return res.status(201).json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function update(req, res) {
  try {
    const item = await projectService.update(
      req.user.id,
      req.params.id,
      req.body || {},
    );
    return res.json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function remove(req, res) {
  try {
    await projectService.remove(req.user.id, req.params.id);
    return res.status(204).send();
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
};
