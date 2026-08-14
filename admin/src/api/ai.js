import { api } from './client';

export function extractIssues(payload) {
  return api('/ai/extract-issues', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function suggestSolutions(payload) {
  return api('/ai/suggest-solutions', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function draftProposal(payload) {
  return api('/ai/draft-proposal', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function draftProposalFromTemplate(payload) {
  return api('/ai/draft-proposal-from-template', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
