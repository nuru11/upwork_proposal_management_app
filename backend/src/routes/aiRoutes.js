const express = require('express');
const aiController = require('../controllers/aiController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);
router.post('/extract-issues', aiController.extractIssues);
router.post('/suggest-solutions', aiController.suggestSolutions);
router.post('/draft-proposal', aiController.draftProposal);
router.post('/draft-proposal-from-template', aiController.draftProposalFromTemplate);

module.exports = router;
