const DEFAULT_MODEL = 'gemini-3.5-flash-lite';
const MAX_OUTPUT_TOKENS = 4096;

function getApiKey() {
  return process.env.GEMINI_API_KEY || '';
}

function getModel() {
  return process.env.GEMINI_MODEL || DEFAULT_MODEL;
}

function assertConfigured() {
  if (!getApiKey()) {
    const err = new Error('AI is not configured (missing GEMINI_API_KEY)');
    err.status = 503;
    throw err;
  }
}

function stripMarkdownFences(text) {
  const trimmed = String(text || '').trim();
  const fenced = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fenced) return fenced[1].trim();
  return trimmed;
}

function parseJsonResponse(text) {
  const cleaned = stripMarkdownFences(text);
  try {
    return JSON.parse(cleaned);
  } catch {
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(cleaned.slice(start, end + 1));
    }
    const err = new Error('AI returned invalid JSON');
    err.status = 502;
    throw err;
  }
}

/**
 * Call Gemini generateContent and parse the response as JSON.
 * @param {string} prompt
 * @returns {Promise<object>}
 */
async function generateJson(prompt) {
  assertConfigured();

  const model = getModel();
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(model)}:generateContent`;

  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': getApiKey(),
      },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: MAX_OUTPUT_TOKENS,
          responseMimeType: 'application/json',
        },
      }),
    });
  } catch (e) {
    const err = new Error(`Failed to reach Gemini: ${e.message}`);
    err.status = 502;
    throw err;
  }

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message =
      payload?.error?.message ||
      `Gemini request failed (${response.status})`;
    const err = new Error(message);
    err.status = response.status >= 500 ? 502 : 400;
    throw err;
  }

  const text =
    payload?.candidates?.[0]?.content?.parts
      ?.map((p) => p.text || '')
      .join('') || '';

  if (!text.trim()) {
    const err = new Error('Gemini returned an empty response');
    err.status = 502;
    throw err;
  }

  return parseJsonResponse(text);
}

module.exports = {
  generateJson,
  assertConfigured,
  getModel,
};
