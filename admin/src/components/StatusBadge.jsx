import { STATUS_COLORS, labelFor, STATUSES } from '../constants/enums';

export default function StatusBadge({ status }) {
  const colors = STATUS_COLORS[status] || STATUS_COLORS.submitted;
  return (
    <span
      className="badge"
      style={{ color: colors.fg, background: colors.bg }}
    >
      {labelFor(STATUSES, status)}
    </span>
  );
}
