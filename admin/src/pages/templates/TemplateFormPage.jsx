import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import {
  createTemplate,
  getTemplate,
  updateTemplate,
} from '../../api/templates';
import {
  LANGUAGES,
  PROPOSAL_PROJECT_TYPES,
} from '../../constants/enums';

const blank = {
  name: '',
  body: '',
  inspiredFrom: '',
  language: 'english',
  projectType: 'mobileApp',
  isFavorite: false,
};

export default function TemplateFormPage() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();
  const [form, setForm] = useState(blank);
  const [loading, setLoading] = useState(isEdit);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isEdit) return undefined;
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const item = await getTemplate(id);
        if (!cancelled) {
          setForm({
            name: item.name || '',
            body: item.body || '',
            inspiredFrom: item.inspiredFrom || '',
            language: item.language || 'english',
            projectType: item.projectType || 'mobileApp',
            isFavorite: Boolean(item.isFavorite),
          });
        }
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load template');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id, isEdit]);

  function setField(key, value) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError('');
    const now = new Date().toISOString();
    const payload = {
      name: form.name.trim(),
      body: form.body,
      inspiredFrom: form.inspiredFrom.trim() || null,
      language: form.language,
      projectType: form.projectType,
      isFavorite: form.isFavorite,
      updatedAt: now,
    };

    try {
      if (isEdit) {
        await updateTemplate(id, payload);
      } else {
        await createTemplate({
          ...payload,
          id: uuidv4(),
          createdAt: now,
        });
      }
      navigate('/templates');
    } catch (err) {
      setError(err.message || 'Save failed');
    } finally {
      setBusy(false);
    }
  }

  if (loading) {
    return <div className="page-loading">Loading…</div>;
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>{isEdit ? 'Edit template' : 'New template'}</h1>
        <Link to="/templates" className="btn btn-ghost">
          Cancel
        </Link>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <form className="form" onSubmit={handleSubmit}>
        <label className="field">
          <span>Name *</span>
          <input
            value={form.name}
            onChange={(e) => setField('name', e.target.value)}
            required
          />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Language</span>
            <select
              value={form.language}
              onChange={(e) => setField('language', e.target.value)}
            >
              {LANGUAGES.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span>Project type *</span>
            <select
              value={form.projectType}
              onChange={(e) => setField('projectType', e.target.value)}
              required
            >
              {PROPOSAL_PROJECT_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </label>
        </div>

        <label className="field checkbox-field">
          <input
            type="checkbox"
            checked={form.isFavorite}
            onChange={(e) => setField('isFavorite', e.target.checked)}
          />
          <span>Favorite</span>
        </label>

        <label className="field">
          <span>Body *</span>
          <textarea
            rows={14}
            value={form.body}
            onChange={(e) => setField('body', e.target.value)}
            required
          />
        </label>

        <label className="field">
          <span>Inspired from</span>
          <textarea
            rows={8}
            value={form.inspiredFrom}
            onChange={(e) => setField('inspiredFrom', e.target.value)}
            placeholder="Original example this template was based on"
          />
        </label>

        <div className="form-actions">
          <button type="submit" className="btn btn-primary" disabled={busy}>
            {busy ? 'Saving…' : isEdit ? 'Save changes' : 'Create template'}
          </button>
        </div>
      </form>
    </div>
  );
}
