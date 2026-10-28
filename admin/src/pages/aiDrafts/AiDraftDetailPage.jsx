import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { deleteAiDraft, getAiDraft, updateAiDraft } from '../../api/aiDrafts';
import ConfirmDialog from '../../components/ConfirmDialog';
import { AI_DOMAINS, labelFor } from '../../constants/enums';

export default function AiDraftDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [draft, setDraft] = useState(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [confirmDelete, setConfirmDelete] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const item = await getAiDraft(id);
        if (!cancelled) {
          setDraft(item);
          setTitle(item.title || '');
          setBody(item.body || '');
        }
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load draft');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  async function handleSave() {
    if (!title.trim() || !body.trim()) {
      setError('Title and body are required');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const updated = await updateAiDraft(id, {
        ...draft,
        title: title.trim(),
        body: body.trim(),
        updatedAt: new Date().toISOString(),
      });
      setDraft(updated);
    } catch (err) {
      setError(err.message || 'Save failed');
    } finally {
      setBusy(false);
    }
  }

  async function handleDelete() {
    setBusy(true);
    try {
      await deleteAiDraft(id);
      navigate('/ai-drafts');
    } catch (err) {
      setError(err.message || 'Delete failed');
      setBusy(false);
      setConfirmDelete(false);
    }
  }

  function createProposal() {
    navigate('/proposals/new', {
      state: {
        formSnapshot: {
          title: title.trim() || draft?.title || '',
          clientName: draft?.clientName || '',
          jobUrl: '',
          body: body.trim() || draft?.body || '',
          language: draft?.language || 'english',
          status: ['submitted'],
          projectType: 'mobileApp',
          templateId: '',
          notes: '',
        },
        aiBody: body.trim() || draft?.body || '',
      },
    });
  }

  if (loading) {
    return <div className="page-loading">Loading…</div>;
  }

  if (!draft) {
    return (
      <div className="page">
        <div className="page-header">
          <h1>AI draft</h1>
          <Link to="/ai-drafts" className="btn btn-ghost">
            Back
          </Link>
        </div>
        <div className="alert alert-error">{error || 'Draft not found'}</div>
      </div>
    );
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>AI draft</h1>
        <Link to="/ai-drafts" className="btn btn-ghost">
          Back
        </Link>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <p className="muted">
        {labelFor(AI_DOMAINS, draft.domain)}
        {draft.updatedAt
          ? ` · ${new Date(draft.updatedAt).toLocaleString()}`
          : ''}
      </p>

      <div className="form panel">
        <label className="field">
          <span>Title</span>
          <input value={title} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="field">
          <span>Proposal body</span>
          <textarea
            rows={16}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            dir={draft.language === 'arabic' ? 'rtl' : 'ltr'}
          />
        </label>
        <div className="form-actions ai-actions">
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => setConfirmDelete(true)}
            disabled={busy}
          >
            Delete
          </button>
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={handleSave}
              disabled={busy}
            >
              {busy ? 'Saving…' : 'Save'}
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={createProposal}
              disabled={busy}
            >
              Create proposal
            </button>
          </div>
        </div>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title="Delete AI draft?"
        message="This will remove the saved AI draft."
        onCancel={() => setConfirmDelete(false)}
        onConfirm={handleDelete}
        busy={busy}
      />
    </div>
  );
}
