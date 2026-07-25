const path = require('path');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function seed() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    const username = 'nuru';
    const password = 'nuru@123';
    const passwordHash = await bcrypt.hash(password, 10);
    const now = new Date().toISOString().slice(0, 23).replace('T', ' ');

    const [existing] = await connection.execute(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [username],
    );

    if (existing.length > 0) {
      await connection.execute(
        `UPDATE users
         SET password_hash = ?, updated_at = ?
         WHERE username = ?`,
        [passwordHash, now, username],
      );
      console.log(`Updated user "${username}".`);
    } else {
      await connection.execute(
        `INSERT INTO users (id, username, password_hash, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?)`,
        [uuidv4(), username, passwordHash, now, now],
      );
      console.log(`Created user "${username}".`);
    }
  } finally {
    await connection.end();
  }
}

seed().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
