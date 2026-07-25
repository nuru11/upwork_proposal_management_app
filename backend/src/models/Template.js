const { toIso } = require('./User');
const { toMysqlDatetime } = require('./Proposal');

function fromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    body: row.body,
    language: row.language,
    isFavorite: Boolean(row.is_favorite),
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    deletedAt: toIso(row.deleted_at),
  };
}

function toDbColumns(payload) {
  return {
    name: payload.name,
    body: payload.body,
    language: payload.language,
    is_favorite: payload.isFavorite ? 1 : 0,
    created_at: toMysqlDatetime(payload.createdAt),
    updated_at: toMysqlDatetime(payload.updatedAt),
  };
}

module.exports = {
  fromRow,
  toDbColumns,
};
