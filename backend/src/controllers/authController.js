const authService = require('../services/authService');

async function login(req, res) {
  try {
    const { username, password } = req.body || {};
    if (!username || !password) {
      return res.status(400).json({ error: 'username and password are required' });
    }
    const result = await authService.login(String(username), String(password));
    return res.json(result);
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message || 'Login failed' });
  }
}

module.exports = {
  login,
};
