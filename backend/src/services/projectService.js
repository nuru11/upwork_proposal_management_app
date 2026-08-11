const { query } = require('../config/db');
const Project = require('../models/Project');
const { toMysqlDatetime } = require('../models/Proposal');

function hasAtLeastOneUrl(payload) {
  return Boolean(
    (payload.playStoreUrl && String(payload.playStoreUrl).trim()) ||
      (payload.appStoreUrl && String(payload.appStoreUrl).trim()) ||
      (payload.webUrl && String(payload.webUrl).trim()),
  );
}

function validateTypes(types) {
  const normalized = Project.normalizeTypes(types);
  if (normalized.length === 0) {
    const err = new Error('At least one valid type is required');
    err.status = 400;
    throw err;
  }
  return normalized;
}

async function list(userId, { type } = {}) {
  const where = ['user_id = ?', 'deleted_at IS NULL'];
  const params = [userId];

  if (type) {
    if (!Project.ALLOWED_TYPES.has(type)) {
      const err = new Error(`Invalid type filter: ${type}`);
      err.status = 400;
      throw err;
    }
    where.push('JSON_CONTAINS(types, ?)');
    params.push(JSON.stringify(type));
  }

  const rows = await query(
    `SELECT * FROM projects
     WHERE ${where.join(' AND ')}
     ORDER BY updated_at DESC`,
    params,
  );
  return rows.map(Project.fromRow);
}

async function getById(userId, id) {
  const rows = await query(
    `SELECT * FROM projects
     WHERE id = ? AND user_id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [id, userId],
  );
  return Project.fromRow(rows[0]);
}

async function create(userId, payload) {
  if (!payload.id || !payload.name) {
    const err = new Error('id and name are required');
    err.status = 400;
    throw err;
  }
  if (!hasAtLeastOneUrl(payload)) {
    const err = new Error(
      'At least one of playStoreUrl, appStoreUrl, or webUrl is required',
    );
    err.status = 400;
    throw err;
  }

  const types = validateTypes(payload.types);

  const cols = Project.toDbColumns({
    ...payload,
    types,
    createdAt: payload.createdAt || new Date().toISOString(),
    updatedAt: payload.updatedAt || new Date().toISOString(),
  });

  await query(
    `INSERT INTO projects (
      id, user_id, name, description, play_store_url, app_store_url, web_url, types,
      created_at, updated_at, deleted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      description = VALUES(description),
      play_store_url = VALUES(play_store_url),
      app_store_url = VALUES(app_store_url),
      web_url = VALUES(web_url),
      types = VALUES(types),
      updated_at = VALUES(updated_at),
      deleted_at = NULL`,
    [
      payload.id,
      userId,
      cols.name,
      cols.description,
      cols.play_store_url,
      cols.app_store_url,
      cols.web_url,
      cols.types,
      cols.created_at,
      cols.updated_at,
    ],
  );

  return getById(userId, payload.id);
}

async function update(userId, id, payload) {
  const existing = await getById(userId, id);
  if (!existing) {
    const err = new Error('Project not found');
    err.status = 404;
    throw err;
  }

  const merged = {
    ...existing,
    ...payload,
    id,
    updatedAt: payload.updatedAt || new Date().toISOString(),
  };
  if (!hasAtLeastOneUrl(merged)) {
    const err = new Error(
      'At least one of playStoreUrl, appStoreUrl, or webUrl is required',
    );
    err.status = 400;
    throw err;
  }

  const types = validateTypes(merged.types);
  const cols = Project.toDbColumns({ ...merged, types });

  await query(
    `UPDATE projects SET
      name = ?, description = ?, play_store_url = ?, app_store_url = ?, web_url = ?,
      types = ?, updated_at = ?, deleted_at = NULL
     WHERE id = ? AND user_id = ?`,
    [
      cols.name,
      cols.description,
      cols.play_store_url,
      cols.app_store_url,
      cols.web_url,
      cols.types,
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
    const err = new Error('Project not found');
    err.status = 404;
    throw err;
  }

  const deletedAt = toMysqlDatetime(new Date().toISOString());
  await query(
    `UPDATE projects
     SET deleted_at = ?, updated_at = ?
     WHERE id = ? AND user_id = ?`,
    [deletedAt, deletedAt, id, userId],
  );
}

async function listAllForSync(userId) {
  const rows = await query(
    `SELECT * FROM projects WHERE user_id = ? ORDER BY updated_at DESC`,
    [userId],
  );
  return rows.map(Project.fromRow);
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  listAllForSync,
};
