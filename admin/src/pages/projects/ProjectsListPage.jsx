import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { deleteProject, listProjects } from '../../api/projects';
import ConfirmDialog from '../../components/ConfirmDialog';
import EmptyState from '../../components/EmptyState';
import { PORTFOLIO_TYPES, labelFor } from '../../constants/enums';

export default function ProjectsListPage() {
  const [type, setType] = useState('');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteId, setDeleteId] = useState(null);
  const [busy, setBusy] = useState(false);

  async function load(filterType = type) {
    setLoading(true);
    setError('');
    try {
      const data = await listProjects(filterType ? { type: filterType } : {});
      setItems(data);
    } catch (err) {
      setError(err.message || 'Failed to load projects');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type]);

  async function handleDelete() {
    if (!deleteId) return;
    setBusy(true);
    try {
      await deleteProject(deleteId);
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
        <h1>Projects</h1>
        <Link to="/projects/new" className="btn btn-primary">
          New project
        </Link>
      </div>

      <div className="filters">
        <select value={type} onChange={(e) => setType(e.target.value)}>
          <option value="">All types</option>
          {PORTFOLIO_TYPES.map((t) => (
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
          title="No projects"
          message="Add portfolio apps to share store and web links."
          action={
            <Link to="/projects/new" className="btn btn-primary">
              New project
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
                <th>Types</th>
                <th>Links</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <Link to={`/projects/${item.id}/edit`} className="table-link">
                      {item.name}
                    </Link>
                  </td>
                  <td>
                    {(item.types || [])
                      .map((t) => labelFor(PORTFOLIO_TYPES, t))
                      .join(', ') || '—'}
                  </td>
                  <td className="link-chips">
                    {item.playStoreUrl ? (
                      <a href={item.playStoreUrl} target="_blank" rel="noreferrer">
                        Play
                      </a>
                    ) : null}
                    {item.appStoreUrl ? (
                      <a href={item.appStoreUrl} target="_blank" rel="noreferrer">
                        App Store
                      </a>
                    ) : null}
                    {item.webUrl ? (
                      <a href={item.webUrl} target="_blank" rel="noreferrer">
                        Web
                      </a>
                    ) : null}
                    {!item.playStoreUrl && !item.appStoreUrl && !item.webUrl
                      ? '—'
                      : null}
                  </td>
                  <td className="table-actions">
                    <Link
                      to={`/projects/${item.id}/edit`}
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
        title="Delete project?"
        message="This will soft-delete the project."
        onCancel={() => setDeleteId(null)}
        onConfirm={handleDelete}
        busy={busy}
      />
    </div>
  );
}
