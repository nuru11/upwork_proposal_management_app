import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import {
  createProject,
  getProject,
  updateProject,
} from '../../api/projects';
import { PORTFOLIO_TYPES } from '../../constants/enums';

const blank = {
  name: '',
  description: '',
  playStoreUrl: '',
  appStoreUrl: '',
  webUrl: '',
  types: ['other'],
};

export default function ProjectFormPage() {
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
        const item = await getProject(id);
        if (!cancelled) {
          setForm({
            name: item.name || '',
            description: item.description || '',
            playStoreUrl: item.playStoreUrl || '',
            appStoreUrl: item.appStoreUrl || '',
            webUrl: item.webUrl || '',
            types: item.types?.length ? item.types : ['other'],
          });
        }
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load project');
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

  function toggleType(value) {
    setForm((f) => {
      const has = f.types.includes(value);
      const next = has
        ? f.types.filter((t) => t !== value)
        : [...f.types, value];
      return { ...f, types: next.length ? next : ['other'] };
    });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const playStoreUrl = form.playStoreUrl.trim();
    const appStoreUrl = form.appStoreUrl.trim();
    const webUrl = form.webUrl.trim();

    if (!playStoreUrl && !appStoreUrl && !webUrl) {
      setError('At least one URL is required (Play Store, App Store, or Web).');
      return;
    }

    setBusy(true);
    setError('');
    const now = new Date().toISOString();
    const payload = {
      name: form.name.trim(),
      description: form.description.trim() || null,
      playStoreUrl: playStoreUrl || null,
      appStoreUrl: appStoreUrl || null,
      webUrl: webUrl || null,
      types: form.types,
      updatedAt: now,
    };

    try {
      if (isEdit) {
        await updateProject(id, payload);
      } else {
        await createProject({
          ...payload,
          id: uuidv4(),
          createdAt: now,
        });
      }
      navigate('/projects');
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
        <h1>{isEdit ? 'Edit project' : 'New project'}</h1>
        <Link to="/projects" className="btn btn-ghost">
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

        <label className="field">
          <span>Description</span>
          <textarea
            value={form.description}
            onChange={(e) => setField('description', e.target.value)}
            rows={4}
            placeholder="Optional notes about this project"
          />
        </label>

        <label className="field">
          <span>Play Store URL</span>
          <input
            type="url"
            value={form.playStoreUrl}
            onChange={(e) => setField('playStoreUrl', e.target.value)}
            placeholder="https://"
          />
        </label>

        <label className="field">
          <span>App Store URL</span>
          <input
            type="url"
            value={form.appStoreUrl}
            onChange={(e) => setField('appStoreUrl', e.target.value)}
            placeholder="https://"
          />
        </label>

        <label className="field">
          <span>Web URL</span>
          <input
            type="url"
            value={form.webUrl}
            onChange={(e) => setField('webUrl', e.target.value)}
            placeholder="https://"
          />
        </label>

        <fieldset className="field">
          <legend>Types</legend>
          <div className="chip-grid">
            {PORTFOLIO_TYPES.map((t) => (
              <label key={t.value} className="chip-check">
                <input
                  type="checkbox"
                  checked={form.types.includes(t.value)}
                  onChange={() => toggleType(t.value)}
                />
                <span>{t.label}</span>
              </label>
            ))}
          </div>
        </fieldset>

        <div className="form-actions">
          <button type="submit" className="btn btn-primary" disabled={busy}>
            {busy ? 'Saving…' : isEdit ? 'Save changes' : 'Create project'}
          </button>
        </div>
      </form>
    </div>
  );
}
