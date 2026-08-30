const PLACEHOLDER_RE = /\[[^\]]+\]/g;

/** Unique `[placeholder]` tokens in first-seen order. */
export function extractPlaceholders(body) {
  const seen = new Set();
  const out = [];
  const text = String(body || '');
  const re = new RegExp(PLACEHOLDER_RE.source, 'g');
  let match = re.exec(text);
  while (match) {
    if (!seen.has(match[0])) {
      seen.add(match[0]);
      out.push(match[0]);
    }
    match = re.exec(text);
  }
  return out;
}

/** Replace filled tokens. Empty values leave the `[token]` in place. */
export function applyPlaceholders(body, values) {
  let out = String(body || '');
  for (const [key, value] of Object.entries(values || {})) {
    const trimmed = String(value || '').trim();
    if (!trimmed) continue;
    out = out.split(key).join(trimmed);
  }
  return out;
}

export function placeholderLabel(token) {
  return token.startsWith('[') && token.endsWith(']')
    ? token.slice(1, -1)
    : token;
}

export function isClientNamePlaceholder(token) {
  return String(token).toLowerCase().includes('client name');
}

/** Ordered `{ text }` / `{ token }` segments for inline rendering. */
export function splitTemplate(body) {
  const text = String(body || '');
  const out = [];
  const re = new RegExp(PLACEHOLDER_RE.source, 'g');
  let last = 0;
  let match = re.exec(text);
  while (match) {
    if (match.index > last) {
      out.push({ text: text.slice(last, match.index) });
    }
    out.push({ token: match[0] });
    last = match.index + match[0].length;
    match = re.exec(text);
  }
  if (last < text.length) {
    out.push({ text: text.slice(last) });
  }
  return out;
}
