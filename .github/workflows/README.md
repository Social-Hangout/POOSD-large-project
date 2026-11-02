# Deployment

`deploy.yml` runs on every push to `main`, or manually from the Actions tab (Run workflow). It builds the React frontend and rsyncs `frontend/dist/` to `/var/www/html/`, then rsyncs `api/` to `~/api` (the deploy user's home) and restarts the Express server with pm2.

## Server

DigitalOcean droplet running Ubuntu 24.04. The web server is **nginx**. Apache is installed but disabled, so ignore any Apache config.

### Requirements

- Node 24 LTS installed system-wide (NodeSource apt, not nvm, so non-interactive SSH finds it) and `npm install -g pm2`
- pm2 starts on boot through the `pm2-deploy` systemd service. After changing which processes run, the `deploy` user runs `pm2 save` (the workflow does this on every deploy).
- `~/api/.env` owned by `deploy` (`chmod 600`), with every variable from `api/.env.example`. It isn't in the repo and deploys never overwrite it. In production:
  - `NODE_ENV=production`
  - `PORT=5000`
  - `HOST=127.0.0.1`, so Express is only reachable through nginx
  - `CORS_ORIGIN=https://contactshub.site`
  - `APP_URL=https://contactshub.site`
  - `SMTP_PORT=2525`, because DigitalOcean blocks outbound SMTP on 25, 465 and 587
  - `MONGO_URI=mongodb://recipeApp:<password>@127.0.0.1:27017/recipes?authSource=admin` (see [MongoDB](#mongodb))
  - `MONGO_URI`, `APP_URL` and `JWT_SECRET` (at least 32 random characters) are required. Without them the API won't start and `/api/...` returns 502.
- A firewall that only allows SSH, HTTP and HTTPS, so port 5000 is never reachable from outside even if `HOST` is missing from `.env`:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status    # should list only OpenSSH and Nginx Full
```

### MongoDB

MongoDB runs on the droplet (not Atlas), so it has to be locked down by hand. As an admin:

1. Check it only listens locally: `sudo ss -tlnp | grep 27017` should show `127.0.0.1:27017`, not `0.0.0.0`. If not, set `bindIp: 127.0.0.1` under `net:` in `/etc/mongod.conf`.
2. Create an admin user and an app user that can only use the `recipes` database. Generate the app password with `openssl rand -hex 24` (hex needs no escaping in the URI):

```js
// sudo mongosh
use admin
db.createUser({ user: "admin", pwd: passwordPrompt(), roles: ["userAdminAnyDatabase"] })
db.createUser({ user: "recipeApp", pwd: passwordPrompt(), roles: [{ role: "readWrite", db: "recipes" }] })
```

3. Require passwords by adding this to `/etc/mongod.conf`, then `sudo systemctl restart mongod`:

```yaml
security:
  authorization: enabled
```

4. Start it on boot: `sudo systemctl enable mongod`.
5. Put the app user in `~/api/.env` as `MONGO_URI` (format above). Use `127.0.0.1`, not `localhost`.

Nothing backs the data up automatically. Run `mongodump` before risky changes.

### nginx

Config is `/etc/nginx/sites-enabled/default`, edited as root. Both the port 80 server block and the HTTPS server block need these two locations:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}

location /api/ {
    proxy_pass http://127.0.0.1:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

- The `proxy_set_header` lines pass the real client IP to Express (`server.js` trusts them from `127.0.0.1` only). Without them every request looks like it came from `127.0.0.1`, so per-IP rate limits would lump all users together.

- `try_files ... /index.html` lets React Router handle paths that aren't files. Without it, the `/verify` and `/reset-password` links in emails return 404. Replace the default `try_files $uri $uri/ =404;` line; don't add a second `location /`.
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
| `SSH_KNOWN_HOSTS` | the server's SSH host key, as a `known_hosts` line (see below) |
| `SERVER_IP`       | the server's IP address |
| `SERVER_USER`     | `deploy`                |

### `SSH_KNOWN_HOSTS`

The workflow refuses to deploy without it, so a server impersonating the droplet can't receive the deploy.

1. On your own machine, run `ssh-keyscan -t ed25519 <SERVER_IP>` and copy the line it prints.
2. Check it's really the droplet. Run `ssh-keygen -lf - <<< "<that line>"` locally, and `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the droplet (through the DigitalOcean web console). The two `SHA256:` fingerprints must match.
3. Save the line as the `SSH_KNOWN_HOSTS` secret. Update it only if the droplet is rebuilt.

## Warnings

- `rsync --delete` removes anything in `/var/www/html` that isn't in the build. The droplet currently serves the Small Project (`contactshub.site`) from there, so **the first deploy replaces the Small Project site**.
- A 502 from `/api/...` means nginx is up but the API process isn't running. Check `pm2 list` and `pm2 logs api` as `deploy`.
