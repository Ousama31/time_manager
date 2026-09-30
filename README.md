# Time Manager

Time Manager is a three-service application:

- Vue 3 frontend served by Nginx
- Phoenix/Elixir API backend
- PostgreSQL 14 database

Docker Compose manages the complete stack from the repository root.

## Project structure

```text
time_manager/
├── docker-compose.yml
├── .env.example
├── backend/
│   └── project/
│       ├── Dockerfile
│       └── entrypoint.sh
└── frontend/
    └── project/
        ├── Dockerfile
        └── nginx.conf
```

## Requirements

- Docker Desktop
- Docker Compose v2, included with Docker Desktop

Confirm that Docker is available:

```bash
docker --version
docker compose version
```

## Environment configuration

Create the local environment file from the template:

```bash
cp .env.example .env
```

Change `PGPASSWORD` and generate a strong Phoenix secret:

```bash
openssl rand -base64 48
```

Place the generated value in `.env` as `SECRET_KEY_BASE`. Never commit `.env`; it contains secrets and is ignored by Git.

Required variables:

```text
PGUSER
PGPASSWORD
PGDATABASE
PGPORT
PGHOST
SECRET_KEY_BASE
PHX_HOST
```

## Run with Docker

From the repository root, build and start the complete application:

```bash
docker compose up --build -d
```

For subsequent starts, cached images can be used:

```bash
docker compose up -d
```

Check service status:

```bash
docker compose ps
```

Open the application:

- Frontend: <http://localhost>
- Backend API: <http://localhost:4000/api>
- PostgreSQL: `localhost:5432`

The backend waits for PostgreSQL, runs pending database migrations, and then starts Phoenix.

## Images

The local images are:

```text
time-manager:backend
time-manager:frontend
postgres:14
```

The backend uses a multi-stage production release and is designed to remain within approximately 300–400 MB. The frontend uses a multi-stage Vite build served by Nginx.

Build an individual image when needed:

```bash
docker build -t time-manager:backend backend/project
docker build -t time-manager:frontend frontend/project
```

## Logs and shutdown

Follow all logs:

```bash
docker compose logs -f
```

Follow one service:

```bash
docker compose logs -f phoenix
docker compose logs -f frontend
docker compose logs -f db
```

Stop and remove the containers and network:

```bash
docker compose down
```

The PostgreSQL data remains in the `db_data` volume. To also delete the database data, use the destructive command:

```bash
docker compose down -v
```

## Docker Hub

One Docker Hub repository can hold both application images under different tags:

```bash
docker tag time-manager:backend YOUR_USERNAME/time-manager:backend
docker tag time-manager:frontend YOUR_USERNAME/time-manager:frontend

docker push YOUR_USERNAME/time-manager:backend
docker push YOUR_USERNAME/time-manager:frontend
```

Use a Docker Hub access token instead of an account password for CI.

## Travis CI

The root `.travis.yml` builds and pushes both application images, then deploys the Compose stack over SSH when changes reach `main`.

Configure these variables in Travis:

```text
DOCKER_USERNAME
DOCKER_PASSWORD
DOCKER_IMAGE
FRONTEND_DOCKER_IMAGE
SSH_KEY
SERVER_USER
SERVER_IP
```

Example image values:

```text
DOCKER_IMAGE=YOUR_USERNAME/time-manager:backend
FRONTEND_DOCKER_IMAGE=YOUR_USERNAME/time-manager:frontend
```

`SSH_KEY` must contain the Base64-encoded deployment private key. The deployment server must have Docker Compose installed and an `.env` file beside `/home/SERVER_USER/docker-compose.yml` containing the required runtime variables.

## Troubleshooting

Inspect stopped or unhealthy containers:

```bash
docker compose ps -a
docker compose logs --tail=100
```

If `docker` is not found on macOS even though Docker Desktop is installed, add its CLI directory to the current terminal:

```bash
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
```

If PostgreSQL reports that no superuser password was specified, start it through Docker Compose instead of running `postgres:14` directly. Compose supplies the database variables from `.env`.
