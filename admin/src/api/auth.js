import { api } from './client';

export function login(username, password) {
  return api('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}
