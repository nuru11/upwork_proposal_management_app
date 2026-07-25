const proposalService = require('../services/proposalService');
const templateService = require('../services/templateService');

async function sync(req, res) {
  try {
    const [proposals, templates] = await Promise.all([
      proposalService.listAllForSync(req.user.id),
      templateService.listAllForSync(req.user.id),
    ]);
    return res.json({ proposals, templates });
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

module.exports = {
  sync,
};
