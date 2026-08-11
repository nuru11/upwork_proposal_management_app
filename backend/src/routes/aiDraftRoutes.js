const express = require('express');
const aiDraftController = require('../controllers/aiDraftController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);
router.get('/', aiDraftController.list);
router.post('/', aiDraftController.create);
router.get('/:id', aiDraftController.getById);
router.put('/:id', aiDraftController.update);
router.delete('/:id', aiDraftController.remove);

module.exports = router;
