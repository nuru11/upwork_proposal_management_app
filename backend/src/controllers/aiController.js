const aiProposalService = require('../services/aiProposalService');

async function extractIssues(req, res) {
  try {
    const result = await aiProposalService.extractIssues(req.body || {});
    return res.json(result);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function suggestSolutions(req, res) {
  try {
    const result = await aiProposalService.suggestSolutions(req.body || {});
    return res.json(result);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

async function draftProposal(req, res) {
  try {
    const result = await aiProposalService.draftProposal(req.body || {});
    return res.json(result);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message });
  }
}

module.exports = {
  extractIssues,
  suggestSolutions,
  draftProposal,
};
