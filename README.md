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

## Managing Jenkins

### Deployment Workflow (SSM)

After pushing changes to GitHub, redeploy on the EC2 instance:

```bash
aws ssm send-command \
  --instance-ids "<instance-id>" \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["export HOME=/root","cd /home/ec2-user/simple-jenkins-job && git pull origin main 2>&1","docker compose up -d --build > /tmp/compose-build.log 2>&1; echo EXIT_CODE=$?"]}' \
  --timeout-seconds 900 \
  --region ap-southeast-1 \
  --query 'Command.CommandId'
```

Check the result:

```bash
aws ssm get-command-invocation \
  --command-id "<command-id>" \
  --instance-id "<instance-id>" \
  --region ap-southeast-1 \
  --query '[Status, StandardOutputContent]' \
  --output text
```

If the build fails, read the log:

```bash
aws ssm send-command ... --parameters '{"commands":["tail -80 /tmp/compose-build.log"]}'
```

### Updating Plugins

Plugins are pinned in `docker-jenkins/server/plugins.txt` with exact versions (e.g. `git:5.9.0`). To update:

1. **Find the latest version** at [plugins.jenkins.io](https://plugins.jenkins.io/) or the Jenkins update center
2. **Edit `plugins.txt`** — change the version after the colon:
   ```
   git:5.10.0              # was git:5.9.0
   docker-plugin:1316.v75635a_002b_0a_
   ```
3. **Commit, push, and redeploy** using the SSM workflow above
4. **If plugin install fails** — check the build log for dependency errors. Common fixes:
   - Update the conflicting dependency plugin too
   - Use `--latest false` flag in the Dockerfile to prevent auto-upgrading transitive deps
   - Check the plugin's page for minimum Jenkins version requirements

### Adding New Plugins

1. Find the plugin at [plugins.jenkins.io](https://plugins.jenkins.io/)
2. Add it to `docker-jenkins/server/plugins.txt`:
   ```
   your-new-plugin:1.2.3
   ```
3. Commit, push, redeploy — `jenkins-plugin-cli` resolves transitive dependencies automatically

### Upgrading Jenkins Version

1. **Edit `docker-jenkins/server/Dockerfile`** — change the base image tag:
   ```dockerfile
   FROM jenkins/jenkins:2.560-jdk21    # was 2.549-jdk21
   ```
2. **Check plugin compatibility** — major Jenkins upgrades may break pinned plugins. Run a local build first:
   ```bash
   cd docker-jenkins/server
   docker build -t jenkins-test .
   ```
3. If plugins fail, update them in `plugins.txt` to versions compatible with the new Jenkins
4. Once the local build passes, push and redeploy

### Configuration as Code (CasC)

Jenkins configuration lives in `docker-jenkins/server/jenkins.yaml` and is mounted via docker-compose. Changes to this file take effect on container restart — no rebuild needed:

```bash
# After pushing jenkins.yaml changes:
docker compose restart jenkins
```

CasC manages: security realm, authorization, cloud agents, credentials, job DSL seeds, and global settings.

### Key Files

| File | Purpose | Requires rebuild? |
|------|---------|-------------------|
| `docker-jenkins/server/plugins.txt` | Plugin list with pinned versions | Yes (`docker compose up --build`) |
| `docker-jenkins/server/Dockerfile` | Jenkins base image + plugin install | Yes |
| `docker-jenkins/server/jenkins.yaml` | CasC config (security, agents, jobs) | No (restart only) |
| `docker-jenkins/agent/Dockerfile` | Build agent image (for Docker cloud) | Yes |
| `docker-compose.yml` | Service definitions and env vars | Yes if structure changes |

### Agent Strategy (t3.micro)

On a `t3.micro` (1 GB RAM + 2 GB swap), use the **built-in controller node** for builds:

- Set `numExecutors: 1` in `jenkins.yaml` (limit to 1 concurrent build)
- Use `agent any` in Jenkinsfiles
- Docker cloud agents are defined but will compete for the same limited resources

When you scale to a larger instance or add dedicated agent nodes, switch `numExecutors: 0` on the controller and route builds to Docker cloud agents or SSH agents.

### Backup & Restore

Jenkins state lives in the `jenkins_home` Docker volume:

```bash
# Backup
docker run --rm -v simple-jenkins-job_jenkins_home:/data -v $(pwd):/backup alpine \
  tar czf /backup/jenkins-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restore
docker compose down
docker run --rm -v simple-jenkins-job_jenkins_home:/data -v $(pwd):/backup alpine \
  tar xzf /backup/jenkins-backup-YYYYMMDD.tar.gz -C /data
docker compose up -d
```

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
docker compose down
docker compose up -d --build

# Check tunnel connectivity
docker logs cloudflared | grep "connection registered"

# Jenkins plugin dependency error during build
# Read the build log for the exact conflict, then update
# the offending plugin version in plugins.txt
tail -80 /tmp/compose-build.log
```
