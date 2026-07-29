const { toIso } = require('./User');
const { toMysqlDatetime } = require('./Proposal');

const ALLOWED_TYPES = new Set([
  'ecommerce',
  'marketplace',
  'elearning',
  'booking',
  'social',
  'delivery',
  'fintech',
  'healthcare',
  'gaming',
  'other',
]);

function parseTypes(value) {
  if (Array.isArray(value)) {
    return value.map(String);
  }
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed.map(String) : ['other'];
    } catch (_) {
      return ['other'];
    }
  }
  return ['other'];
}

function normalizeTypes(types) {
  const unique = [];
  for (const raw of parseTypes(types)) {
    if (ALLOWED_TYPES.has(raw) && !unique.includes(raw)) {
      unique.push(raw);
    }
  }
  return unique;
}

function fromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    playStoreUrl: row.play_store_url || null,
    appStoreUrl: row.app_store_url || null,
    webUrl: row.web_url || null,
    types: normalizeTypes(row.types),
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    deletedAt: toIso(row.deleted_at),
  };
}

function toDbColumns(payload) {
  const types = normalizeTypes(payload.types);
  return {
    name: payload.name,
    play_store_url: payload.playStoreUrl || null,
    app_store_url: payload.appStoreUrl || null,
    web_url: payload.webUrl || null,
    types: JSON.stringify(types.length > 0 ? types : ['other']),
    created_at: toMysqlDatetime(payload.createdAt),
    updated_at: toMysqlDatetime(payload.updatedAt),
  };
}

module.exports = {
  ALLOWED_TYPES,
  normalizeTypes,
  fromRow,
  toDbColumns,
};
