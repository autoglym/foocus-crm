# Focus CRM - Claude Code Handoff

## Project Overview
A lightweight CRM web app for tracking high-value clients and prospects, built as a single HTML file with Supabase backend.

## Tech Stack
- **Frontend**: Single HTML file with vanilla JS, no build step
- **Styling**: CSS custom properties (dark theme)
- **Fonts**: DM Sans + JetBrains Mono (Google Fonts)
- **Backend**: Supabase (PostgreSQL + Auth)
- **Hosting**: Netlify (static deploy)

## Supabase Config
```
URL: https://izeefglmytbszpsntcur.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6ZWVmZ2xteXRic3pwc250Y3VyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNjEwMTksImV4cCI6MjA3OTgzNzAxOX0.nfQZY4-7FRc15tKVZlIBwSRvhMS0C7i4KJyIhxf6YiU
```

## Database Schema

### clients
- id (UUID, PK)
- name (TEXT)
- category ('high_value_client' | 'high_value_target')
- deal_value (NUMERIC)
- probability (INTEGER, 0-100)
- logo (TEXT, base64)
- notes (TEXT)
- created_at, updated_at (TIMESTAMPTZ)

### tasks
- id (UUID, PK)
- client_id (UUID, FK → clients, CASCADE)
- title (TEXT)
- description (TEXT)
- due_date (DATE)
- due_time (TIME)
- importance ('low' | 'medium' | 'high')
- urgency ('low' | 'medium' | 'high')
- completed (BOOLEAN)
- created_at, updated_at (TIMESTAMPTZ)

### documents
- id (UUID, PK)
- client_id (UUID, FK → clients, CASCADE)
- name (TEXT)
- data (TEXT, base64)
- doc_type ('brief' | 'contract' | 'delivery_agreement' | 'other')
- created_at (TIMESTAMPTZ)

## Current Features

### Authentication
- Email/password signup and login via Supabase Auth
- Shared data model (all users see same data)
- Session persistence

### Dashboard
- 4 KPI cards: ARR Secured, ARR Weighted, Target ARR Weighted, Total Pipeline
- "Do First" section (urgent + important tasks)
- Filter tabs: All / Clients / Targets with counts
- Client/target card grid with deal value, probability badge, task/doc counts

### Client Detail View
- Logo upload (click to change)
- Tabs: Tasks, Documents, Notes
- Inline task completion
- Document upload and viewing

### Other Pages
- **All Tasks**: List view with filters (all/pending/completed)
- **Priority Matrix**: Eisenhower matrix (4 quadrants)
- **High Value Clients**: Filtered view
- **High Value Targets**: Filtered view
- **Documents**: All documents grouped by client
- **Break Even**: Operating cost input + thermometer visualization showing progress to break-even

### Design System
```css
--bg-primary: #0a0a0b
--bg-secondary: #111113
--bg-tertiary: #18181b
--bg-card: #141416
--border: #27272a
--text-primary: #fafafa
--text-secondary: #a1a1aa
--accent: #3b82f6
--client: #10b981 (green)
--target: #f59e0b (amber)
--urgent: #ef4444 (red)
--important: #8b5cf6 (purple)
```

## File Structure
Single file: `index.html` containing all HTML, CSS, and JS.

## Live URL
https://focus-crm.netlify.app (or your custom Netlify subdomain)

## Known Issues / TODO
- Operating cost in Break Even is stored in localStorage (per-browser), not Supabase
- Documents stored as base64 in database (works but not optimal for large files)
- No real-time sync between users (requires page refresh)
- No search functionality
- No recurring tasks

## Starting Point
The `index.html` file in this folder is the complete current version. Open it locally or deploy to Netlify to test.

---

## Prompt for Claude Code

```
I have a single-file CRM web app (index.html) that uses Supabase for auth and database. 

Tech: Vanilla JS, CSS custom properties, Supabase JS SDK via CDN.

Current features:
- Auth (email/password)
- Client/target management with deal values and probability
- Tasks with Eisenhower matrix priority
- Documents (base64 stored)
- Break Even visualization
- Dark theme

The file is self-contained - all HTML, CSS, JS in one file.

Please read index.html to understand the current implementation, then help me with: [YOUR REQUEST HERE]
```
