import { api } from './client';

export function listAiDrafts() {
  return api('/ai-drafts');
}

export function getAiDraft(id) {
  return api(`/ai-drafts/${id}`);
}

export function createAiDraft(payload) {
  return api('/ai-drafts', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateAiDraft(id, payload) {
  return api(`/ai-drafts/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function deleteAiDraft(id) {
  return api(`/ai-drafts/${id}`, { method: 'DELETE' });
}

export function titleFromJob(jobDescription) {
  const line = String(jobDescription || '')
    .split(/\r?\n/)
    .map((s) => s.trim())
    .find((s) => s.length > 0);
  if (!line) return 'Untitled AI draft';
  return line.length > 80 ? `${line.slice(0, 77)}...` : line;
}
