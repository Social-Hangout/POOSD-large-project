# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

UCF COP 4331C (POOSD, Fall 2026) Large Project. A recipe app: users type the ingredients they have and get recipes they can make with them, and can browse recipes, leave reviews, and comment.

Two clients use the same API:
- the React web app in this repo
- a Flutter mobile app (not in this repo)

So every API feature must work for both: JWT in the `Authorization: Bearer <token>` header, JSON in and out, and no cookie-only or browser-redirect-only flows.

## Course requirements (graded, do not substitute)

Stack:
- MERN only: MongoDB (Atlas), Express, React, Node.js. **No Python anywhere**, including scripts and tooling.
- Web frontend must use React with TypeScript. No plain HTML/CSS pages.
- Styling: a component/utility library such as Bootstrap or Tailwind is recommended by the course.
- Mobile app must use Flutter.

Backend features:
- **Email verification**: a new account must verify its email before it can log in. Include a resend-verification route.
- **Password reset by email**: request a reset (sends an email with a token or link), then submit a new password with that token.
- **JWT auth** for security. Passwords are hashed, and the password hash is never returned in any response.
- Email is sent with NodeMailer or SendGrid. New senders often land in spam, so test delivery to both a UCF address and a Gmail address.

## Email (decided: Nodemailer + Brevo SMTP)

- Provider: Brevo's free plan (300 emails/day, no time limit), sent through Nodemailer. Chosen over SendGrid, which only offers a 60-day trial, and over Gmail SMTP, which can't send from the droplet.
- **Port 2525, not 587/465.** DigitalOcean blocks outbound 25, 465 and 587 on droplets. Brevo accepts 2525 with STARTTLS, and `api/utils/mailer.js` requires TLS on it.
- Sender: an address on `contactshub.site`, which is authenticated in Brevo (Brevo code, DKIM, DMARC records in Cloudflare DNS). Brevo rewrites unauthenticated or free-mail senders such as gmail.com to `@brevosend.com`, so never use a Gmail address as the sender.
- The sender and link domains are config, not code: `MAIL_FROM` sets the From address and `APP_URL` sets the base URL for links in emails. Changing domains means changing `.env` and authenticating the new domain in Brevo, with no code changes.
- `SMTP_USER`/`SMTP_PASS` are Brevo's SMTP login and an **SMTP key**, not a Brevo API key.
- All mail goes through `sendEmail({ to, subject, html, text })` in `api/utils/mailer.js`. Always send both `html` and `text`.
- Test delivery with `node scripts/test-email.js <address>` (run from `api/`).

Documentation deliverables (keep the code consistent with these):
- API spec in SwaggerHub/OpenAPI. `docs/api-contract.md` is the source it gets converted from, so every route needs method, path, auth requirement, request fields with types, success response, and error responses with status codes.
- Unit and integration test results. There is no test framework yet; when one is added, new routes should come with tests.
- ER diagram, use-case diagram, sequence or activity diagram (PlantUML), class diagram for the mobile app, Gantt chart, and web/mobile prototypes. These live outside the code but should match it (for example, Mongoose models should match the ER diagram).

## Layout

- `api/`: Express server (CommonJS, Node >= 24). `server.js` is the entry point; `routes/`, `middleware/` and `models/` (Mongoose) are where features go. `utils/` holds shared helpers (the mailer); `scripts/` holds one-off scripts run by hand.
- `frontend/`: React 19 + TypeScript app scaffolded with Vite (ESM). Lint is oxlint.
- `.github/workflows/deploy.yml`: the only CI. See the deploy section below.
- API contract: `docs/api-contract.md` is the agreed source of truth for routes, shapes and error format. Its "Open questions" section lists what the team still has to decide. Build routes to match it, and change it in the same PR as the code. Ask before changing the contract, because the web and mobile clients both depend on it.

## API conventions

- All routes live under `/api`.
- Errors always use `{ "error": "message" }`.
- IDs are MongoDB ObjectId strings, returned as `id`, never `_id`. An invalid id returns 404, not 500.
- Users can only edit or delete their own content (recipes, reviews, comments). Enforce this in the route, not just the UI.
- List and search routes are paginated with `page` (default 1) and `limit` (default 20, max 50), and return `{ "<items>": [...], "page", "totalPages" }`. Bad values return 400.

## Commands

```bash
# API
cd api && npm install
npm run dev        # nodemon
npm start          # node server.js (what pm2 runs in production)

# Frontend
cd frontend && npm install
npm run dev        # Vite dev server on :5173
npm run build      # tsc -b && vite build -> frontend/dist
npm run lint       # oxlint
```

Health check: `curl http://localhost:<PORT>/api/health` returns `{"status":"ok"}`.

There is no test framework yet in either package.

## Local development gotchas

- **Port 5000 on macOS** is taken by AirPlay Receiver (responses come from `Server: AirTunes`, not Express). Set `PORT=5001` in `api/.env` and run the frontend with `API_URL=http://localhost:5001 npm run dev`.
- The frontend calls relative `/api/...` URLs. In dev, Vite proxies `/api` to `API_URL` (default `http://localhost:5000`, see `frontend/vite.config.ts`). In production, nginx does the proxying.
- `HOST` defaults to `0.0.0.0` so a phone on the same network can reach the API at `http://<LAN IP>:<PORT>/api/health`.
- Environment variables are listed in `api/.env.example` (names only). `.env` files are gitignored. Never commit secrets or hardcode them; when adding a variable, add its name to `.env.example`.

## Deployment

Server: DigitalOcean droplet, Ubuntu 24.04. The web server is **nginx, not Apache**. Apache is installed but disabled; ignore any Apache instructions or config.

Every push to `main` (or a manual run) triggers `deploy.yml`:
1. Builds `frontend/` with Node 24 and rsyncs `frontend/dist/` to `/var/www/html/` with `--delete`.
2. Rsyncs `api/` to `~/api` on the server (skipping `node_modules` and `.env`), then runs `npm ci --omit=dev` and restarts it with pm2 under the name `api`.

Server setup:
- The deploy workflow logs in as the `deploy` user. `deploy` has **no sudo**. The API files, `~/api/.env`, and pm2 all belong to `deploy`.
- pm2 starts on boot through the `pm2-deploy` systemd service. After changing which processes run, `deploy` runs `pm2 save`.
- nginx config is `/etc/nginx/sites-enabled/default`, edited as root. It proxies `location /api/` to `http://127.0.0.1:5000` in both the port 80 server block and the HTTPS server block, and `location /` uses `try_files $uri $uri/ /index.html;` so React routes such as the `/verify` and `/reset-password` email links don't 404.
- The server's `~/api/.env` is set up by hand and never overwritten by deploys. In production it sets `HOST=127.0.0.1`, so Express is only reachable through nginx. Use `127.0.0.1`, not `localhost`, in proxy config (localhost can resolve to IPv6 `::1`).
- The droplet also serves `contactshub.site` (our Small Project) from `/var/www/html`, with an HTTPS certificate from Certbot. Because the frontend deploy uses `--delete`, the first deploy replaces the Small Project site. Don't change the Certbot-managed lines in the nginx config.

Consequences:
- The backend must stay in `api/`, and both `package-lock.json` files must be committed, because the workflow runs `npm ci`.
- If the frontend build fails, the API doesn't deploy either.
- A 502 from `/api/...` in production means nginx is fine but the API process isn't running (check `pm2 list` as `deploy`).

Server setup details are in `.github/workflows/README.md`.

## Git conventions

- Branches are named `feature/<short-name>` (for example `feature/docs-api-contract`) and merge into `main` through PRs. Merging to `main` deploys.
- Commit messages: `type(scope): Summary` followed by `- ` bullet lines, for example `feat(api): Add Express server skeleton`.

## Working rules

- Don't add dependencies without saying why.
- Keep `docs/api-contract.md`, the Mongoose models, and the routes in sync.
- Ask before anything that touches the server, the deploy workflow, or the API contract.