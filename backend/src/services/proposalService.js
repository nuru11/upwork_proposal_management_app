const { query } = require('../config/db');
const Proposal = require('../models/Proposal');

async function list(userId, { status, language, search } = {}) {
  const where = ['user_id = ?', 'deleted_at IS NULL'];
  const params = [userId];

  if (status) {
    where.push('status = ?');
    params.push(status);
  }
  if (language) {
    where.push('language = ?');
    params.push(language);
  }
  if (search && search.trim()) {
    where.push('(title LIKE ? OR client_name LIKE ? OR body LIKE ?)');
    const q = `%${search.trim()}%`;
    params.push(q, q, q);
  }

  const rows = await query(
    `SELECT * FROM proposals
     WHERE ${where.join(' AND ')}
     ORDER BY updated_at DESC`,
    params,
  );
  return rows.map(Proposal.fromRow);
}

async function getById(userId, id) {
  const rows = await query(
    `SELECT * FROM proposals
     WHERE id = ? AND user_id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [id, userId],
  );
  return Proposal.fromRow(rows[0]);
}

async function create(userId, payload) {
  if (!payload.id || !payload.title || !payload.body) {
    const err = new Error('id, title, and body are required');
    err.status = 400;
    throw err;
  }

  const cols = Proposal.toDbColumns({
    ...payload,
    language: payload.language || 'english',
    status: payload.status || 'submitted',
    createdAt: payload.createdAt || new Date().toISOString(),
    updatedAt: payload.updatedAt || new Date().toISOString(),
  });

  await query(
    `INSERT INTO proposals (
      id, user_id, title, client_name, job_url, body, language, status,
      template_id, notes, created_at, updated_at, submitted_at, deleted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      client_name = VALUES(client_name),
      job_url = VALUES(job_url),
      body = VALUES(body),
      language = VALUES(language),
      status = VALUES(status),
      template_id = VALUES(template_id),
      notes = VALUES(notes),
      updated_at = VALUES(updated_at),
      submitted_at = VALUES(submitted_at),
      deleted_at = NULL`,
    [
      payload.id,
      userId,
      cols.title,
      cols.client_name,
      cols.job_url,
      cols.body,
      cols.language,
      cols.status,
      cols.template_id,
      cols.notes,
      cols.created_at,
      cols.updated_at,
      cols.submitted_at,
    ],
  );

  return getById(userId, payload.id);
}

async function update(userId, id, payload) {
  const existing = await getById(userId, id);
  if (!existing) {
    const err = new Error('Proposal not found');
    err.status = 404;
    throw err;
  }

  const merged = {
    ...existing,
    ...payload,
    id,
    updatedAt: payload.updatedAt || new Date().toISOString(),
  };
  const cols = Proposal.toDbColumns(merged);

  await query(
    `UPDATE proposals SET
      title = ?, client_name = ?, job_url = ?, body = ?, language = ?,
      status = ?, template_id = ?, notes = ?, updated_at = ?, submitted_at = ?,
      deleted_at = NULL
     WHERE id = ? AND user_id = ?`,
    [
      cols.title,
      cols.client_name,
      cols.job_url,
      cols.body,
      cols.language,
      cols.status,
      cols.template_id,
      cols.notes,
      cols.updated_at,
      cols.submitted_at,
      id,
      userId,
    ],
  );

  return getById(userId, id);
}

async function remove(userId, id) {
  const existing = await getById(userId, id);
  if (!existing) {
    const err = new Error('Proposal not found');
    err.status = 404;
    throw err;
  }

  const deletedAt = Proposal.toMysqlDatetime(new Date().toISOString());
  await query(
    `UPDATE proposals
     SET deleted_at = ?, updated_at = ?
     WHERE id = ? AND user_id = ?`,
    [deletedAt, deletedAt, id, userId],
  );
}

async function listAllForSync(userId) {
  const rows = await query(
    `SELECT * FROM proposals WHERE user_id = ? ORDER BY updated_at DESC`,
    [userId],
  );
  return rows.map(Proposal.fromRow);
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  listAllForSync,
};
