const express = require('express');
const authRoutes = require('./authRoutes');
const proposalRoutes = require('./proposalRoutes');
const templateRoutes = require('./templateRoutes');
const syncController = require('../controllers/syncController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.get('/health', (_req, res) => {
  res.json({ ok: true });
});

router.use('/auth', authRoutes);
router.use('/proposals', proposalRoutes);
router.use('/templates', templateRoutes);
router.get('/sync', authRequired, syncController.sync);

module.exports = router;
