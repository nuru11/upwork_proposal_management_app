import { api, buildQuery } from './client';

export function listProposals(filters = {}) {
  return api(`/proposals${buildQuery(filters)}`);
}

export function getProposal(id) {
  return api(`/proposals/${id}`);
}

export function createProposal(payload) {
  return api('/proposals', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateProposal(id, payload) {
  return api(`/proposals/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function deleteProposal(id) {
  return api(`/proposals/${id}`, { method: 'DELETE' });
}
