export const STATUSES = [
  { value: 'submitted', label: 'Submitted' },
  { value: 'viewed', label: 'Viewed' },
  { value: 'responded', label: 'Responded' },
  { value: 'hired', label: 'Hired' },
  { value: 'rejected', label: 'Rejected' },
];

export const LANGUAGES = [
  { value: 'english', label: 'English' },
  { value: 'arabic', label: 'Arabic' },
];

export const PROPOSAL_PROJECT_TYPES = [
  { value: 'mobileApp', label: 'Mobile app' },
  { value: 'storeUpload', label: 'Play Store & App Store upload' },
  { value: 'other', label: 'Other' },
];

export const PORTFOLIO_TYPES = [
  { value: 'ecommerce', label: 'Ecommerce' },
  { value: 'marketplace', label: 'Marketplace' },
  { value: 'elearning', label: 'E-learning' },
  { value: 'booking', label: 'Booking' },
  { value: 'social', label: 'Social' },
  { value: 'delivery', label: 'Delivery' },
  { value: 'fintech', label: 'Fintech' },
  { value: 'healthcare', label: 'Healthcare' },
  { value: 'gaming', label: 'Gaming' },
  { value: 'other', label: 'Other' },
];

/** Domains for the AI proposal wizard only (includes portfolio + extras). */
export const AI_DOMAINS = [
  ...PORTFOLIO_TYPES.filter((t) => t.value !== 'other'),
  { value: 'restaurant', label: 'Restaurant' },
  { value: 'realEstate', label: 'Real estate' },
  { value: 'saas', label: 'SaaS' },
  { value: 'logistics', label: 'Logistics' },
  { value: 'travel', label: 'Travel' },
  { value: 'fitness', label: 'Fitness' },
  { value: 'agency', label: 'Agency' },
  { value: 'other', label: 'Other' },
];

export const STATUS_COLORS = {
  submitted: { fg: '#64748b', bg: '#f1f5f9' },
  viewed: { fg: '#b45309', bg: '#fef3c7' },
  responded: { fg: '#1d4ed8', bg: '#dbeafe' },
  hired: { fg: '#0f766e', bg: '#ccfbf1' },
  rejected: { fg: '#be123c', bg: '#ffe4e6' },
};

export function labelFor(options, value) {
  return options.find((o) => o.value === value)?.label ?? value ?? '—';
}
