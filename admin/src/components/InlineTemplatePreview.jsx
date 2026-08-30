import {
  placeholderLabel,
  splitTemplate,
} from '../utils/templatePlaceholders';

export default function InlineTemplatePreview({
  body,
  values,
  modes = {},
  onChange,
  onFillField,
  onToggleMode,
  busy = false,
  busyKey = null,
}) {
  const paragraphs = [];
  let current = [];

  function flush() {
    if (!current.length) return;
    paragraphs.push(current);
    current = [];
  }

  for (const segment of splitTemplate(body)) {
    if (segment.text != null) {
      const parts = String(segment.text).split('\n');
      parts.forEach((part, index) => {
        if (part) current.push({ text: part });
        if (index < parts.length - 1) flush();
      });
    } else if (segment.token) {
      current.push({ token: segment.token });
    }
  }
  flush();

  return (
    <div className="inline-template">
      {paragraphs.map((spans, pIndex) => (
        <p key={pIndex} className="inline-template-line">
          {spans.map((span, sIndex) =>
            span.token ? (
              <span
                key={`${span.token}-${sIndex}`}
                className={`inline-template-field${
                  modes[span.token] === 'note' ? ' is-note' : ''
                }`}
              >
                <button
                  type="button"
                  className="inline-mode-toggle"
                  onClick={() => onToggleMode(span.token)}
                  disabled={busy}
                  title={
                    modes[span.token] === 'note'
                      ? 'Note: AI will rewrite this as the real field'
                      : 'Absolute: use this text as-is'
                  }
                >
                  {modes[span.token] === 'note' ? 'Note' : 'Abs'}
                </button>
                <input
                  value={values[span.token] || ''}
                  onChange={(e) => onChange(span.token, e.target.value)}
                  placeholder={
                    modes[span.token] === 'note'
                      ? 'Instruction…'
                      : placeholderLabel(span.token)
                  }
                  disabled={busy}
                />
                <button
                  type="button"
                  className="btn btn-ghost btn-inline"
                  onClick={() => onFillField(span.token)}
                  disabled={busy}
                  title="Fill with AI"
                >
                  {busyKey === span.token ? '…' : 'AI'}
                </button>
              </span>
            ) : (
              <span key={`t-${sIndex}`}>{span.text}</span>
            ),
          )}
        </p>
      ))}
    </div>
  );
}
