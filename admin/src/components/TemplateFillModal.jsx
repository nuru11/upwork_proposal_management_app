import { useEffect, useMemo, useState } from 'react';
import { fillTemplateFields, rewriteProposalLanguage } from '../api/ai';
import {
  applyPlaceholders,
  extractPlaceholders,
  isClientNamePlaceholder,
  isOptionalNamePlaceholder,
  placeholderLabel,
  stripOptionalNamePlaceholders,
} from '../utils/templatePlaceholders';

function initialValues(keys, clientName) {
  const values = {};
  const client = String(clientName || '').trim();
  for (const key of keys) {
    values[key] = client && isClientNamePlaceholder(key) ? client : '';
  }
  return values;
}

export default function TemplateFillModal({
  open,
  templateBody,
  language,
  clientName,
  notes,
  onApply,
  onCancel,
}) {
  const keys = useMemo(() => extractPlaceholders(templateBody), [templateBody]);
  const [jobDescription, setJobDescription] = useState('');
  const [values, setValues] = useState(() => initialValues(keys, clientName));
  const [busy, setBusy] = useState(false);
  const [busyKey, setBusyKey] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!open) return;
    setJobDescription('');
    setValues(initialValues(keys, clientName));
    setBusy(false);
    setBusyKey(null);
    setError('');
  }, [open, keys, clientName]);

  if (!open) return null;

  const emptyKeys = keys.filter((key) => {
    if (String(values[key] || '').trim()) return false;
    if (isOptionalNamePlaceholder(key)) return false;
    return true;
  });

  function setValue(key, value) {
    setValues((current) => ({ ...current, [key]: value }));
  }

  async function fillWithAi(keysToFill) {
    if (!keysToFill.length) return;
    const job = jobDescription.trim();
    if (!job) {
      setError('Paste a job description to fill with AI.');
      return;
    }

    const filled = {};
    for (const [key, value] of Object.entries(values)) {
      const trimmed = String(value || '').trim();
      if (trimmed && !keysToFill.includes(key)) filled[key] = trimmed;
    }

    setBusy(true);
    setBusyKey(keysToFill.length === 1 ? keysToFill[0] : null);
    setError('');
    try {
      const result = await fillTemplateFields({
        jobDescription: job,
        domain: 'other',
        language,
        templateBody,
        filled,
        emptyKeys: keysToFill,
        clientName: clientName || undefined,
        notes: notes || undefined,
      });
      const next = result?.values || {};
      setValues((current) => {
        const merged = { ...current };
        for (const key of keysToFill) {
          const val = String(next[key] || '').trim();
          if (val) merged[key] = val;
        }
        return merged;
      });
    } catch (err) {
      setError(err.message || 'Could not fill fields');
    } finally {
      setBusy(false);
      setBusyKey(null);
    }
  }

  async function handleApply() {
    let assembled = stripOptionalNamePlaceholders(
      applyPlaceholders(templateBody, values),
    );
    if (language === 'arabic') {
      setBusy(true);
      setError('');
      try {
        const result = await rewriteProposalLanguage({
          body: assembled,
          language,
        });
        assembled = String(result?.body || '').trim() || assembled;
      } catch (err) {
        setError(err.message || 'Could not rewrite to Arabic');
        setBusy(false);
        return;
      }
      setBusy(false);
    }
    onApply(assembled);
  }

  return (
    <div className="modal-backdrop" role="presentation" onClick={onCancel}>
      <div
        className="modal modal-wide"
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        <h3>Fill template fields</h3>
        <p>
          Type values yourself, or use AI for the empty ones.
          {language === 'arabic'
            ? ' The generated letter will be rewritten fully in Arabic.'
            : ''}
        </p>
        {error ? <div className="alert alert-error">{error}</div> : null}

        <label className="field">
          <span>Job description (for AI)</span>
          <textarea
            rows={4}
            value={jobDescription}
            onChange={(e) => setJobDescription(e.target.value)}
            placeholder="Paste the Upwork job posting to fill empty fields…"
            disabled={busy}
          />
        </label>

        <div className="form-actions" style={{ justifyContent: 'flex-start', marginBottom: 12 }}>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => fillWithAi(emptyKeys)}
            disabled={busy || emptyKeys.length === 0}
          >
            {busy && !busyKey
              ? 'Filling…'
              : emptyKeys.length === 0
                ? 'All fields filled'
                : `Fill empty with AI (${emptyKeys.length})`}
          </button>
        </div>

        <div className="template-fill-fields">
          {keys.map((key) => (
            <label className="field" key={key}>
              <span className="template-fill-label">
                {placeholderLabel(key)}
                <button
                  type="button"
                  className="btn btn-ghost btn-inline"
                  onClick={() => fillWithAi([key])}
                  disabled={busy}
                >
                  {busyKey === key ? 'Filling…' : 'AI'}
                </button>
              </span>
              <textarea
                rows={2}
                value={values[key] || ''}
                onChange={(e) => setValue(key, e.target.value)}
                disabled={busy}
              />
            </label>
          ))}
        </div>

        <div className="modal-actions">
          <button type="button" className="btn btn-ghost" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button type="button" className="btn btn-primary" onClick={handleApply} disabled={busy}>
            Apply
          </button>
        </div>
      </div>
    </div>
  );
}
