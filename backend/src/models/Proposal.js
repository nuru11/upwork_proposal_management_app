const { toIso } = require('./User');

function fromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    title: row.title,
    clientName: row.client_name,
    jobUrl: row.job_url,
    body: row.body,
    language: row.language,
    status: row.status,
    templateId: row.template_id,
    notes: row.notes,
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    submittedAt: toIso(row.submitted_at),
    deletedAt: toIso(row.deleted_at),
  };
}

function toDbColumns(payload) {
  return {
    title: payload.title,
    client_name: payload.clientName ?? null,
    job_url: payload.jobUrl ?? null,
    body: payload.body,
    language: payload.language,
    status: payload.status,
    template_id: payload.templateId ?? null,
    notes: payload.notes ?? null,
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
  fromRow,
  toDbColumns,
  toMysqlDatetime,
};
