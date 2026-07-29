import { api, buildQuery } from './client';

export function listProjects(filters = {}) {
  return api(`/projects${buildQuery(filters)}`);
}

export function getProject(id) {
  return api(`/projects/${id}`);
}

export function createProject(payload) {
  return api('/projects', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateProject(id, payload) {
  return api(`/projects/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function deleteProject(id) {
  return api(`/projects/${id}`, { method: 'DELETE' });
}
