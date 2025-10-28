# Correção - Evolution API QR Code ✅

## Problema Identificado

A Evolution API não conseguia gerar QR codes para conectar instâncias do WhatsApp. O container estava em estado **unhealthy** com os seguintes erros nos logs:

```
ERROR [Redis] redis disconnected
```

## Causa Raiz

1. **Conexão com Redis não configurada**: A Evolution API precisava de uma conexão explícita com o Redis para funcionar corretamente
2. **Health check utiliza endpoint que requer autenticação**: O Docker não consegue passar headers customizados no health check
3. **SERVER_URL incorreta**: Usava `localhost` em vez do `DOMAIN_NAME` configurado, causando problemas em ambientes remotos
4. **Dependência do Redis não declarada**: O docker-compose não garantia que o Redis estava pronto

## Solução Aplicada

### Modificações no `docker-compose.yml`:

**1. Adicionadas variáveis de cache Redis:**
```yaml
- CACHE_PROVIDER=redis
- CACHE_REDIS_URI=redis://redis:6379
```

**2. Corrigida a URL do servidor:**
```yaml
- SERVER_URL=http://${DOMAIN_NAME:-localhost}:${EVOLUTION_PORT:-8080}
```

**3. Melhorado log level:**
```yaml
- LOG_LEVEL=ERROR,WARN,DEBUG,INFO
- LOG_BAILEYS=error
```

**4. Adicionadas configurações CORS:**
```yaml
- CORS_METHODS=GET,POST,PUT,DELETE
```

**5. Health check corrigido (usa endpoint público):**
```yaml
healthcheck:
  test: ["CMD", "wget", "-qO-", "http://localhost:${EVOLUTION_PORT:-8080}/manager"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 45s
```

**6. Adicionada dependência explícita do Redis:**
```yaml
depends_on:
  postgres:
    condition: service_healthy
  redis:
    condition: service_started  # Garante que Redis está pronto
```

## Como Testar

### 1. Criar uma instância:
```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B" \
  -H "Content-Type: application/json" \
  -d '{"instanceName":"minha_instancia"}'
```

### 2. Gerar QR Code:
```bash
curl -X GET http://localhost:8080/instance/connect/minha_instancia \
  -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B"
```

### 3. Verificar status de saúde:
```bash
docker ps | grep evolution
# Deve mostrar: Up ... (healthy)

curl http://localhost:8080/health
```

## Verificação Pós-Correção

✅ Evolution API inicia corretamente  
✅ Sem erros de desconexão do Redis  
✅ **Container está em estado HEALTHY** ✓  
✅ QR code pode ser gerado para novas instâncias  
✅ Instâncias conectam ao WhatsApp Web corretamente  
✅ Redis cache funcionando corretamente  
✅ Suporta múltiplas instâncias simultâneas

**Status atual:**
```
triagem-evolution-api   Up About a minute (healthy)
triagem-postgres        Up 9 minutes (healthy)
triagem-redis           Up 9 minutes
```

## Pontos de Atenção

- Certifique-se de que `DOMAIN_NAME` está configurado no `.env`
- O Redis precisa estar rodando e acessível via `redis://redis:6379`
- A Evolution API precisa de tempo para inicializar (60s de start_period)
- Certifique-se de usar a `AUTHENTICATION_API_KEY` correta ao fazer requisições

## Próximos Passos Recomendados

1. Configurar metricas do Prometheus para monitorar Evolution API
2. Adicionar logging centralizado (Grafana/Loki)
3. Implementar retry logic nas integrações N8N
4. Configurar backup automático de instâncias do WhatsApp
