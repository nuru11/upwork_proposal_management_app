import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { deleteTemplate, listTemplates } from '../../api/templates';
import ConfirmDialog from '../../components/ConfirmDialog';
import EmptyState from '../../components/EmptyState';
import {
  PROPOSAL_PROJECT_TYPES,
  LANGUAGES,
  labelFor,
} from '../../constants/enums';

export default function TemplatesListPage() {
  const [projectType, setProjectType] = useState('');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteId, setDeleteId] = useState(null);
  const [busy, setBusy] = useState(false);

  async function load(type = projectType) {
    setLoading(true);
    setError('');
    try {
      const data = await listTemplates(type ? { projectType: type } : {});
      setItems(data);
    } catch (err) {
      setError(err.message || 'Failed to load templates');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projectType]);

  async function handleDelete() {
    if (!deleteId) return;
    setBusy(true);
    try {
      await deleteTemplate(deleteId);
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
        <h1>Templates</h1>
        <Link to="/templates/new" className="btn btn-primary">
          New template
        </Link>
      </div>

      <div className="filters">
        <select
          value={projectType}
          onChange={(e) => setProjectType(e.target.value)}
        >
          <option value="">All project types</option>
          {PROPOSAL_PROJECT_TYPES.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </select>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}
      {loading ? <div className="page-loading">Loading…</div> : null}

      {!loading && items.length === 0 ? (
        <EmptyState
          title="No templates"
          message="Save reusable proposal bodies as templates."
          action={
            <Link to="/templates/new" className="btn btn-primary">
              New template
            </Link>
          }
        />
      ) : null}

      {!loading && items.length > 0 ? (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Language</th>
                <th>Type</th>
                <th>Favorite</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <Link to={`/templates/${item.id}/edit`} className="table-link">
                      {item.name}
                    </Link>
                  </td>
                  <td>{labelFor(LANGUAGES, item.language)}</td>
                  <td>{labelFor(PROPOSAL_PROJECT_TYPES, item.projectType)}</td>
                  <td>{item.isFavorite ? '★' : '—'}</td>
                  <td className="table-actions">
                    <Link
                      to={`/templates/${item.id}/edit`}
                      className="btn btn-ghost btn-sm"
                    >
                      Edit
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
        title="Delete template?"
        message="This will soft-delete the template."
        onCancel={() => setDeleteId(null)}
        onConfirm={handleDelete}
        busy={busy}
      />
    </div>
  );
}
