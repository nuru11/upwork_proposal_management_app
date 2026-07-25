const express = require('express');
const templateController = require('../controllers/templateController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);
router.get('/', templateController.list);
router.post('/', templateController.create);
router.get('/:id', templateController.getById);
router.put('/:id', templateController.update);
router.delete('/:id', templateController.remove);

module.exports = router;
