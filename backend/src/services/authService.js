const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const User = require('../models/User');

async function findByUsername(username) {
  const rows = await query(
    'SELECT * FROM users WHERE username = ? LIMIT 1',
    [username],
  );
  return rows[0] || null;
}

async function login(username, password) {
  const user = await findByUsername(username);
  if (!user) {
    const err = new Error('Invalid username or password');
    err.status = 401;
    throw err;
  }

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    const err = new Error('Invalid username or password');
    err.status = 401;
    throw err;
  }

  const token = jwt.sign(
    { username: user.username },
    process.env.JWT_SECRET,
    { subject: user.id, expiresIn: '30d' },
  );

  return {
    token,
    user: User.toPublic(user),
  };
}

module.exports = {
  findByUsername,
  login,
};
