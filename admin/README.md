# Proposal Admin

Personal React admin panel for the Upwork proposal manager. Talks to the existing Express API with JWT auth.

## Setup

```bash
cd admin
npm install
```

Copy `.env.example` to `.env` if you need a custom API URL. Leave `VITE_API_BASE_URL` empty to use the Vite proxy (`/api` → `http://localhost:3000`).

## Run

1. Start the backend (from repo root):

```bash
cd backend
npm run dev
```

2. Start the admin SPA:

```bash
cd admin
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

## Login

Use the seeded backend user (from `backend` seed script), e.g.:

- Username: `nuru`
- Password: `nuru@123`

## Features

- Dashboard: hire rate, counts by status, hire rate by language/template
- Proposals: list/filter, create, edit, detail, status update, delete
- Templates: list/filter, create, edit, favorite, delete
- Projects: list/filter, create, edit, delete (portfolio apps)

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server on port 5173 |
| `npm run build` | Production build to `dist/` |
| `npm run preview` | Preview production build |
