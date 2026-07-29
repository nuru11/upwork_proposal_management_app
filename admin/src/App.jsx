import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth/AuthContext';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ProposalsListPage from './pages/proposals/ProposalsListPage';
import ProposalFormPage from './pages/proposals/ProposalFormPage';
import ProposalDetailPage from './pages/proposals/ProposalDetailPage';
import TemplatesListPage from './pages/templates/TemplatesListPage';
import TemplateFormPage from './pages/templates/TemplateFormPage';
import ProjectsListPage from './pages/projects/ProjectsListPage';
import ProjectFormPage from './pages/projects/ProjectFormPage';

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="proposals" element={<ProposalsListPage />} />
        <Route path="proposals/new" element={<ProposalFormPage />} />
        <Route path="proposals/:id" element={<ProposalDetailPage />} />
        <Route path="proposals/:id/edit" element={<ProposalFormPage />} />
        <Route path="templates" element={<TemplatesListPage />} />
        <Route path="templates/new" element={<TemplateFormPage />} />
        <Route path="templates/:id/edit" element={<TemplateFormPage />} />
        <Route path="projects" element={<ProjectsListPage />} />
        <Route path="projects/new" element={<ProjectFormPage />} />
        <Route path="projects/:id/edit" element={<ProjectFormPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
