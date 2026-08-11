import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { deleteAiDraft, listAiDrafts } from '../../api/aiDrafts';
import ConfirmDialog from '../../components/ConfirmDialog';
import EmptyState from '../../components/EmptyState';
import { AI_DOMAINS, labelFor } from '../../constants/enums';

function formatDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString();
}

export default function AiDraftsListPage() {
  const navigate = useNavigate();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteId, setDeleteId] = useState(null);
  const [busy, setBusy] = useState(false);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const data = await listAiDrafts();
      setItems(data);
    } catch (err) {
      setError(err.message || 'Failed to load AI drafts');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleDelete() {
    if (!deleteId) return;
    setBusy(true);
    try {
      await deleteAiDraft(deleteId);
      setDeleteId(null);
      await load();
    } catch (err) {
      setError(err.message || 'Delete failed');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>AI drafts</h1>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() =>
            navigate('/proposals/ai-wizard', {
              state: { returnTo: '/ai-drafts' },
            })
          }
        >
          New AI draft
        </button>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}
      {loading ? <div className="page-loading">Loading…</div> : null}

      {!loading && items.length === 0 ? (
        <EmptyState
          title="No AI drafts"
          message="Generate a proposal with AI and save it here."
          action={
            <button
              type="button"
              className="btn btn-primary"
              onClick={() =>
                navigate('/proposals/ai-wizard', {
                  state: { returnTo: '/ai-drafts' },
                })
              }
            >
              Generate with AI
            </button>
          }
        />
      ) : null}

      {!loading && items.length > 0 ? (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Title</th>
                <th>Domain</th>
                <th>Updated</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <Link to={`/ai-drafts/${item.id}`} className="table-link">
                      {item.title}
                    </Link>
                  </td>
                  <td>{labelFor(AI_DOMAINS, item.domain)}</td>
                  <td>{formatDate(item.updatedAt)}</td>
                  <td className="table-actions">
                    <Link
                      to={`/ai-drafts/${item.id}`}
                      className="btn btn-ghost btn-sm"
                    >
                      Open
                    </Link>
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm danger-text"
                      onClick={() => setDeleteId(item.id)}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      <ConfirmDialog
        open={Boolean(deleteId)}
        title="Delete AI draft?"
        message="This will remove the saved AI draft."
        onCancel={() => setDeleteId(null)}
        onConfirm={handleDelete}
        busy={busy}
      />
    </div>
  );
}
