import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { listProposals } from '../../api/proposals';
import EmptyState from '../../components/EmptyState';
import StatusBadge from '../../components/StatusBadge';
import {
  STATUSES,
  LANGUAGES,
  PROPOSAL_PROJECT_TYPES,
  labelFor,
} from '../../constants/enums';

const emptyFilters = {
  search: '',
  status: '',
  language: '',
  projectType: '',
};

export default function ProposalsListPage() {
  const [filters, setFilters] = useState(emptyFilters);
  const [applied, setApplied] = useState(emptyFilters);
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const data = await listProposals(applied);
        if (!cancelled) setItems(data);
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load proposals');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [applied]);

  function applyFilters(e) {
    e.preventDefault();
    setApplied({ ...filters });
  }

  function resetFilters() {
    setFilters(emptyFilters);
    setApplied(emptyFilters);
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>Proposals</h1>
        <Link to="/proposals/new" className="btn btn-primary">
          New proposal
        </Link>
      </div>

      <form className="filters" onSubmit={applyFilters}>
        <input
          placeholder="Search title, client, body…"
          value={filters.search}
          onChange={(e) => setFilters((f) => ({ ...f, search: e.target.value }))}
        />
        <select
          value={filters.status}
          onChange={(e) => setFilters((f) => ({ ...f, status: e.target.value }))}
        >
          <option value="">All statuses</option>
          {STATUSES.map((s) => (
            <option key={s.value} value={s.value}>
              {s.label}
            </option>
          ))}
        </select>
        <select
          value={filters.language}
          onChange={(e) => setFilters((f) => ({ ...f, language: e.target.value }))}
        >
          <option value="">All languages</option>
          {LANGUAGES.map((l) => (
            <option key={l.value} value={l.value}>
              {l.label}
            </option>
          ))}
        </select>
        <select
          value={filters.projectType}
          onChange={(e) => setFilters((f) => ({ ...f, projectType: e.target.value }))}
        >
          <option value="">All project types</option>
          {PROPOSAL_PROJECT_TYPES.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </select>
        <button type="submit" className="btn btn-secondary">
          Filter
        </button>
        <button type="button" className="btn btn-ghost" onClick={resetFilters}>
          Reset
        </button>
      </form>

      {error ? <div className="alert alert-error">{error}</div> : null}
      {loading ? <div className="page-loading">Loading…</div> : null}

      {!loading && !error && items.length === 0 ? (
        <EmptyState
          title="No proposals"
          message="Create your first proposal or adjust filters."
          action={
            <Link to="/proposals/new" className="btn btn-primary">
              New proposal
            </Link>
          }
        />
      ) : null}

      {!loading && items.length > 0 ? (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Title</th>
                <th>Client</th>
                <th>Status</th>
                <th>Language</th>
                <th>Type</th>
                <th>Updated</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <Link to={`/proposals/${item.id}`} className="table-link">
                      {item.title}
                    </Link>
                  </td>
                  <td>{item.clientName || '—'}</td>
                  <td>
                    <StatusBadge status={item.status} />
                  </td>
                  <td>{labelFor(LANGUAGES, item.language)}</td>
                  <td>{labelFor(PROPOSAL_PROJECT_TYPES, item.projectType)}</td>
                  <td className="muted">
                    {item.updatedAt
                      ? new Date(item.updatedAt).toLocaleString()
                      : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </div>
  );
}
