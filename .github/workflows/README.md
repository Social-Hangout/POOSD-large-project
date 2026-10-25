# Deployment

`deploy.yml` runs on every push to `main`, or manually from the Actions tab (Run workflow). It builds the React frontend and rsyncs `frontend/dist/` to `/var/www/html/`, then rsyncs `api/` to `~/api` (the deploy user's home) and restarts the Express server with pm2.

## Server requirements

- Node 24 LTS installed system-wide (e.g. NodeSource apt, not nvm, so non-interactive SSH finds it) and `npm install -g pm2`
- `~/api/.env` on the server with `MONGO_URI`, `PORT`, and `HOST=127.0.0.1` so Express is only reachable through Apache (not in the repo, never overwritten by deploys)
- Apache (`a2enmod proxy proxy_http`) proxying `/api` to Express, with a fallback for React Router:

```apache
ProxyPass        /api http://127.0.0.1:5000/api
ProxyPassReverse /api http://127.0.0.1:5000/api
FallbackResource /index.html
```

## Server deploy user

On the server there is a `deploy` user that can only write to the web root

## GitHub secrets

These are located on the Github repo at:

Settings → Secrets and variables → Actions:

| Secret            | Value                   |
|-------------------|-------------------------|
| `SSH_PRIVATE_KEY` | the private key         |
| `SERVER_IP`       | the server's IP address |
| `SERVER_USER`     | `deploy`                |

> `rsync --delete` removes anything in `/var/www/html` that isn't in the repo.
