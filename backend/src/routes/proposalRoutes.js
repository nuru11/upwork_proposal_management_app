const express = require('express');
const proposalController = require('../controllers/proposalController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);
router.get('/', proposalController.list);
router.post('/', proposalController.create);
router.get('/:id', proposalController.getById);
router.put('/:id', proposalController.update);
router.delete('/:id', proposalController.remove);

module.exports = router;
