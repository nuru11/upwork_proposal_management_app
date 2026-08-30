const { randomUUID } = require('crypto');
const geminiClient = require('./geminiClient');

const MAX_JOB_DESCRIPTION_LENGTH = 8000;
const MAX_NOTES_LENGTH = 2000;
const MAX_MENTION_NOTE_LENGTH = 500;
const ALLOWED_DOMAINS = new Set([
  'ecommerce',
  'marketplace',
  'elearning',
  'booking',
  'social',
  'delivery',
  'fintech',
  'healthcare',
  'gaming',
  'restaurant',
  'realEstate',
  'saas',
  'logistics',
  'travel',
  'fitness',
  'agency',
  'other',
]);

function httpError(status, message) {
  const err = new Error(message);
  err.status = status;
  return err;
}

function normalizeJobDescription(raw) {
  if (raw == null || typeof raw !== 'string' || !raw.trim()) {
    throw httpError(400, 'jobDescription is required');
  }
  const trimmed = raw.trim();
  if (trimmed.length > MAX_JOB_DESCRIPTION_LENGTH) {
    throw httpError(
      400,
      `jobDescription must be at most ${MAX_JOB_DESCRIPTION_LENGTH} characters`,
    );
  }
  return trimmed;
}

function normalizeDomain(raw) {
  const domain = String(raw || 'other').trim().toLowerCase();
  if (!ALLOWED_DOMAINS.has(domain)) {
    throw httpError(400, `Invalid domain. Allowed: ${[...ALLOWED_DOMAINS].join(', ')}`);
  }
  return domain;
}

function normalizeLanguage(raw) {
  const language = String(raw || 'english').trim().toLowerCase();
  if (language !== 'english' && language !== 'arabic') {
    throw httpError(400, 'language must be english or arabic');
  }
  return language;
}

function normalizeNotes(raw) {
  if (raw == null) return '';
  const trimmed = String(raw).trim();
  if (!trimmed) return '';
  if (trimmed.length > MAX_NOTES_LENGTH) {
    throw httpError(
      400,
      `notes must be at most ${MAX_NOTES_LENGTH} characters`,
    );
  }
  return trimmed;
}

function guidanceBlock(notes) {
  if (!notes) return '';
  return `
Extra guidance from the freelancer (must follow when relevant):
"""
${notes}
"""
`;
}

function normalizeIssues(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw httpError(400, 'issues must be a non-empty array');
  }
  return raw.map((item, index) => {
    if (!item || typeof item !== 'object') {
      throw httpError(400, `issues[${index}] is invalid`);
    }
    const title = String(item.title || '').trim();
    if (!title) {
      throw httpError(400, `issues[${index}].title is required`);
    }
    return {
      id: String(item.id || randomUUID()),
      title,
      whyItFails: String(item.whyItFails || '').trim(),
    };
  });
}

function normalizeSolutions(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw httpError(400, 'solutions must be a non-empty array');
  }
  return raw.map((item, index) => {
    if (!item || typeof item !== 'object') {
      throw httpError(400, `solutions[${index}] is invalid`);
    }
    const offer = String(item.offer || '').trim();
    if (!offer) {
      throw httpError(400, `solutions[${index}].offer is required`);
    }
    return {
      issueId: String(item.issueId || ''),
      issueTitle: String(item.issueTitle || '').trim(),
      offer,
    };
  });
}

function normalizeMentionNote(raw) {
  if (raw == null) return null;
  const trimmed = String(raw).trim();
  if (!trimmed) return null;
  return trimmed.slice(0, MAX_MENTION_NOTE_LENGTH);
}

function normalizeProjects(raw) {
  if (raw == null) return [];
  if (!Array.isArray(raw)) {
    throw httpError(400, 'projects must be an array');
  }
  return raw.slice(0, 10).map((item) => ({
    name: String(item?.name || '').trim(),
    description: item?.description ? String(item.description).trim() || null : null,
    types: Array.isArray(item?.types)
      ? item.types.map(String)
      : [],
    playStoreUrl: item?.playStoreUrl ? String(item.playStoreUrl) : null,
    appStoreUrl: item?.appStoreUrl ? String(item.appStoreUrl) : null,
    webUrl: item?.webUrl ? String(item.webUrl) : null,
    describe: Boolean(item?.describe),
    mentionNote: normalizeMentionNote(item?.mentionNote),
  })).filter((p) => p.name);
}

function assignIssueIds(issues) {
  return (issues || []).map((issue) => ({
    id: String(issue.id || randomUUID()),
    title: String(issue.title || '').trim(),
    whyItFails: String(issue.whyItFails || '').trim(),
  })).filter((i) => i.title);
}

async function extractIssues({ jobDescription, domain, language, notes }) {
  const job = normalizeJobDescription(jobDescription);
  const domainNorm = normalizeDomain(domain);
  const lang = normalizeLanguage(language);
  const notesNorm = normalizeNotes(notes);

  const prompt = `You help a freelance developer write Upwork proposals.
Analyze this job posting for a ${domainNorm} project and extract 3 to 5 common failure points or client fears that typically sink this kind of project. Prefer issues that are relevant to THIS posting when possible (e.g. UX complexity, notifications, performance/speed, payments, trust/safety).

Job posting:
"""
${job}
"""
${guidanceBlock(notesNorm)}
Respond with JSON only in this exact shape:
{
  "issues": [
    { "title": "short issue name", "whyItFails": "one sentence why this matters for this job" }
  ]
}

Language for title and whyItFails: ${lang}.
Do not invent client names or fake requirements not implied by the job.`;

  const result = await geminiClient.generateJson(prompt);
  const issues = assignIssueIds(result.issues);
  if (issues.length === 0) {
    throw httpError(502, 'AI returned no issues');
  }
  return { issues };
}

async function suggestSolutions({ jobDescription, domain, issues, notes }) {
  const job = normalizeJobDescription(jobDescription);
  const domainNorm = normalizeDomain(domain);
  const issuesNorm = normalizeIssues(issues);
  const notesNorm = normalizeNotes(notes);

  const prompt = `You help a freelance developer write Upwork proposals.
For each issue below, write a concrete solution/offer the developer would deliver (specific actions, not vague fluff). Keep each offer to 1–3 sentences.

Domain: ${domainNorm}

Job posting:
"""
${job}
"""
${guidanceBlock(notesNorm)}
Issues (JSON):
${JSON.stringify(issuesNorm, null, 2)}

Respond with JSON only in this exact shape:
{
  "solutions": [
    {
      "issueId": "same id as input",
      "issueTitle": "same title as input",
      "offer": "concrete solution to offer"
    }
  ]
}

Include exactly one solution per input issue, preserving issueId and issueTitle.`;

  const result = await geminiClient.generateJson(prompt);
  const byId = new Map(
    (result.solutions || []).map((s) => [String(s.issueId || ''), s]),
  );

  const solutions = issuesNorm.map((issue) => {
    const fromAi = byId.get(issue.id);
    const offer = String(fromAi?.offer || '').trim();
    if (!offer) {
      throw httpError(502, `AI missing solution for issue ${issue.id}`);
    }
    return {
      issueId: issue.id,
      issueTitle: issue.title,
      offer,
    };
  });

  return { solutions };
}

async function draftProposal({
  jobDescription,
  domain,
  language,
  issues,
  solutions,
  projects,
  templateBody,
  inspiredFrom,
  clientName,
  notes,
}) {
  const job = normalizeJobDescription(jobDescription);
  const domainNorm = normalizeDomain(domain);
  const lang = normalizeLanguage(language);
  const issuesNorm = normalizeIssues(issues);
  const solutionsNorm = normalizeSolutions(solutions);
  const projectsNorm = normalizeProjects(projects);
  const notesNorm = normalizeNotes(notes);
  const template = templateBody ? String(templateBody).trim().slice(0, 4000) : '';
  const inspired = inspiredFrom ? String(inspiredFrom).trim().slice(0, 4000) : '';
  const client = clientName ? String(clientName).trim().slice(0, 120) : '';

  const templateRules = [
    template
      ? '- If a template skeleton is provided, match its structure and fill every [placeholder] for this job. Do not leave bracket placeholders in the output.'
      : '',
    inspired
      ? '- If an inspired-from example is provided, match its tone and flow. Do not copy names, metrics, or project specifics from that example.'
      : '',
  ]
    .filter(Boolean)
    .join('\n');

  const prompt = `You write short, high-converting Upwork cover letters for a freelance developer.

Write a problem-first proposal in this structure:
1. Hook: acknowledge the real risks / issues for this ${domainNorm} job
2. For each issue: briefly state the issue and your concrete solution
3. Proof: mention every project from the list below by name. Follow each project's describe / mentionNote flags:
   - If describe is false: mention the project by name and include a store/web URL when provided. Do not copy, paraphrase, or expand the stored description.
   - If describe is true: rewrite how the project is relevant to THIS job. Do not paste or lightly rephrase the stored description. Use it as source material, then connect it to the posting (e.g. if the job is security-related and the project involved security work, explain how you improved that app's security). Never invent work that is not in the description or mentionNote.
   - Always honor mentionNote when present (even if describe is false — use it as a short hint, not a long paragraph).
4. Clear CTA (short call to discuss approach / timeline)

Rules:
- Language: ${lang}
- Keep it concise (about 150–320 words; longer only if needed to mention every selected project)
- Do NOT invent metrics, years of experience, features, or apps that are not in the projects list
- Ground project proof only in the provided descriptions and mentionNotes — do not invent what a project does
- If describe is false, do not copy-paste or expand the stored description
- If projects list is empty, skip the proof section rather than fabricating
${templateRules}
${client ? `- You may address the client as ${client}` : '- Do not invent a client name'}

Job posting:
"""
${job}
"""
${guidanceBlock(notesNorm)}
Selected issues:
${JSON.stringify(issuesNorm, null, 2)}

Solutions to offer:
${JSON.stringify(solutionsNorm, null, 2)}

My relevant projects (only use these):
${JSON.stringify(projectsNorm, null, 2)}

${template ? `Template skeleton to follow (fill placeholders for this job):\n"""\n${template}\n"""` : ''}
${inspired ? `Inspired-from example (tone and flow only — do not copy specifics):\n"""\n${inspired}\n"""` : ''}

Respond with JSON only in this exact shape:
{
  "body": "full proposal cover letter text"
}`;

  const result = await geminiClient.generateJson(prompt);
  const body = String(result.body || '').trim();
  if (!body) {
    throw httpError(502, 'AI returned an empty proposal body');
  }
  return { body };
}

function projectProofRules(domainNorm) {
  return `Project proof rules (for the similar-project hook and any portfolio link):
- Mention every project from the list below by name. Follow each project's describe / mentionNote flags:
  - If describe is false: mention the project by name and include a store/web URL when provided. Do not copy, paraphrase, or expand the stored description.
  - If describe is true: rewrite how the project is relevant to THIS ${domainNorm} job. Do not paste or lightly rephrase the stored description. Use it as source material, then connect it to the posting. Never invent work that is not in the description or mentionNote.
  - Always honor mentionNote when present (even if describe is false — use it as a short hint, not a long paragraph).
- Ground project proof only in the provided descriptions and mentionNotes — do not invent what a project does`;
}

function normalizeEmptyKeys(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw httpError(400, 'emptyKeys must be a non-empty array');
  }
  const keys = raw
    .map((item) => String(item || '').trim())
    .filter((key) => key.startsWith('[') && key.endsWith(']') && key.length > 2)
    .slice(0, 40);
  if (keys.length === 0) {
    throw httpError(
      400,
      'emptyKeys must contain bracket tokens like [Core Job Challenge]',
    );
  }
  return [...new Set(keys)];
}

function normalizeFilledMap(raw) {
  if (raw == null) return {};
  if (typeof raw !== 'object' || Array.isArray(raw)) {
    throw httpError(400, 'filled must be an object');
  }
  const out = {};
  for (const [k, v] of Object.entries(raw)) {
    const key = String(k || '').trim();
    const val = String(v ?? '').trim();
    if (key && val) out[key] = val.slice(0, 800);
  }
  return out;
}

function placeholderFillRules(lang, client, domainNorm) {
  const arabic = lang === 'arabic';
  return `- If the skeleton has [X%]: one simple number in a plain sentence${arabic ? ' in Arabic' : ' (e.g. "Around 60% of users…")'}. Do not copy the inspired-from example's numbers.
- If the skeleton has [Authoritative Source]: keep it casual${arabic ? ' in Arabic (e.g. دراسات تجربة المستخدم تبين)' : ', like "UX studies show" or "research shows"'}. Do not cite a fancy report name or sound academic.
- If the skeleton has [Link to Demo / Portfolio] or [Link to Similar Project]: use a selected project URL when provided. If the projects list is empty, write a short line that you are happy to share a similar build — do not invent a URL.
- If the skeleton has [App Stack]: prefer Flutter. Use Capacitor only if the job is clearly a very small/simple app (few screens, mostly a site wrapper, no heavy native work like live GPS or matching). Fill [App Stack Reason] in plain talk (fast, one codebase, good for this project type).
- If the skeleton has [Backend Stack]: prefer Node.js unless the posting clearly requires something else.
- If the skeleton has [Hosting Suggestion]: pick what fits THIS job's stage. Early / MVP / cost-sensitive → VPS now, cloud later. If they already need scale or name a cloud, recommend that instead. Do not invent a budget. Keep it to one short sentence.
- If the skeleton has [Similar App Type] or [Concrete Outcome From That Build]: describe a similar shipped app in plain talk using selected projects when available. Concrete outcomes only (2-tap book, map that keeps updating). Do not invent metrics, years of experience, or a named app that is not in the projects list.
- If the skeleton has [X]: use the number of selected projects (1, 2, 3…). If the projects list is empty, write "founders" / "apps like this"${arabic ? ' (Arabic: أصحاب تطبيقات / تطبيقات زي كذا — use ٢ / ٣ when you have a real count)' : ''} — do not invent "3".
- If the skeleton has [App / startup type], [Measurable Result], or [Similar Approach]: fill a result-first opening that is concrete and job-specific (2-tap book, dual-app, store-live). No fake %, no years of experience, no named app that is not in the projects list.${arabic ? ' The Arabic opening must read as one natural sentence: ساعدت X يحقّقون [نتيجة] باستخدام [طريقة] — do not leave English word order.' : ''}
- If the skeleton has [Specific Proof From a Similar Build]: one concrete outcome from a selected project; pair it with [Link to Similar Project]. If the projects list is empty, keep the proof general and do not invent a URL.
- If the skeleton has [Shared Risk] / [Core Job Challenge]: name THIS job's real risk in plain talk (drop-off, store reject, laggy map, unclear price) — not a generic "I can help with your app".
- If the skeleton has numbered step placeholders: fill a concrete plan for THIS job. Keep each step one short line.
- If the skeleton has [Likely Objection]: pick one worry THIS client might have (two native teams, Flutter not feeling native, cost) and answer it in plain talk in the paired short-answer placeholder.
- If the skeleton has a quick-win placeholder: one change they can make on the current flow or listing today. Not "hire me". Do not invent access to their codebase.
- If the skeleton has [Business Question] or [Expert Question that baselines the work]: one short product question for THIS job (users, money, first-open path, why they leave a competitor). Not technical (no Flutter, APIs, hosting, GPS) and not timeline/budget. Easy to answer in one sentence. The client should feel that answering it baselines the work. Do not copy the inspired-from question unless it truly fits this job.
- If the skeleton has [Their Goal]: this job's goal in a few words (booking, store launch, live map, week one).
- Never invent a freelancer name. If the skeleton has [Your Name], sign off with ${arabic ? '"مع التحية،" only' : '"Best," only'}.
- ${client ? `Address the client as ${client}` : arabic ? 'If the greeting has a client-name placeholder, use something like "مرحبا،" — do not invent a client name' : 'If the greeting has a client-name placeholder, use "there" — do not invent a client name'}.
- ${projectProofRules(domainNorm)}
- If the projects list is empty, still fill the similar-project hook in general terms without inventing a named app.`;
}

function languageInstructions(lang) {
  if (lang === 'arabic') {
    return `CRITICAL: The proposal body must be written entirely in Arabic.
- Write the entire letter in simple everyday Arabic. Short sentences. Common words. Sound like a freelancer messaging a client, not a report.
- Do NOT output English sentences. The JSON "body" value must be Arabic text.
- If the skeleton or inspired-from example is already Arabic, fill placeholders and keep that Arabic flow. If they are English, translate the flow into Arabic. Never leave English sentences in the output (except project names and URLs).
- Keep project names and URLs in their original form.
- Greeting/sign-off in Arabic (e.g. مرحبا، / مع التحية،). Do not use Hi / Best.
- Do NOT use stiff or translated-from-English phrasing. Keep it warm, direct, and a bit informal.
- Keep it ~180–250 words.`;
  }

  return `Voice (must follow):
- Simple everyday English. Short sentences. Common words. Contractions are good (I've, don't, it's).
- Write like you are messaging a client, not writing a report.
- Sound human: "I recently built", "these apps mostly fail because", "from my experience", "here is how I make sure".
- Do NOT use buzzwords or stiff phrasing (no leverage, robust, seamless, cutting-edge, comprehensive, utilize, delve, landscape, furthermore, moreover, "I am writing to express").
- Do NOT stack jargon. Explain problems in plain talk (laggy map, too many clicks, prices aren't clear).
- Keep it ~180–250 words. Warm, direct, a bit informal.`;
}

async function draftProposalFromTemplate({
  jobDescription,
  domain,
  language,
  templateBody,
  inspiredFrom,
  projects,
  clientName,
  notes,
}) {
  const job = normalizeJobDescription(jobDescription);
  const domainNorm = normalizeDomain(domain);
  const lang = normalizeLanguage(language);
  const projectsNorm = normalizeProjects(projects);
  const notesNorm = normalizeNotes(notes);
  const template = templateBody ? String(templateBody).trim().slice(0, 4000) : '';
  if (!template) {
    throw httpError(400, 'templateBody is required');
  }
  const inspired = inspiredFrom ? String(inspiredFrom).trim().slice(0, 4000) : '';
  const client = clientName ? String(clientName).trim().slice(0, 120) : '';

  const arabic = lang === 'arabic';
  const prompt = `You write short Upwork cover letters that sound like a real freelancer typed them quickly — not like AI or a marketing page.

Fill the template skeleton for this ${domainNorm} job. The skeleton is the structure of record — follow its paragraphs, greeting, lists, questions, and sign-off exactly. Fill every [placeholder] for THIS job. Do NOT rewrite it as a different letter (no problem-first Hook → per-issue → Proof → CTA, and do not force a "how I solve both" / tech-stack layout if the skeleton does not have those sections).

${languageInstructions(lang)}

Rules:
- Language: ${lang}${arabic ? ' (CRITICAL: body must be entirely in Arabic)' : ''}
- Fill every [placeholder] for THIS job. Do not leave bracket placeholders in the output.
- If an inspired-from example is provided, match its tone and flow only. Do not copy its names, metrics, project type, technical details, or CTA question unless they genuinely fit THIS job.${arabic ? ' Translate into Arabic; do not copy English sentences from the example or skeleton.' : ''}
${placeholderFillRules(lang, client, domainNorm)}

Job posting:
"""
${job}
"""
${guidanceBlock(notesNorm)}
My relevant projects (only use these):
${JSON.stringify(projectsNorm, null, 2)}

Template skeleton to follow (fill placeholders for this job):
"""
${template}
"""
${inspired ? `Inspired-from example (tone and flow only — do not copy specifics):\n"""\n${inspired}\n"""` : ''}

Respond with JSON only in this exact shape:
{
  "body": "${arabic ? 'full proposal cover letter text, entirely in Arabic' : 'full proposal cover letter text'}"
}`;

  const result = await geminiClient.generateJson(prompt);
  const body = String(result.body || '').trim();
  if (!body) {
    throw httpError(502, 'AI returned an empty proposal body');
  }
  return { body };
}

async function fillTemplateFields({
  jobDescription,
  domain,
  language,
  templateBody,
  filled,
  emptyKeys,
  instructions,
  projects,
  clientName,
  notes,
}) {
  const job = normalizeJobDescription(jobDescription);
  const domainNorm = normalizeDomain(domain);
  const lang = normalizeLanguage(language);
  const template = templateBody ? String(templateBody).trim().slice(0, 4000) : '';
  if (!template) {
    throw httpError(400, 'templateBody is required');
  }
  const keys = normalizeEmptyKeys(emptyKeys);
  const filledMap = normalizeFilledMap(filled);
  const instructionsMap = normalizeFilledMap(instructions);
  const projectsNorm = normalizeProjects(projects);
  const notesNorm = normalizeNotes(notes);
  const client = clientName ? String(clientName).trim().slice(0, 120) : '';
  const arabic = lang === 'arabic';

  const prompt = `You fill individual [placeholder] values for an Upwork cover letter. Return only the requested keys — not a full letter.

${arabic
    ? 'CRITICAL: Each value must be simple everyday Arabic. Short sentences. Common words. No English sentences except project names and URLs.'
    : 'Voice: simple everyday English. Short sentences. Common words. Contractions are good (I\'ve, don\'t, it\'s).'}

Rules:
- Language: ${lang}${arabic ? ' (CRITICAL: values must be entirely in Arabic except names and URLs)' : ''}
- Fill ONLY these keys: ${JSON.stringify(keys)}
- Do not return a full proposal. Do not invent extra keys.
- Already filled by the freelancer (do not change; use as context):
${JSON.stringify(filledMap, null, 2)}
- Freelancer notes/instructions for specific keys (write the finished field from the job + this hint; do not paste the hint unless it already is the finished line):
${JSON.stringify(instructionsMap, null, 2)}
${placeholderFillRules(lang, client, domainNorm)}

Job posting:
"""
${job}
"""
${guidanceBlock(notesNorm)}
My relevant projects (only use these):
${JSON.stringify(projectsNorm, null, 2)}

Template skeleton (context only — do not rewrite it):
"""
${template}
"""

Respond with JSON only in this exact shape:
{
  "values": {
    ${keys.map((key) => `"${key.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}": "replacement text"`).join(',\n    ')}
  }
}`;

  const result = await geminiClient.generateJson(prompt);
  const rawValues = result.values;
  if (!rawValues || typeof rawValues !== 'object' || Array.isArray(rawValues)) {
    throw httpError(502, 'AI returned no field values');
  }

  const values = {};
  for (const key of keys) {
    const val = String(rawValues[key] ?? '').trim();
    if (val) values[key] = val;
  }
  if (Object.keys(values).length === 0) {
    throw httpError(502, 'AI returned empty field values');
  }
  return { values };
}

module.exports = {
  extractIssues,
  suggestSolutions,
  draftProposal,
  draftProposalFromTemplate,
  fillTemplateFields,
  ALLOWED_DOMAINS,
  MAX_JOB_DESCRIPTION_LENGTH,
};
