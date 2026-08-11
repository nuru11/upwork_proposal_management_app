const { toIso } = require('./User');
const { toMysqlDatetime } = require('./Proposal');

function parseJsonArray(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

function fromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    title: row.title,
    jobDescription: row.job_description || '',
    notes: row.notes || null,
    domain: row.domain,
    language: row.language,
    issues: parseJsonArray(row.issues),
    solutions: parseJsonArray(row.solutions),
    body: row.body || '',
    clientName: row.client_name || null,
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    deletedAt: toIso(row.deleted_at),
  };
}

function toDbColumns(payload) {
  return {
    title: payload.title,
    job_description: payload.jobDescription || '',
    notes: payload.notes || null,
    domain: payload.domain,
    language: payload.language,
    issues: JSON.stringify(parseJsonArray(payload.issues)),
    solutions: JSON.stringify(parseJsonArray(payload.solutions)),
    body: payload.body || '',
    client_name: payload.clientName || null,
    created_at: toMysqlDatetime(payload.createdAt),
    updated_at: toMysqlDatetime(payload.updatedAt),
  };
}

module.exports = {
  fromRow,
  toDbColumns,
  parseJsonArray,
};
