# Triagem MVP

## Como subir localmente com Docker

1. Crie o arquivo `.env` (já existe um exemplo na raiz) com as variáveis:
- POSTGRES_PASSWORD, DJANGO_SECRET_KEY, DOMAIN_NAME, TZ

2. Suba os serviços:

```
docker compose up --build -d
```

3. Acesse:
- Backend API: http://localhost/api/docs (Swagger)
- Health: http://localhost/health
- Admin Django: http://localhost/admin (admin/admin123)
- Frontend Angular: http://localhost/

## Fluxo básico
- Cadastro: POST /api/auth/register
- Login: POST /api/auth/login
- Pré-triagem: POST /api/pre-triage/ (Bearer <token>)

## Observações
- O backend utiliza PostgreSQL via DATABASE_URL.
- O serviço Nginx faz proxy para o backend em /api.
- O entrypoint do Django aguarda o Postgres, aplica migrações e cria superusuário.