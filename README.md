# Simple Jenkins Job — Docker-Jenkins Approach

CI/CD pipeline running locally using **Jenkins-in-Docker**, an **Angular portfolio** app, and a **Cloudflare Tunnel** for public HTTPS access via `ronaldcatibag.uk`.

## Architecture

```
  ronaldcatibag.uk
        |
  Cloudflare Tunnel (cloudflared)
        |
        v
      nginx :80  (reverse proxy / MFE router)
        |
        +--- /           ---> portfolio :80   (Angular app)
        +--- /jenkins/   ---> jenkins   :8080 (CI/CD)

  All containers on the "ci-net" Docker network.
  TLS is handled by Cloudflare — no local certificates needed.
```

## Project Structure

```
.
├── docker-compose.yml            # Orchestrates Nginx, Jenkins, portfolio, and cloudflared
├── Jenkinsfile                   # Pipeline: clone → build → deploy → smoke test
├── docker-jenkins/
│   └── server/
│       ├── Dockerfile            # Jenkins 2.549 JDK21 + plugins
│       ├── plugins.txt           # Pre-installed Jenkins plugins
│       └── jenkins.yaml          # Configuration as Code (CasC)
├── my-portfolio/
│   ├── Dockerfile                # Multi-stage: Angular build → Nginx
│   └── nginx.conf                # SPA routing for the Angular app
└── nginx/
    └── default.conf              # Reverse proxy: / → portfolio, /jenkins/ → Jenkins
```

## Quick Start

### 1. Clone the repo

```bash
git clone <this-repo-url>
cd simple-jenkins-job
```

### 2. Set the Cloudflare Tunnel token

Create a `.env` file (git-ignored):

```
CLOUDFLARE_TUNNEL_TOKEN=<your-token>
```

### 3. Start all services

```bash
docker compose up -d --build
```

### 4. Update Cloudflare tunnel route

In the Cloudflare dashboard, set the tunnel route for `ronaldcatibag.uk` to:

```
http://nginx:80
```

### 5. Verify

| Service   | Local URL                | Public URL                            |
|-----------|--------------------------|---------------------------------------|
| Portfolio | `http://localhost:80`     | `https://ronaldcatibag.uk/`           |
| Jenkins   | `http://localhost:8080`   | `https://ronaldcatibag.uk/jenkins/`   |

## How It Works

### MFE Approach

Nginx acts as a reverse proxy / micro-frontend router. All traffic enters through a single domain and Nginx routes by path:

- `/` → the Angular portfolio app
- `/jenkins/` → Jenkins CI/CD (running with `--prefix=/jenkins`)

Cloudflare Tunnel points to `http://nginx:80`, and Nginx distributes to the correct backend.

### Docker-Jenkins Approach

Jenkins runs **as a Docker container** with the host's Docker socket mounted (`/var/run/docker.sock`). This lets Jenkins run `docker build` and `docker run` against the host daemon — no native Jenkins installation needed.

### Pipeline Stages

| Stage              | What it does                                            |
|--------------------|---------------------------------------------------------|
| **Clone**          | Pulls `heroku/node-js-sample` from GitHub               |
| **Build Image**    | Writes a Dockerfile and builds `node-js-sample:latest`  |
| **Deploy**         | Stops old container, starts a fresh one on `ci-net`     |
| **Smoke Test**     | Waits 5 seconds, then curls the app to confirm it's up  |

### Idempotent Reruns

- Pipeline stops/removes the old app container before deploying a new one
- `docker compose up` is safe to re-run

## Ports

| Port | Service     | Access                          |
|------|-------------|---------------------------------|
| 80   | Nginx       | Entry point (tunneled)          |
| 8080 | Jenkins     | Direct local access             |
| 4200 | Portfolio   | Direct local access             |

## Security Notes

- No secrets stored in the repository (tunnel token via env var)
- TLS handled entirely by Cloudflare — no local cert management
- Docker socket mount grants Jenkins root-equivalent Docker access (acceptable for dev/lab)
- `.env` file is git-ignored

## Troubleshooting

```bash
# Check container status
docker compose ps

# View logs
docker logs -f nginx
docker logs -f jenkins
docker logs -f portfolio
docker logs -f cloudflared

# Rebuild everything
docker compose down -v
docker compose up -d --build

# Check tunnel connectivity
docker logs cloudflared | grep "connection registered"
```
