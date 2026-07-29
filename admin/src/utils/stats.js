import { STATUSES, LANGUAGES } from '../constants/enums';

export function computeStats(proposals, templates = []) {
  const templateNameById = Object.fromEntries(
    templates.map((t) => [t.id, t.name]),
  );

  const total = proposals.length;
  const hired = proposals.filter((p) => p.status === 'hired').length;

  const byStatus = Object.fromEntries(STATUSES.map((s) => [s.value, 0]));
  proposals.forEach((p) => {
    if (byStatus[p.status] != null) {
      byStatus[p.status] += 1;
    }
  });

  const byLanguage = Object.fromEntries(
    LANGUAGES.map((l) => [l.value, { total: 0, hired: 0 }]),
  );
  proposals.forEach((p) => {
    const key = p.language in byLanguage ? p.language : 'english';
    byLanguage[key].total += 1;
    if (p.status === 'hired') {
      byLanguage[key].hired += 1;
    }
  });

  const templateMap = new Map();
  proposals.forEach((p) => {
    const key = p.templateId || '__none__';
    if (!templateMap.has(key)) {
      templateMap.set(key, { templateId: p.templateId || null, total: 0, hired: 0 });
    }
    const row = templateMap.get(key);
    row.total += 1;
    if (p.status === 'hired') {
      row.hired += 1;
    }
  });

  const byTemplate = [...templateMap.values()]
    .map((row) => ({
      ...row,
      name: row.templateId
        ? templateNameById[row.templateId] || 'Unknown template'
        : 'No template',
    }))
    .sort((a, b) => b.total - a.total);

  return {
    overall: { total, hired },
    hireRate: total === 0 ? null : hired / total,
    byStatus,
    byLanguage,
    byTemplate,
  };
}

export function formatPercent(hired, total) {
  if (!total) return '—';
  return `${Math.round((hired / total) * 100)}%`;
}
