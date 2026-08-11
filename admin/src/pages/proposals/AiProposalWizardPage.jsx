import { useEffect, useMemo, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { draftProposal, extractIssues, suggestSolutions } from '../../api/ai';
import { createAiDraft, titleFromJob } from '../../api/aiDrafts';
import { listProjects } from '../../api/projects';
import { listTemplates } from '../../api/templates';
import {
  LANGUAGES,
  AI_DOMAINS,
  PROPOSAL_PROJECT_TYPES,
  labelFor,
} from '../../constants/enums';

const STEPS = ['Job', 'Issues', 'Solutions', 'Draft'];

function matchingProjectIds(projects, domain) {
  return (projects || [])
    .filter((p) => Array.isArray(p.types) && p.types.includes(domain))
    .map((p) => p.id);
}

function previewDescription(text) {
  const trimmed = (text || '').trim();
  if (!trimmed) return 'No description';
  return trimmed.length > 100 ? `${trimmed.slice(0, 100)}…` : trimmed;
}

export default function AiProposalWizardPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const incoming = location.state || {};

  const returnTo = incoming.returnTo || '/proposals/new';
  const formSnapshot = incoming.formSnapshot || null;
  const initialLanguage = incoming.language || formSnapshot?.language || 'english';
  const incomingTemplateId =
    incoming.templateId || formSnapshot?.templateId || '';
  const clientName = incoming.clientName || formSnapshot?.clientName || '';

  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const [jobDescription, setJobDescription] = useState('');
  const [notes, setNotes] = useState('');
  const [domain, setDomain] = useState('marketplace');
  const [language, setLanguage] = useState(initialLanguage);
  const [templates, setTemplates] = useState([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState(incomingTemplateId);

  const [issues, setIssues] = useState([]);
  const [solutions, setSolutions] = useState([]);
  const [draftBody, setDraftBody] = useState('');
  const [newIssueTitle, setNewIssueTitle] = useState('');
  const [newIssueWhy, setNewIssueWhy] = useState('');

  const [projects, setProjects] = useState([]);
  const [selectedProjectIds, setSelectedProjectIds] = useState(() => new Set());
  const [describeProjectIds, setDescribeProjectIds] = useState(() => new Set());
  const [projectNotes, setProjectNotes] = useState({});
  const [projectsLoading, setProjectsLoading] = useState(true);

  const selectedTemplate = useMemo(
    () => templates.find((t) => t.id === selectedTemplateId) || null,
    [templates, selectedTemplateId],
  );

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [projectList, templateList] = await Promise.all([
          listProjects(),
          listTemplates(),
        ]);
        if (cancelled) return;
        const items = projectList || [];
        setProjects(items);
        setSelectedProjectIds(new Set(matchingProjectIds(items, domain)));
        setTemplates(templateList || []);
      } catch (err) {
        if (!cancelled) setError(err.message || 'Failed to load projects');
      } finally {
        if (!cancelled) setProjectsLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
    // Pre-check against the initial domain only; later domain changes re-apply below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function changeDomain(nextDomain) {
    setDomain(nextDomain);
    setSelectedProjectIds(new Set(matchingProjectIds(projects, nextDomain)));
  }

  function toggleProject(id) {
    setSelectedProjectIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleDescribe(id) {
    setDescribeProjectIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function setProjectNote(id, value) {
    setProjectNotes((prev) => ({ ...prev, [id]: value }));
  }

  function selectAllProjects() {
    setSelectedProjectIds(new Set(projects.map((p) => p.id)));
  }

  function clearProjectSelection() {
    setSelectedProjectIds(new Set());
  }

  const selectedIssues = useMemo(
    () => issues.filter((i) => i.selected && i.title.trim()),
    [issues],
  );

  const guidanceNotes = notes.trim() || undefined;

  function addCustomIssue() {
    const title = newIssueTitle.trim();
    if (!title) {
      setError('Enter an issue title to add.');
      return;
    }
    setError('');
    setIssues((list) => [
      ...list,
      {
        id: crypto.randomUUID(),
        title,
        whyItFails: newIssueWhy.trim(),
        selected: true,
      },
    ]);
    setNewIssueTitle('');
    setNewIssueWhy('');
  }

  function removeIssue(index) {
    setIssues((list) => list.filter((_, i) => i !== index));
  }

  async function runExtract() {
    if (!jobDescription.trim()) {
      setError('Paste a job description first.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const result = await extractIssues({
        jobDescription: jobDescription.trim(),
        domain,
        language,
        notes: guidanceNotes,
      });
      const list = (result.issues || []).map((issue) => ({
        ...issue,
        selected: true,
      }));
      if (!list.length) {
        setError('No issues returned. Try again.');
        return;
      }
      setIssues(list);
      setStep(1);
    } catch (err) {
      setError(err.message || 'Failed to extract issues');
    } finally {
      setBusy(false);
    }
  }

  async function runSolutions() {
    if (!selectedIssues.length) {
      setError('Select at least one issue.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const result = await suggestSolutions({
        jobDescription: jobDescription.trim(),
        domain,
        issues: selectedIssues.map(({ id, title, whyItFails }) => ({
          id,
          title: title.trim(),
          whyItFails: whyItFails || '',
        })),
        notes: guidanceNotes,
      });
      const list = result.solutions || [];
      if (!list.length) {
        setError('No solutions returned. Try again.');
        return;
      }
      setSolutions(list);
      setStep(2);
    } catch (err) {
      setError(err.message || 'Failed to suggest solutions');
    } finally {
      setBusy(false);
    }
  }

  async function runDraft() {
    const cleanedSolutions = solutions.filter((s) => (s.offer || '').trim());
    if (!cleanedSolutions.length) {
      setError('Add at least one solution.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const selectedProjects = projects.filter((p) => selectedProjectIds.has(p.id));

      const result = await draftProposal({
        jobDescription: jobDescription.trim(),
        domain,
        language,
        issues: selectedIssues.map(({ id, title, whyItFails }) => ({
          id,
          title: title.trim(),
          whyItFails: whyItFails || '',
        })),
        solutions: cleanedSolutions.map((s) => ({
          issueId: s.issueId,
          issueTitle: s.issueTitle,
          offer: s.offer.trim(),
        })),
        projects: selectedProjects.map((p) => ({
          name: p.name,
          description: p.description || null,
          types: p.types,
          playStoreUrl: p.playStoreUrl,
          appStoreUrl: p.appStoreUrl,
          webUrl: p.webUrl,
          describe: describeProjectIds.has(p.id),
          mentionNote: (projectNotes[p.id] || '').trim() || null,
        })),
        templateBody: selectedTemplate?.body?.trim() || undefined,
        inspiredFrom: selectedTemplate?.inspiredFrom?.trim() || undefined,
        clientName: clientName.trim() || undefined,
        notes: guidanceNotes,
      });

      const body = (result.body || '').trim();
      if (!body) {
        setError('Empty draft returned. Try again.');
        return;
      }
      setDraftBody(body);
      setStep(3);
    } catch (err) {
      setError(err.message || 'Failed to generate draft');
    } finally {
      setBusy(false);
    }
  }

  function useDraft() {
    const body = draftBody.trim();
    if (!body) {
      setError('Draft is empty.');
      return;
    }
    navigate(returnTo, {
      replace: true,
      state: {
        formSnapshot,
        aiBody: body,
      },
    });
  }

  async function saveAiDraft() {
    const body = draftBody.trim();
    if (!body) {
      setError('Draft is empty.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const created = await createAiDraft({
        id: crypto.randomUUID(),
        title: titleFromJob(jobDescription),
        jobDescription: jobDescription.trim(),
        notes: guidanceNotes || null,
        domain,
        language,
        issues: selectedIssues.map(({ id, title, whyItFails }) => ({
          id,
          title: title.trim(),
          whyItFails: whyItFails || '',
        })),
        solutions: solutions
          .filter((s) => (s.offer || '').trim())
          .map((s) => ({
            issueId: s.issueId,
            issueTitle: s.issueTitle,
            offer: s.offer.trim(),
          })),
        body,
        clientName: clientName.trim() || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      navigate(`/ai-drafts/${created.id}`, { replace: true });
    } catch (err) {
      setError(err.message || 'Failed to save AI draft');
    } finally {
      setBusy(false);
    }
  }

  function primaryAction() {
    if (step === 0) return runExtract();
    if (step === 1) return runSolutions();
    if (step === 2) return runDraft();
    return useDraft();
  }

  const primaryLabel =
    step === 0
      ? 'Extract issues'
      : step === 1
        ? 'Suggest solutions'
        : step === 2
          ? 'Generate draft'
          : 'Use draft';

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h1>Generate with AI</h1>
          <p className="muted" style={{ margin: '4px 0 0' }}>
            Issues → solutions → draft, same flow as the mobile app.
          </p>
        </div>
        <Link to={returnTo} className="btn btn-ghost" state={{ formSnapshot }}>
          Cancel
        </Link>
      </div>

      <div className="ai-steps" aria-label="Wizard progress">
        {STEPS.map((label, index) => (
          <div
            key={label}
            className={`ai-step ${index <= step ? 'active' : ''} ${index === step ? 'current' : ''}`}
          >
            <span className="ai-step-num">{index + 1}</span>
            <span>{label}</span>
          </div>
        ))}
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      {step === 0 ? (
        <div className="form panel">
          <label className="field">
            <span>Job description *</span>
            <textarea
              rows={10}
              value={jobDescription}
              onChange={(e) => setJobDescription(e.target.value)}
              placeholder="Paste the Upwork job posting here…"
              disabled={busy}
            />
          </label>

          <label className="field">
            <span>Notes / guidance</span>
            <textarea
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder='e.g. also mention issues that will reduce income or increase costs'
              disabled={busy}
            />
          </label>

          <label className="field">
            <span>Domain</span>
            <select
              value={domain}
              onChange={(e) => changeDomain(e.target.value)}
              disabled={busy}
            >
              {AI_DOMAINS.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </label>

          <div className="field">
            <div className="ai-project-picker-header">
              <span>Projects to mention</span>
              {projects.length ? (
                <span className="ai-project-picker-actions">
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    onClick={selectAllProjects}
                    disabled={busy || projectsLoading}
                  >
                    Select all
                  </button>
                  <button
                    type="button"
                    className="btn btn-ghost btn-sm"
                    onClick={clearProjectSelection}
                    disabled={busy || projectsLoading}
                  >
                    Clear
                  </button>
                </span>
              ) : null}
            </div>
            {projectsLoading ? (
              <p className="muted">Loading projects…</p>
            ) : projects.length === 0 ? (
              <p className="muted">
                No projects yet.{' '}
                <Link to="/projects">Add projects</Link> so the AI can mention them.
              </p>
            ) : (
              <div className="ai-project-picker">
                {projects.map((project) => {
                  const selected = selectedProjectIds.has(project.id);
                  return (
                    <div key={project.id} className="ai-project-item">
                      <label className="checkbox-field">
                        <input
                          type="checkbox"
                          checked={selected}
                          onChange={() => toggleProject(project.id)}
                          disabled={busy}
                        />
                        <span className="ai-project-item-text">
                          <strong>{project.name}</strong>
                          <span>{previewDescription(project.description)}</span>
                        </span>
                      </label>
                      {selected ? (
                        <div className="ai-project-item-options">
                          <label className="checkbox-field">
                            <input
                              type="checkbox"
                              checked={describeProjectIds.has(project.id)}
                              onChange={() => toggleDescribe(project.id)}
                              disabled={busy}
                            />
                            <span>Describe it</span>
                          </label>
                          <label className="field">
                            <span>Specific note</span>
                            <input
                              type="text"
                              value={projectNotes[project.id] || ''}
                              onChange={(e) => setProjectNote(project.id, e.target.value)}
                              placeholder="e.g. how you improved this app's security"
                              maxLength={500}
                              disabled={busy}
                            />
                          </label>
                        </div>
                      ) : null}
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          <label className="field">
            <span>Language</span>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              disabled={busy}
            >
              {LANGUAGES.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </label>

          <label className="field">
            <span>Inspire from template</span>
            <select
              value={selectedTemplateId}
              onChange={(e) => setSelectedTemplateId(e.target.value)}
              disabled={busy}
            >
              <option value="">None</option>
              {templates.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name} ({labelFor(PROPOSAL_PROJECT_TYPES, t.projectType)})
                </option>
              ))}
            </select>
          </label>
        </div>
      ) : null}

      {step === 1 ? (
        <div className="ai-cards">
          {issues.map((issue, index) => (
            <div key={issue.id || index} className="ai-card">
              <div className="ai-card-header">
                <label className="checkbox-field">
                  <input
                    type="checkbox"
                    checked={Boolean(issue.selected)}
                    onChange={(e) => {
                      const selected = e.target.checked;
                      setIssues((list) =>
                        list.map((item, i) =>
                          i === index ? { ...item, selected } : item,
                        ),
                      );
                    }}
                    disabled={busy}
                  />
                  <span>Include</span>
                </label>
                <button
                  type="button"
                  className="btn btn-ghost btn-sm"
                  onClick={() => removeIssue(index)}
                  disabled={busy}
                  aria-label="Remove issue"
                >
                  Remove
                </button>
              </div>
              <label className="field">
                <span>Issue</span>
                <input
                  value={issue.title}
                  onChange={(e) => {
                    const title = e.target.value;
                    setIssues((list) =>
                      list.map((item, i) =>
                        i === index ? { ...item, title } : item,
                      ),
                    );
                  }}
                  disabled={busy}
                />
              </label>
              <label className="field">
                <span>Why it matters</span>
                <textarea
                  rows={2}
                  value={issue.whyItFails || ''}
                  onChange={(e) => {
                    const whyItFails = e.target.value;
                    setIssues((list) =>
                      list.map((item, i) =>
                        i === index ? { ...item, whyItFails } : item,
                      ),
                    );
                  }}
                  disabled={busy}
                />
              </label>
            </div>
          ))}

          <div className="ai-card ai-add-issue">
            <h3>Add your own issue</h3>
            <label className="field">
              <span>Issue title</span>
              <input
                value={newIssueTitle}
                onChange={(e) => setNewIssueTitle(e.target.value)}
                placeholder="e.g. High no-show rate cutting revenue"
                disabled={busy}
              />
            </label>
            <label className="field">
              <span>Why it matters (optional)</span>
              <textarea
                rows={2}
                value={newIssueWhy}
                onChange={(e) => setNewIssueWhy(e.target.value)}
                placeholder="Short reason this matters for the client"
                disabled={busy}
              />
            </label>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={addCustomIssue}
              disabled={busy}
            >
              Add issue
            </button>
          </div>
        </div>
      ) : null}

      {step === 2 ? (
        <div className="ai-cards">
          {solutions.map((solution, index) => (
            <div key={solution.issueId || index} className="ai-card">
              <h3>{solution.issueTitle}</h3>
              <label className="field">
                <span>Your offer / solution</span>
                <textarea
                  rows={3}
                  value={solution.offer}
                  onChange={(e) => {
                    const offer = e.target.value;
                    setSolutions((list) =>
                      list.map((item, i) =>
                        i === index ? { ...item, offer } : item,
                      ),
                    );
                  }}
                  disabled={busy}
                />
              </label>
            </div>
          ))}
        </div>
      ) : null}

      {step === 3 ? (
        <div className="form panel">
          <p className="muted">
            Review and edit before applying to the proposal form.
          </p>
          <label className="field">
            <span>Proposal body</span>
            <textarea
              rows={16}
              value={draftBody}
              onChange={(e) => setDraftBody(e.target.value)}
              dir={language === 'arabic' ? 'rtl' : 'ltr'}
              disabled={busy}
            />
          </label>
        </div>
      ) : null}

      <div className="form-actions ai-actions">
        {step > 0 ? (
          <button
            type="button"
            className="btn btn-ghost"
            disabled={busy}
            onClick={() => {
              setError('');
              setStep((s) => s - 1);
            }}
          >
            Back
          </button>
        ) : (
          <span />
        )}
        <div style={{ display: 'flex', gap: 8 }}>
          {step === 3 ? (
            <button
              type="button"
              className="btn btn-secondary"
              disabled={busy}
              onClick={saveAiDraft}
            >
              Save AI draft
            </button>
          ) : null}
          <button
            type="button"
            className="btn btn-primary"
            disabled={busy}
            onClick={primaryAction}
          >
            {busy ? 'Working…' : primaryLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
