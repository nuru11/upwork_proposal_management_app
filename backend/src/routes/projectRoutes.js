const express = require('express');
const projectController = require('../controllers/projectController');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);
router.get('/', projectController.list);
router.post('/', projectController.create);
router.get('/:id', projectController.getById);
router.put('/:id', projectController.update);
router.delete('/:id', projectController.remove);

module.exports = router;
