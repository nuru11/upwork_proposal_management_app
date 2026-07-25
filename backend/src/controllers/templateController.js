const templateService = require('../services/templateService');

async function list(req, res) {
  try {
    const items = await templateService.list(req.user.id);
    return res.json(items);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function getById(req, res) {
  try {
    const item = await templateService.getById(req.user.id, req.params.id);
    if (!item) return res.status(404).json({ error: 'Template not found' });
    return res.json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function create(req, res) {
  try {
    const item = await templateService.create(req.user.id, req.body || {});
    return res.status(201).json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function update(req, res) {
  try {
    const item = await templateService.update(
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
    await templateService.remove(req.user.id, req.params.id);
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
