import { api, buildQuery } from './client';

export function listTemplates(filters = {}) {
  return api(`/templates${buildQuery(filters)}`);
}

export function getTemplate(id) {
  return api(`/templates/${id}`);
}

export function createTemplate(payload) {
  return api('/templates', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateTemplate(id, payload) {
  return api(`/templates/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function deleteTemplate(id) {
  return api(`/templates/${id}`, { method: 'DELETE' });
}