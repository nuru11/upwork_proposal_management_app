import { useEffect, useRef, useState } from 'react';
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import {
  createProposal,
  getProposal,
  updateProposal,
} from '../../api/proposals';
import { listTemplates } from '../../api/templates';
import {
  STATUSES,
  LANGUAGES,
  PROPOSAL_PROJECT_TYPES,
  statusList,
} from '../../constants/enums';
import TemplateFillModal from '../../components/TemplateFillModal';
import { extractPlaceholders } from '../../utils/templatePlaceholders';

const blank = {
  title: '',
  clientName: '',
  jobUrl: '',
  jobDescription: '',
  body: '',
  language: 'english',
  status: ['submitted'],
  projectType: 'mobileApp',
  templateId: '',
  notes: '',
};

export default function ProposalFormPage() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();
  const location = useLocation();
  const skipNextFetch = useRef(
    Boolean(location.state?.formSnapshot || location.state?.aiBody),
  );
  const [form, setForm] = useState(() => {
    const snap = location.state?.formSnapshot;
    const aiBody = location.state?.aiBody;
    const jobDescription = location.state?.jobDescription;
    if (!snap && !aiBody && !jobDescription) return blank;
    const next = {
      ...(snap || blank),
      ...(aiBody ? { body: aiBody } : {}),
      ...(jobDescription ? { jobDescription } : {}),
    };
    return { ...next, status: statusList(next.status) };
  });
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(
    isEdit && !location.state?.formSnapshot && !location.state?.aiBody,
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [fillOpen, setFillOpen] = useState(false);

  useEffect(() => {
    if (!location.state?.formSnapshot && !location.state?.aiBody) return;
    navigate(location.pathname, { replace: true, state: null });
  }, [location.state, location.pathname, navigate]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const tpls = await listTemplates();
        if (!cancelled) setTemplates(tpls);
      } catch {
        /* optional */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!isEdit) return undefined;
    if (skipNextFetch.current) {
      skipNextFetch.current = false;
      setLoading(false);
      return undefined;
    }
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const item = await getProposal(id);
        if (!cancelled) {
          setForm({
            title: item.title || '',
            clientName: item.clientName || '',
            jobUrl: item.jobUrl || '',
            jobDescription: item.jobDescription || '',
            body: item.body || '',
            language: item.language || 'english',
            status: statusList(item.status),
            projectType: item.projectType || 'mobileApp',
            templateId: item.templateId || '',
            notes: item.notes || '',
          });
        }
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load proposal');
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

  function toggleStatus(value) {
    setForm((f) => {
      const current = statusList(f.status);
      const has = current.includes(value);
      const next = has
        ? current.filter((s) => s !== value)
        : [...current, value];
      return { ...f, status: next.length ? statusList(next) : current };
    });
  }

  function onTemplateChange(templateId) {
    setField('templateId', templateId);
    if (!templateId) return;
    const tpl = templates.find((t) => t.id === templateId);
    if (!tpl) return;
    const keys = extractPlaceholders(tpl.body || '');
    setForm((f) => ({
      ...f,
      templateId,
      language: tpl.language || f.language,
      projectType: tpl.projectType || f.projectType,
      body: f.body.trim() ? f.body : keys.length === 0 ? tpl.body : f.body,
    }));
  }

  function openFillFields() {
    const tpl = templates.find((t) => t.id === form.templateId);
    if (!tpl) {
      setError('Select a template first.');
      return;
    }
    const keys = extractPlaceholders(tpl.body || '');
    if (keys.length === 0) {
      setForm((f) => ({
        ...f,
        body: f.body.trim() ? f.body : tpl.body,
        language: tpl.language || f.language,
        projectType: tpl.projectType || f.projectType,
      }));
      return;
    }
    setError('');
    setFillOpen(true);
  }

  function openAiWizard(mode = 'ai') {
    const selectedTemplate = templates.find((t) => t.id === form.templateId);
    navigate('/proposals/ai-wizard', {
      state: {
        returnTo: isEdit ? `/proposals/${id}/edit` : '/proposals/new',
        formSnapshot: form,
        language: form.language,
        clientName: form.clientName,
        templateId: selectedTemplate?.id || '',
        templateBody: selectedTemplate?.body || '',
        mode,
      },
    });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError('');
    const now = new Date().toISOString();
    const payload = {
      title: form.title.trim(),
      clientName: form.clientName.trim() || null,
      jobUrl: form.jobUrl.trim() || null,
      jobDescription: (form.jobDescription || '').trim() || null,
      body: form.body,
      language: form.language,
      status: form.status,
      projectType: form.projectType,
      templateId: form.templateId || null,
      notes: form.notes.trim() || null,
      updatedAt: now,
    };

    try {
      if (isEdit) {
        await updateProposal(id, payload);
        navigate(`/proposals/${id}`);
      } else {
        const created = await createProposal({
          ...payload,
          id: uuidv4(),
          createdAt: now,
          submittedAt: now,
        });
        navigate(`/proposals/${created.id}`);
      }
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
        <h1>{isEdit ? 'Edit proposal' : 'New proposal'}</h1>
        <Link
          to={isEdit ? `/proposals/${id}` : '/proposals'}
          className="btn btn-ghost"
        >
          Cancel
        </Link>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <form className="form" onSubmit={handleSubmit}>
        <div className="form-actions" style={{ marginBottom: 8, gap: 8, justifyContent: 'flex-start', flexWrap: 'wrap' }}>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => openAiWizard('ai')}
          >
            Generate with AI
          </button>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => openAiWizard('fromTemplate')}
          >
            Generate with template
          </button>
        </div>

        <label className="field">
          <span>Title *</span>
          <input
            value={form.title}
            onChange={(e) => setField('title', e.target.value)}
            required
          />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Client</span>
            <input
              value={form.clientName}
              onChange={(e) => setField('clientName', e.target.value)}
            />
          </label>
          <label className="field">
            <span>Job URL</span>
            <input
              type="url"
              value={form.jobUrl}
              onChange={(e) => setField('jobUrl', e.target.value)}
              placeholder="https://"
            />
          </label>
        </div>

        <label className="field">
          <span>Job description</span>
          <textarea
            rows={6}
            value={form.jobDescription || ''}
            onChange={(e) => setField('jobDescription', e.target.value)}
            placeholder="Paste the Upwork job posting"
          />
        </label>

        <fieldset className="field">
          <legend>Status</legend>
          <div className="chip-grid">
            {STATUSES.map((s) => (
              <label key={s.value} className="chip-check">
                <input
                  type="checkbox"
                  checked={statusList(form.status).includes(s.value)}
                  onChange={() => toggleStatus(s.value)}
                />
                <span>{s.label}</span>
              </label>
            ))}
          </div>
        </fieldset>

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

        <label className="field">
          <span>Template</span>
          <div className="template-fill-row">
            <select
              value={form.templateId}
              onChange={(e) => onTemplateChange(e.target.value)}
            >
              <option value="">None</option>
              {templates.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.isFavorite ? '★ ' : ''}
                  {t.name}
                </option>
              ))}
            </select>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={openFillFields}
              disabled={!form.templateId}
            >
              Fill fields
            </button>
          </div>
        </label>

        <label className="field">
          <span>Body *</span>
          <textarea
            rows={12}
            value={form.body}
            onChange={(e) => setField('body', e.target.value)}
            required
          />
        </label>

        <label className="field">
          <span>Notes</span>
          <textarea
            rows={3}
            value={form.notes}
            onChange={(e) => setField('notes', e.target.value)}
          />
        </label>

        <div className="form-actions">
          <button type="submit" className="btn btn-primary" disabled={busy}>
            {busy ? 'Saving…' : isEdit ? 'Save changes' : 'Create proposal'}
          </button>
        </div>
      </form>

      <TemplateFillModal
        open={fillOpen}
        templateBody={templates.find((t) => t.id === form.templateId)?.body || ''}
        language={form.language}
        clientName={form.clientName}
        notes={form.notes}
        onCancel={() => setFillOpen(false)}
        onApply={(body) => {
          const tpl = templates.find((t) => t.id === form.templateId);
          setForm((f) => ({
            ...f,
            body,
            language: tpl?.language || f.language,
            projectType: tpl?.projectType || f.projectType,
          }));
          setFillOpen(false);
        }}
      />
    </div>
  );
}
