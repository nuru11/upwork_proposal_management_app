const aiDraftService = require('../services/aiDraftService');

async function list(req, res) {
  try {
    const items = await aiDraftService.list(req.user.id);
    return res.json(items);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function getById(req, res) {
  try {
    const item = await aiDraftService.getById(req.user.id, req.params.id);
    if (!item) return res.status(404).json({ error: 'AI draft not found' });
    return res.json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function create(req, res) {
  try {
    const item = await aiDraftService.create(req.user.id, req.body || {});
    return res.status(201).json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function update(req, res) {
  try {
    const item = await aiDraftService.update(
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
    await aiDraftService.remove(req.user.id, req.params.id);
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
