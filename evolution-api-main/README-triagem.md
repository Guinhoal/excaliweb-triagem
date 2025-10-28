# Evolution API na stack Triagem

Este guia rápido explica como configurar, subir e usar a Evolution API integrada ao seu ambiente (Docker Compose) desta stack de triagem.

## Onde a API roda
- Serviço: `evolution-api` (imagem oficial)
- Porta interna: 8080
- Porta externa: 8080 (mapeada no host)
- Proxy (Nginx): exposto em `/evolution` no domínio/host do droplet
- URL pública configurada: `SERVER_URL=http://${DOMAIN_NAME}/evolution`

Exemplos:
- Via Nginx: `http://SEU_DOMINIO_OU_IP/evolution`
- Direto na porta: `http://SEU_IP:8080` (sem o prefixo `/evolution`)

Use sempre o cabeçalho de autenticação global: `apikey: <EVOLUTION_API_KEY>`

## Variáveis relevantes (.env raiz)
- `EVOLUTION_API_KEY` (obrigatória) – já existe exemplo em `.env` do projeto
- `DOMAIN_NAME` – usado para formar o `SERVER_URL`

No docker-compose ajustamos:
- `SERVER_URL=http://${DOMAIN_NAME}/evolution`
- `DATABASE_CONNECTION_URI=...triagem_db?schema=evolution_api` (isola o schema)

## Subir os serviços
1. `docker compose up -d evolution-api` (ou `./manage.sh start` para tudo)
2. Ver logs: `docker compose logs -f evolution-api`
3. Health-check simples: `curl -H "apikey: $EVOLUTION_API_KEY" http://SEU_IP:8080/instance/fetchInstances`

Se você acessar via Nginx, use:
`curl -H "apikey: $EVOLUTION_API_KEY" http://SEU_DOMINIO/evolution/instance/fetchInstances`

## Fluxo básico de uso
1) Criar uma instância
- Endpoint: `POST /instance/create`
- Cabeçalhos: `Content-Type: application/json`, `apikey: <EVOLUTION_API_KEY>`
- Corpo mínimo (Baileys com QR Code):
```
{
  "instanceName": "triagem01",
  "integration": "WHATSAPP-BAILEYS",
  "qrcode": true
}
```
- Resposta inclui `instance.instanceId`, `status` e `qrcode` (com base64 e/ou pairingCode quando disponível).

2) Obter QR Code novamente (opcional)
- `GET /instance/qrCode/:instanceName`
- Cabeçalho: `apikey` (global OU token da instância)

3) Conectar/checar status
- Conectar manualmente: `GET /instance/connect/:instanceName`
- Estado da conexão: `GET /instance/connectionState/:instanceName`

4) Enviar mensagem de texto
- `POST /message/sendText/:instanceName`
- Cabeçalhos: `Content-Type: application/json`, `apikey: <TOKEN_DA_INSTANCIA_OU_GLOBAL>`
- Exemplo de corpo:
```
{
  "number": "5511999999999@s.whatsapp.net",
  "text": "Olá, mundo!"
}
```
Observação: o campo `number` espera o JID (com sufixo `@s.whatsapp.net`). Se enviar apenas dígitos, algumas rotas aceitam, mas o formato JID é o mais seguro.

5) Webhooks
- Webhook global já apontado para o backend Django: `WEBHOOK_GLOBAL_URL=http://django:8000/api/webhooks/whatsapp/`
- Você pode também configurar webhooks por instância via `POST /event/webhook/set/:instanceName` passando `{ "url": "http://..." }` e outras opções.

6) Buscar instâncias
- `GET /instance/fetchInstances` com `apikey` global

## Rotas úteis
- Criar: `POST /instance/create`
- Reiniciar: `POST /instance/restart/:instanceName`
- Conectar: `GET /instance/connect/:instanceName`
- Logout: `DELETE /instance/logout/:instanceName`
- QR Code: `GET /instance/qrCode/:instanceName`
- Status conexão: `GET /instance/connectionState/:instanceName`
- Enviar texto: `POST /message/sendText/:instanceName`
- Enviar mídia: `POST /message/sendMedia/:instanceName` (campo `file` ou `media` base64/url)

Todas as rotas acima requerem `apikey` no cabeçalho. Para rotas por instância, você pode usar o token retornado ao criar a instância.

## Dicas e troubleshooting
- Se o QR não aparecer: verifique logs e limite `QRCODE_LIMIT` (padrão 30). Reiniciar instância pode ajudar.
- Banco: usamos o mesmo Postgres do sistema, mas com schema dedicado `evolution_api`.
- Se usar via Nginx (`/evolution`), mantenha o `SERVER_URL` com esse prefixo — isso afeta links e callbacks.
- Para integrar com Chatwoot/N8N/EvoAI, habilite as flags correspondentes no `.env` da Evolution API (veja `evolution-api-main/.env.example`).

## Segurança
- Troque a `EVOLUTION_API_KEY` e mantenha-a fora de commits.
- Se expor publicamente, restrinja IPs no Nginx ou adicione WAF.

---
Qualquer dúvida, me chame que ajusto os endpoints/headers conforme seu fluxo.
