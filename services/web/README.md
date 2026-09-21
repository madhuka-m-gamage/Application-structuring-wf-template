# Web Frontend Service (`services/web/`)

The **Web Frontend Service** delivers the single-page application (SPA) dashboard for the **System Design-to-Deployment Template**. Serving responsive HTML5/CSS3/JavaScript assets, it incorporates an internal reverse proxy targeting the **Backend API Service**, eliminating local browser CORS constraints and mirroring production Cloud CDN / Load Balancer behavior.

---

## 1. Architectural Role & Standards

- **Runtime**: Node.js 20 LTS (Alpine multi-stage build) or Nginx unprivileged
- **Security**: Runs as unprivileged non-root user `appuser` (UID 10001)
- **Networking**: Ingress port `3000` (or `8080` in Cloud Run)
- **Reverse Proxy**: Seamlessly proxies all `/api/*` requests upstream to `API_URL`
- **Healthcheck Probe**: Native HTTP probe calling `/healthz`

---

## 2. Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/healthz` | Container liveness and upstream proxy probe |
| `GET` | `/` | Serves SPA `index.html` dashboard |
| `GET` | `/style.css`, `/app.js` | Static application assets |
| `*` | `/api/*` | Proxied directly to `API_URL` (Backend API) |

---

## 3. Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `PORT` | No | `3000` | Port on which the web server listens |
| `HOST` | No | `0.0.0.0` | Bind interface address |
| `API_URL` | No | `http://api:8080` | Upstream Backend API target URL |
| `NODE_ENV` | No | `development` | Runtime environment mode |

---

## 4. Local Development

### Prerequisites
- Node.js >= 20.0.0
- npm >= 10.0.0

### Run Locally (Standalone)
```bash
cd services/web
npm start
```
Open `http://localhost:3000` in your web browser.

### Run Tests & Linting
```bash
npm test
npm run lint
```

---

## 5. Container Execution

### Build Docker Image
```bash
docker build -t system-template-web:latest services/web/
```

### Run Container
```bash
docker run -p 3000:3000 \
  -e API_URL="http://host.docker.internal:8080" \
  system-template-web:latest
```

### Healthcheck Probe
```bash
wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/healthz || exit 1
```
