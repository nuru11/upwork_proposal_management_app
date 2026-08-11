const { query } = require('../config/db');
const AiDraft = require('../models/AiDraft');
const { toMysqlDatetime } = require('../models/Proposal');
const { ALLOWED_DOMAINS } = require('./aiProposalService');

function httpError(status, message) {
  const err = new Error(message);
  err.status = status;
  throw err;
}

function titleFromJob(jobDescription) {
  const line = String(jobDescription || '')
    .split(/\r?\n/)
    .map((s) => s.trim())
    .find((s) => s.length > 0);
  if (!line) return 'Untitled AI draft';
  return line.length > 80 ? `${line.slice(0, 77)}...` : line;
}

function normalizePayload(payload, existing = {}) {
  const jobDescription = String(
    payload.jobDescription ?? existing.jobDescription ?? '',
  ).trim();
  const body = String(payload.body ?? existing.body ?? '').trim();
  if (!body) {
    httpError(400, 'body is required');
  }

  const language = String(payload.language ?? existing.language ?? 'english')
    .trim()
    .toLowerCase();
  if (language !== 'english' && language !== 'arabic') {
    httpError(400, 'language must be english or arabic');
  }

  const domain = String(payload.domain ?? existing.domain ?? 'other')
    .trim();
  if (!ALLOWED_DOMAINS.has(domain)) {
    httpError(400, `Invalid domain. Allowed: ${[...ALLOWED_DOMAINS].join(', ')}`);
  }

  let title = String(payload.title ?? existing.title ?? '').trim();
  if (!title) title = titleFromJob(jobDescription);

  return {
    title,
    jobDescription,
    notes: payload.notes != null ? String(payload.notes).trim() || null : existing.notes ?? null,
    domain,
    language,
    issues: AiDraft.parseJsonArray(payload.issues ?? existing.issues),
    solutions: AiDraft.parseJsonArray(payload.solutions ?? existing.solutions),
    body,
    clientName:
      payload.clientName != null
        ? String(payload.clientName).trim() || null
        : existing.clientName ?? null,
    createdAt: payload.createdAt || existing.createdAt || new Date().toISOString(),
    updatedAt: payload.updatedAt || new Date().toISOString(),
  };
}

async function list(userId) {
  const rows = await query(
    `SELECT * FROM ai_drafts
     WHERE user_id = ? AND deleted_at IS NULL
     ORDER BY updated_at DESC`,
    [userId],
  );
  return rows.map(AiDraft.fromRow);
}

async function getById(userId, id) {
  const rows = await query(
    `SELECT * FROM ai_drafts
     WHERE id = ? AND user_id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [id, userId],
  );
  return AiDraft.fromRow(rows[0]);
}

async function create(userId, payload) {
  if (!payload.id) {
    httpError(400, 'id is required');
  }

  const normalized = normalizePayload(payload);
  const cols = AiDraft.toDbColumns(normalized);

  await query(
    `INSERT INTO ai_drafts (
      id, user_id, title, job_description, notes, domain, language,
      issues, solutions, body, client_name, created_at, updated_at, deleted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      job_description = VALUES(job_description),
      notes = VALUES(notes),
      domain = VALUES(domain),
      language = VALUES(language),
      issues = VALUES(issues),
      solutions = VALUES(solutions),
      body = VALUES(body),
      client_name = VALUES(client_name),
      updated_at = VALUES(updated_at),
      deleted_at = NULL`,
    [
      payload.id,
      userId,
      cols.title,
      cols.job_description,
      cols.notes,
      cols.domain,
      cols.language,
      cols.issues,
      cols.solutions,
      cols.body,
      cols.client_name,
      cols.created_at,
      cols.updated_at,
    ],
  );

  return getById(userId, payload.id);
}

async function update(userId, id, payload) {
  const existing = await getById(userId, id);
  if (!existing) {
    httpError(404, 'AI draft not found');
  }

  const normalized = normalizePayload(payload, existing);
  const cols = AiDraft.toDbColumns({ ...normalized, id });

  await query(
    `UPDATE ai_drafts SET
      title = ?, job_description = ?, notes = ?, domain = ?, language = ?,
      issues = ?, solutions = ?, body = ?, client_name = ?,
      updated_at = ?, deleted_at = NULL
     WHERE id = ? AND user_id = ?`,
    [
      cols.title,
      cols.job_description,
      cols.notes,
      cols.domain,
      cols.language,
      cols.issues,
      cols.solutions,
      cols.body,
      cols.client_name,
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
    httpError(404, 'AI draft not found');
  }

  const deletedAt = toMysqlDatetime(new Date().toISOString());
  await query(
    `UPDATE ai_drafts
     SET deleted_at = ?, updated_at = ?
     WHERE id = ? AND user_id = ?`,
    [deletedAt, deletedAt, id, userId],
  );
}

async function listAllForSync(userId) {
  const rows = await query(
    `SELECT * FROM ai_drafts WHERE user_id = ? ORDER BY updated_at DESC`,
    [userId],
  );
  return rows.map(AiDraft.fromRow);
}

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  listAllForSync,
  titleFromJob,
};
