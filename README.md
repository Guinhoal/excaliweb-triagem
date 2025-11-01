# Triagem MVP

Sistema de triagem médica com chatbot inteligente, integração WhatsApp e dashboard para médicos.

## Como subir localmente com Docker

1. **Configure as variáveis de ambiente:**
   - Copie o arquivo `.env.example` para `.env`:
     ```bash
     cp .env.example .env
     ```
   - Edite o arquivo `.env` e configure suas credenciais:
     - `POSTGRES_PASSWORD`: Senha do banco de dados
     - `DJANGO_SECRET_KEY`: Chave secreta do Django (use uma longa e aleatória)
     - `DOMAIN_NAME`: Seu domínio ou IP
     - `GROQ_API_KEY`: Sua chave da API Groq (obtenha em https://console.groq.com)
     - `EVOLUTION_API_KEY`: Chave da Evolution API para WhatsApp
     - Outras variáveis conforme necessário

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