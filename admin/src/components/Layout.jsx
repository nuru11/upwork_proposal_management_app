import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const navItems = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/proposals', label: 'Proposals' },
  { to: '/ai-drafts', label: 'AI drafts' },
  { to: '/templates', label: 'Templates' },
  { to: '/projects', label: 'Projects' },
];

export default function Layout() {
  const { user, logout } = useAuth();

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <img className="brand-mark" src="/logo.png" alt="Proposal Admin" />
          <div>
            <div className="brand-title">Proposal Admin</div>
            <div className="brand-sub">Personal</div>
          </div>
        </div>
        <nav className="nav">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="main">
        <header className="topbar">
          <div className="topbar-spacer" />
          <div className="topbar-user">
            <span className="username">{user?.username ?? 'User'}</span>
            <button type="button" className="btn btn-ghost" onClick={logout}>
              Logout
            </button>
          </div>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
