const { query } = require('../config/db');
const Template = require('../models/Template');
const { toMysqlDatetime } = require('../models/Proposal');

async function list(userId) {
  const rows = await query(
    `SELECT * FROM templates
     WHERE user_id = ? AND deleted_at IS NULL
     ORDER BY is_favorite DESC, updated_at DESC`,
    [userId],
  );
  return rows.map(Template.fromRow);
}

async function getById(userId, id) {
  const rows = await query(
    `SELECT * FROM templates
     WHERE id = ? AND user_id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [id, userId],
  );
  return Template.fromRow(rows[0]);
}

async function create(userId, payload) {
  if (!payload.id || !payload.name || !payload.body) {
    const err = new Error('id, name, and body are required');
    err.status = 400;
    throw err;
  }

  const cols = Template.toDbColumns({
    ...payload,
    language: payload.language || 'english',
    isFavorite: Boolean(payload.isFavorite),
    createdAt: payload.createdAt || new Date().toISOString(),
    updatedAt: payload.updatedAt || new Date().toISOString(),
  });

  await query(
    `INSERT INTO templates (
      id, user_id, name, body, language, is_favorite,
      created_at, updated_at, deleted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      body = VALUES(body),
      language = VALUES(language),
      is_favorite = VALUES(is_favorite),
      updated_at = VALUES(updated_at),
      deleted_at = NULL`,
    [
      payload.id,
      userId,
      cols.name,
      cols.body,
      cols.language,
      cols.is_favorite,
      cols.created_at,
      cols.updated_at,
    ],
  );

  return getById(userId, payload.id);
}

async function update(userId, id, payload) {
  const existing = await getById(userId, id);
  if (!existing) {
    const err = new Error('Template not found');
    err.status = 404;
    throw err;
  }

  const merged = {
    ...existing,
    ...payload,
    id,
    updatedAt: payload.updatedAt || new Date().toISOString(),
  };
  const cols = Template.toDbColumns(merged);

  await query(
    `UPDATE templates SET
      name = ?, body = ?, language = ?, is_favorite = ?,
      updated_at = ?, deleted_at = NULL
     WHERE id = ? AND user_id = ?`,
    [
      cols.name,
      cols.body,
      cols.language,
      cols.is_favorite,
      cols.updated_at,
      id,
      userId,
    ],
  );

  return getById(userId, id);
}

async function remove(userId, id) {
  const existing = await getById(userId, id);
  if (!existing) {
    const err = new Error('Template not found');
    err.status = 404;
    throw err;
  }

  const deletedAt = toMysqlDatetime(new Date().toISOString());
  await query(
    `UPDATE templates
     SET deleted_at = ?, updated_at = ?
     WHERE id = ? AND user_id = ?`,
    [deletedAt, deletedAt, id, userId],
  );
}

async function listAllForSync(userId) {
  const rows = await query(
    `SELECT * FROM templates WHERE user_id = ? ORDER BY updated_at DESC`,
    [userId],
  );
  return rows.map(Template.fromRow);
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  listAllForSync,
};
