import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { listProposals } from '../api/proposals';
import { listTemplates } from '../api/templates';
import EmptyState from '../components/EmptyState';
import StatusBadge from '../components/StatusBadge';
import { STATUSES, LANGUAGES } from '../constants/enums';
import { computeStats, formatPercent } from '../utils/stats';

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const [proposals, templates] = await Promise.all([
          listProposals(),
          listTemplates(),
        ]);
        if (!cancelled) {
          setStats(computeStats(proposals, templates));
        }
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load stats');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return <div className="page-loading">Loading dashboard…</div>;
  }

  if (error) {
    return <div className="alert alert-error">{error}</div>;
  }

  if (!stats || stats.overall.total === 0) {
    return (
      <div className="page">
        <div className="page-header">
          <h1>Dashboard</h1>
        </div>
        <EmptyState
          title="No stats yet"
          message="Once you track proposals and update their status, hire rates will show up here."
          action={
            <Link to="/proposals/new" className="btn btn-primary">
              New proposal
            </Link>
          }
        />
      </div>
    );
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>Dashboard</h1>
        <Link to="/proposals" className="btn btn-ghost">
          View proposals
        </Link>
      </div>

      <div className="stat-grid">
        <div className="stat-card stat-hero">
          <div className="stat-label">Overall hire rate</div>
          <div className="stat-value teal">
            {formatPercent(stats.overall.hired, stats.overall.total)}
          </div>
          <div className="stat-meta">
            {stats.overall.hired} hired of {stats.overall.total} proposals
          </div>
        </div>
      </div>

      <h2 className="section-title">By status</h2>
      <div className="stat-grid cols-5">
        {STATUSES.map((s) => (
          <div key={s.value} className="stat-card">
            <div className="stat-label">
              <StatusBadge status={s.value} />
            </div>
            <div className="stat-value sm">{stats.byStatus[s.value] || 0}</div>
          </div>
        ))}
      </div>

      <h2 className="section-title">Hire rate by language</h2>
      <div className="card-list">
        {LANGUAGES.map((lang) => {
          const data = stats.byLanguage[lang.value];
          return (
            <div key={lang.value} className="card-row">
              <div>
                <div className="card-row-title">{lang.label}</div>
                <div className="muted">
                  {data.hired} hired of {data.total}
                </div>
              </div>
              <div className="card-row-value">
                {formatPercent(data.hired, data.total)}
              </div>
            </div>
          );
        })}
      </div>

      {stats.byTemplate.length > 0 ? (
        <>
          <h2 className="section-title">Hire rate by template</h2>
          <div className="card-list">
            {stats.byTemplate.map((row) => (
              <div key={row.templateId || 'none'} className="card-row">
                <div>
                  <div className="card-row-title">{row.name}</div>
                  <div className="muted">
                    {row.hired} hired of {row.total}
                  </div>
                </div>
                <div className="card-row-value">
                  {formatPercent(row.hired, row.total)}
                </div>
              </div>
            ))}
          </div>
        </>
      ) : null}
    </div>
  );
}
