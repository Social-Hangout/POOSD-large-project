# Deployment

`deploy.yml` runs on every push to `main`, or manually from the Actions tab (Run workflow). It builds the React frontend and rsyncs `frontend/dist/` to `/var/www/html/`, then rsyncs `api/` to `~/api` (the deploy user's home) and restarts the Express server with pm2.

## Server

DigitalOcean droplet running Ubuntu 24.04. The web server is **nginx**. Apache is installed but disabled, so ignore any Apache config.

### Requirements

- Node 24 LTS installed system-wide (NodeSource apt, not nvm, so non-interactive SSH finds it) and `npm install -g pm2`
- pm2 starts on boot through the `pm2-deploy` systemd service. After changing which processes run, the `deploy` user runs `pm2 save` (the workflow does this on every deploy).
- `~/api/.env` owned by `deploy`, with every variable from `api/.env.example`. It isn't in the repo and deploys never overwrite it. In production:
  - `PORT=5000`
  - `HOST=127.0.0.1`, so Express is only reachable through nginx
  - `APP_URL=https://contactshub.site`
  - `SMTP_PORT=2525`, because DigitalOcean blocks outbound SMTP on 25, 465 and 587

### nginx

Config is `/etc/nginx/sites-enabled/default`, edited as root. Both the port 80 server block and the HTTPS server block proxy the API:

```nginx
location /api/ {
    proxy_pass http://127.0.0.1:5000;
}
```

- Use `127.0.0.1`, not `localhost`, because `localhost` can resolve to IPv6 `::1`, where Express isn't listening.
- `proxy_pass` has no trailing path, so the full `/api/...` path reaches Express unchanged.
- The HTTPS certificate is managed by Certbot. Don't edit the Certbot-managed lines.

Test with `sudo nginx -t`, then apply with `sudo systemctl reload nginx`.

## Server deploy user

The workflow logs in as the `deploy` user, which has **no sudo**. `deploy` owns the API files, `~/api/.env` and the pm2 processes. Anything that needs root (nginx, installing Node or pm2, systemd) has to be done by an admin account.

## GitHub secrets

These are located on the GitHub repo at:

Settings → Secrets and variables → Actions:

| Secret            | Value                   |
|-------------------|-------------------------|
| `SSH_PRIVATE_KEY` | the private key         |
| `SERVER_IP`       | the server's IP address |
| `SERVER_USER`     | `deploy`                |

## Warnings

- `rsync --delete` removes anything in `/var/www/html` that isn't in the build. The droplet currently serves the Small Project (`contactshub.site`) from there, so **the first deploy replaces the Small Project site**.
- A 502 from `/api/...` means nginx is up but the API process isn't running. Check `pm2 list` and `pm2 logs api` as `deploy`.
