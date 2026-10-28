const { toIso } = require('./User');

const STATUS_ORDER = [
  'submitted',
  'viewed',
  'responded',
  'hired',
  'rejected',
];

const ALLOWED_STATUSES = new Set(STATUS_ORDER);

function parseStatuses(value) {
  if (Array.isArray(value)) {
    return value.map(String);
  }
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) return [];
    if (trimmed.startsWith('[')) {
      try {
        const parsed = JSON.parse(trimmed);
        return Array.isArray(parsed) ? parsed.map(String) : [trimmed];
      } catch (_) {
        return [trimmed];
      }
    }
    return [trimmed];
  }
  return [];
}

function normalizeStatuses(statuses) {
  const present = new Set(
    parseStatuses(statuses).filter((status) => ALLOWED_STATUSES.has(status)),
  );
  return STATUS_ORDER.filter((status) => present.has(status));
}

function fromRow(row) {
  if (!row) return null;
  const statuses = normalizeStatuses(row.status);
  return {
    id: row.id,
    title: row.title,
    clientName: row.client_name,
    jobUrl: row.job_url,
    jobDescription: row.job_description,
    body: row.body,
    language: row.language,
    status: statuses.length > 0 ? statuses : ['submitted'],
    projectType: row.project_type,
    templateId: row.template_id,
    notes: row.notes,
    updatedVersion: row.updated_version,
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    submittedAt: toIso(row.submitted_at),
    deletedAt: toIso(row.deleted_at),
  };
}

function toDbColumns(payload) {
  const statuses = normalizeStatuses(payload.status);
  return {
    title: payload.title,
    client_name: payload.clientName ?? null,
    job_url: payload.jobUrl ?? null,
    job_description: payload.jobDescription ?? null,
    body: payload.body,
    language: payload.language,
    status: JSON.stringify(statuses.length > 0 ? statuses : ['submitted']),
    project_type: payload.projectType,
    template_id: payload.templateId ?? null,
    notes: payload.notes ?? null,
    updated_version: payload.updatedVersion ?? null,
    created_at: toMysqlDatetime(payload.createdAt),
    updated_at: toMysqlDatetime(payload.updatedAt),
    submitted_at: toMysqlDatetime(payload.submittedAt),
  };
}

function toMysqlDatetime(value) {
  if (value == null || value === '') return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString().slice(0, 23).replace('T', ' ');
}

module.exports = {
  ALLOWED_STATUSES,
  normalizeStatuses,
  fromRow,
  toDbColumns,
  toMysqlDatetime,
};
