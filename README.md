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
│       ├── API_DOCUMENTATION.md
│       ├── AUTHENTICATION.md
│       ├── CYBERSECURITY.md
│       ├── openapi.yaml
│       └── entrypoint.sh
└── frontend/
    └── project/
        ├── Dockerfile
        └── nginx.conf
```

## Documentation

- **[API Documentation](backend/project/API_DOCUMENTATION.md)**: Exhaustive endpoints catalog, query parameters, payloads, and JSON schemas.
- **[OpenAPI 3.0 Specification](backend/project/openapi.yaml)**: Importable into Swagger UI, Postman, and API tools.
- **[Authentication & Access Control](backend/project/AUTHENTICATION.md)**: Bcrypt hashing, Phoenix.Token lifecycle, AuthPlug, and RBAC matrix.
- **[Cybersecurity Architecture & Safeguards](backend/project/CYBERSECURITY.md)**: OWASP Top 10 API & Mobile defenses, IDOR protection, and checklist.
- **[Backend Architecture & File Guide](backend/project/architecture.md)**
- **[Frontend Architecture & File Guide](frontend/project/architecture.md)**



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

From the repository root, create `.env` from `.env.example`, set the required values listed above, then build and start the application:

```bash
cp .env.example .env
docker compose up --build -d
```

To start just the backend or frontend (Compose also starts required services):

```bash
docker compose up --build -d phoenix
docker compose up --build -d frontend
```

Open the app at <http://localhost>. Check status or follow logs with:

```bash
docker compose ps
docker compose logs -f
```

Stop the application with:

```bash
docker compose down
```

The PostgreSQL data is kept in the `db_data` volume when containers are stopped.
