import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  deleteProposal,
  getProposal,
  updateProposal,
} from '../../api/proposals';
import { getTemplate } from '../../api/templates';
import ConfirmDialog from '../../components/ConfirmDialog';
import StatusBadge from '../../components/StatusBadge';
import {
  STATUSES,
  LANGUAGES,
  PROPOSAL_PROJECT_TYPES,
  labelFor,
  statusList,
} from '../../constants/enums';

export default function ProposalDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [item, setItem] = useState(null);
  const [templateName, setTemplateName] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [reviewBusy, setReviewBusy] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [notes, setNotes] = useState('');
  const [updatedVersion, setUpdatedVersion] = useState('');
  const [reviewSaved, setReviewSaved] = useState(false);
  const [copiedVersion, setCopiedVersion] = useState(false);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const data = await getProposal(id);
      setItem(data);
      setNotes(data.notes || '');
      setUpdatedVersion(data.updatedVersion || '');
      setReviewSaved(false);
      if (data.templateId) {
        try {
          const tpl = await getTemplate(data.templateId);
          setTemplateName(tpl.name);
        } catch {
          setTemplateName('Unknown template');
        }
      } else {
        setTemplateName(null);
      }
    } catch (err) {
      setError(err.message || 'Failed to load proposal');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  async function toggleStatus(value) {
    if (!item || busy) return;
    const current = statusList(item.status);
    const has = current.includes(value);
    const next = has ? current.filter((s) => s !== value) : [...current, value];
    if (!next.length) return;
    setBusy(true);
    setError('');
    try {
      const updated = await updateProposal(id, {
        ...item,
        status: statusList(next),
        updatedAt: new Date().toISOString(),
      });
      setItem(updated);
    } catch (err) {
      setError(err.message || 'Failed to update status');
    } finally {
      setBusy(false);
    }
  }

  async function handleDelete() {
    setBusy(true);
    try {
      await deleteProposal(id);
      navigate('/proposals');
    } catch (err) {
      setError(err.message || 'Delete failed');
      setBusy(false);
      setConfirmOpen(false);
    }
  }

  async function copyBody() {
    if (!item?.body) return;
    try {
      await navigator.clipboard.writeText(item.body);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      setError('Could not copy to clipboard');
    }
  }

  async function copyUpdatedVersion() {
    if (!updatedVersion.trim()) return;
    try {
      await navigator.clipboard.writeText(updatedVersion);
      setCopiedVersion(true);
      setTimeout(() => setCopiedVersion(false), 1500);
    } catch {
      setError('Could not copy to clipboard');
    }
  }

  async function saveReview() {
    if (!item || reviewBusy) return;
    setReviewBusy(true);
    setError('');
    setReviewSaved(false);
    try {
      const updated = await updateProposal(id, {
        ...item,
        notes: notes.trim() || null,
        updatedVersion: updatedVersion.trim() || null,
        updatedAt: new Date().toISOString(),
      });
      setItem(updated);
      setNotes(updated.notes || '');
      setUpdatedVersion(updated.updatedVersion || '');
      setReviewSaved(true);
    } catch (err) {
      setError(err.message || 'Failed to save notes');
    } finally {
      setReviewBusy(false);
    }
  }

  if (loading) {
    return <div className="page-loading">Loading…</div>;
  }

  if (error && !item) {
    return (
      <div className="page">
        <div className="alert alert-error">{error}</div>
        <Link to="/proposals" className="btn btn-ghost">
          Back to list
        </Link>
      </div>
    );
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <Link to="/proposals" className="back-link">
            ← Proposals
          </Link>
          <h1>{item.title}</h1>
        </div>
        <div className="header-actions">
          <Link to={`/proposals/${id}/edit`} className="btn btn-secondary">
            Edit
          </Link>
          <button
            type="button"
            className="btn btn-danger"
            onClick={() => setConfirmOpen(true)}
          >
            Delete
          </button>
        </div>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <div className="detail-grid">
        <div className="detail-main">
          <div className="detail-card">
            <div className="detail-card-header">
              <h2>Proposal body</h2>
              <button type="button" className="btn btn-ghost" onClick={copyBody}>
                {copied ? 'Copied' : 'Copy body'}
              </button>
            </div>
            <pre className="body-pre">{item.body}</pre>
          </div>
          <div className="detail-card review-fields">
            <label className="field">
              <span>Notes</span>
              <span className="field-hint">
                How to improve this proposal, or its weaknesses.
              </span>
              <textarea
                rows={4}
                value={notes}
                onChange={(e) => {
                  setNotes(e.target.value);
                  setReviewSaved(false);
                }}
              />
            </label>
            <div>
              <div className="detail-card-header">
                <label className="field" htmlFor="updated-version">
                  <span>Updated version</span>
                  <span className="field-hint">The improved proposal.</span>
                </label>
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={copyUpdatedVersion}
                  disabled={!updatedVersion.trim()}
                >
                  {copiedVersion ? 'Copied' : 'Copy'}
                </button>
              </div>
              <textarea
                id="updated-version"
                className="review-textarea"
                rows={10}
                value={updatedVersion}
                onChange={(e) => {
                  setUpdatedVersion(e.target.value);
                  setReviewSaved(false);
                }}
              />
            </div>
            <div className="header-actions">
              {reviewSaved ? <span className="field-hint">Saved</span> : null}
              <button
                type="button"
                className="btn btn-primary"
                onClick={saveReview}
                disabled={reviewBusy}
              >
                {reviewBusy ? 'Saving…' : 'Save'}
              </button>
            </div>
          </div>
        </div>

        <aside className="detail-side">
          <div className="detail-card">
            <h2>Status</h2>
            <div className="status-row">
              {statusList(item.status).map((status) => (
                <StatusBadge key={status} status={status} />
              ))}
            </div>
            <fieldset className="field">
              <legend>Update status</legend>
              <div className="chip-grid">
                {STATUSES.map((s) => (
                  <label key={s.value} className="chip-check">
                    <input
                      type="checkbox"
                      checked={statusList(item.status).includes(s.value)}
                      disabled={busy}
                      onChange={() => toggleStatus(s.value)}
                    />
                    <span>{s.label}</span>
                  </label>
                ))}
              </div>
            </fieldset>
          </div>

          <div className="detail-card">
            <h2>Details</h2>
            <dl className="meta-list">
              <div>
                <dt>Client</dt>
                <dd>{item.clientName || '—'}</dd>
              </div>
              <div>
                <dt>Language</dt>
                <dd>{labelFor(LANGUAGES, item.language)}</dd>
              </div>
              <div>
                <dt>Project type</dt>
                <dd>{labelFor(PROPOSAL_PROJECT_TYPES, item.projectType)}</dd>
              </div>
              <div>
                <dt>Template</dt>
                <dd>{templateName || '—'}</dd>
              </div>
              <div>
                <dt>Job URL</dt>
                <dd>
                  {item.jobUrl ? (
                    <a href={item.jobUrl} target="_blank" rel="noreferrer">
                      Open job
                    </a>
                  ) : (
                    '—'
                  )}
                </dd>
              </div>
              <div>
                <dt>Updated</dt>
                <dd>
                  {item.updatedAt
                    ? new Date(item.updatedAt).toLocaleString()
                    : '—'}
                </dd>
              </div>
              <div>
                <dt>Submitted</dt>
                <dd>
                  {item.submittedAt
                    ? new Date(item.submittedAt).toLocaleString()
                    : '—'}
                </dd>
              </div>
            </dl>
          </div>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        title="Delete proposal?"
        message="This will soft-delete the proposal. It will no longer appear in lists."
        onCancel={() => setConfirmOpen(false)}
        onConfirm={handleDelete}
        busy={busy}
      />
    </div>
  );
}
