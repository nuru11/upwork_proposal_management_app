const proposalService = require('../services/proposalService');
const templateService = require('../services/templateService');
const projectService = require('../services/projectService');

async function sync(req, res) {
  try {
    const [proposals, templates, projects] = await Promise.all([
      proposalService.listAllForSync(req.user.id),
      templateService.listAllForSync(req.user.id),
      projectService.listAllForSync(req.user.id),
    ]);
    return res.json({ proposals, templates, projects });
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

module.exports = {
  sync,
};
