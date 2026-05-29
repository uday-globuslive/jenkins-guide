# Module 01: Architecture and Installation (Kid Mode)

## Story
School example:
- principal = controller
- classrooms = agents
- students working = pipeline steps

## What each part does
- Controller plans and tracks work.
- Agent runs commands.

## Master-Slave and Executors (simple words)
Some people still say Master-Slave. In modern docs, think Controller-Agent.

- Master (old word) = Controller
- Slave (old word) = Agent

### What is an Executor?
Executor is a worker slot on a node.

Example:
- If an agent has 2 executors, it can run 2 builds at the same time.
- If controller has executors set to 0, controller only manages and does not run builds.

Beginner rule:
- Keep controller executors low (or 0 for production style).
- Put build workload on agents.

## Easy install path
Use Docker Compose first.
Why: easy start, easy reset.

## First setup steps
1. Start Jenkins
2. Open browser on Jenkins URL
3. Create admin user
4. Install needed plugins only
5. Run one test pipeline

## Safety basics
- enable authentication
- do not use default weak passwords
- backup Jenkins data

## Copy-Paste Commands
Use these from the repository root.

```bash
cd ~/jenkins-guide
chmod +x setup.sh
sudo ./setup.sh
docker-compose ps
docker-compose logs -f jenkins
```

```powershell
cd e:/jenkins-guide
docker compose up -d
docker compose ps
docker compose logs -f jenkins
```

Open browser:
- http://YOUR_SERVER_IP:8080
