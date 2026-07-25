function toPublic(row) {
  if (!row) return null;
  return {
    id: row.id,
    username: row.username,
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
  };
}

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const normalized = String(value).includes('T')
    ? String(value)
    : String(value).replace(' ', 'T');
  return new Date(normalized).toISOString();
}

module.exports = {
  toPublic,
  toIso,
};
