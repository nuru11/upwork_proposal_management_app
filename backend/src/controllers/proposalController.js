const proposalService = require('../services/proposalService');

async function list(req, res) {
  try {
    const items = await proposalService.list(req.user.id, {
      status: req.query.status,
      language: req.query.language,
      search: req.query.search,
    });
    return res.json(items);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function getById(req, res) {
  try {
    const item = await proposalService.getById(req.user.id, req.params.id);
    if (!item) return res.status(404).json({ error: 'Proposal not found' });
    return res.json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function create(req, res) {
  try {
    const item = await proposalService.create(req.user.id, req.body || {});
    return res.status(201).json(item);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function update(req, res) {
  try {
    const item = await proposalService.update(
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
    await proposalService.remove(req.user.id, req.params.id);
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
