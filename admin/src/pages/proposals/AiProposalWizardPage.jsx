import { useMemo, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { draftProposal, extractIssues, suggestSolutions } from '../../api/ai';
import { listProjects } from '../../api/projects';
import { LANGUAGES, PORTFOLIO_TYPES } from '../../constants/enums';

const STEPS = ['Job', 'Issues', 'Solutions', 'Draft'];

export default function AiProposalWizardPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const incoming = location.state || {};

  const returnTo = incoming.returnTo || '/proposals/new';
  const formSnapshot = incoming.formSnapshot || null;
  const initialLanguage = incoming.language || formSnapshot?.language || 'english';
  const templateBody = incoming.templateBody || '';
  const clientName = incoming.clientName || formSnapshot?.clientName || '';

  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const [jobDescription, setJobDescription] = useState('');
  const [notes, setNotes] = useState('');
  const [domain, setDomain] = useState('marketplace');
  const [language, setLanguage] = useState(initialLanguage);
  const [useTemplate, setUseTemplate] = useState(Boolean(templateBody.trim()));

  const [issues, setIssues] = useState([]);
  const [solutions, setSolutions] = useState([]);
  const [draftBody, setDraftBody] = useState('');
  const [newIssueTitle, setNewIssueTitle] = useState('');
  const [newIssueWhy, setNewIssueWhy] = useState('');

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
      const projects = await listProjects();
      const matching = (projects || []).filter((p) =>
        Array.isArray(p.types) ? p.types.includes(domain) : false,
      );

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
        projects: matching.map((p) => ({
          name: p.name,
          types: p.types,
          playStoreUrl: p.playStoreUrl,
          appStoreUrl: p.appStoreUrl,
          webUrl: p.webUrl,
        })),
        templateBody:
          useTemplate && templateBody.trim() ? templateBody.trim() : undefined,
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
              onChange={(e) => setDomain(e.target.value)}
              disabled={busy}
            >
              {PORTFOLIO_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </label>

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

          {templateBody.trim() ? (
            <label className="field checkbox-field">
              <input
                type="checkbox"
                checked={useTemplate}
                onChange={(e) => setUseTemplate(e.target.checked)}
                disabled={busy}
              />
              <span>Use current template style</span>
            </label>
          ) : null}
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
  );
}
