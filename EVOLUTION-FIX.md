# Correção do Evolution API

## Problema Identificado

O container `triagem-evolution` estava em loop de restart devido a erro de migração do Prisma:

```
Error: P3005
The database schema is not empty
```

## Causa Raiz

O Evolution API estava tentando criar tabelas no schema `public` do PostgreSQL, que já continha as tabelas do Django, causando conflito.

## Solução Implementada

### 1. Configuração do Schema Dedicado

Modificado o `docker-compose.yml` para usar um schema dedicado para o Evolution API:

```yaml
- DATABASE_CONNECTION_URI=postgresql://triagem_user:${POSTGRES_PASSWORD}@postgres:5432/triagem_db?schema=evolution_api
```

**Antes:** Sem especificação de schema (usava `public` por padrão)  
**Depois:** Schema dedicado `evolution_api`

### 2. Script de Inicialização

O script `/root/triagem-mvp/init-scripts/001_create_evolution_schema.sql` já estava criando o schema `evolution_api` corretamente.

### 3. Recriação do Container

```bash
docker compose stop evolution-api
docker compose rm -f evolution-api
docker compose up -d evolution-api
```

## Resultado

✅ Evolution API funcionando corretamente  
✅ Instância WhatsApp conectada e ativa  
✅ Endpoint `/instance/fetchInstances` respondendo  
✅ Separação clara entre schemas Django (public) e Evolution (evolution_api)

## Verificação

Para verificar se o Evolution está funcionando:

```bash
# Verificar status do container
docker ps --filter "name=triagem-evolution"

# Verificar logs
docker logs triagem-evolution --tail 50

# Testar API
curl -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B" http://localhost:8080/instance/fetchInstances
```

## Script de Verificação Completo

Criado o script `check-services.sh` que verifica:

- ✅ Status de todos os containers
- ✅ Health checks do PostgreSQL e Backup
- ✅ Conectividade de todos os serviços
- ✅ Schemas do banco de dados
- ✅ Portas expostas
- ✅ Volumes Docker

**Uso:**
```bash
./check-services.sh
```

## Serviços Disponíveis

| Serviço | URL | Status |
|---------|-----|--------|
| Frontend | http://localhost/ | ✅ |
| Django API | http://localhost:8000/api/docs/ | ✅ |
| Django Admin | http://localhost:8000/admin/ | ✅ |
| N8N | http://localhost:5678/ | ✅ |
| Evolution API | http://localhost:8080/ | ✅ |
| PostgreSQL | localhost:5432 | ✅ |
| Redis | localhost:6379 | ✅ |

## Instâncias WhatsApp

Atualmente há **1 instância** conectada:

- **Nome:** triagem-excaliweb
- **Status:** open (conectado)
- **Número:** 5531933015646
- **Integração:** WHATSAPP-BAILEYS

---

**Data da Correção:** 27 de outubro de 2025  
**Versão Evolution API:** 2.2.3
