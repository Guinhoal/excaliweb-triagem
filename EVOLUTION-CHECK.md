# 🚀 Guia Completo de Verificação - Evolution API

## 📊 Status da Aplicação

Seu Evolution API está configurado da seguinte forma:

| Componente | Configuração |
|-----------|-------------|
| **Porta** | 8080 |
| **URL** | http://localhost:8080 |
| **API Key** | AE8099A0180B46AA9D1598A294D0BB2B |
| **Banco de Dados** | PostgreSQL (triagem_db) |
| **Webhook** | http://django:8000/api/webhooks/whatsapp/ |

---

## ✅ Checklist de Verificação

### 1. **Verificar Container**
```bash
# Ver status do container
docker ps -a | grep evolution

# Ver logs em tempo real
docker logs triagem-evolution -f

# Ver últimos 50 logs
docker logs triagem-evolution --tail 50
```

**Sinais Positivos:**
- ✅ Container com status "Up"
- ✅ "Server running on port 8080"
- ✅ "Connected to database"

---

### 2. **Testar Health Check**
```bash
curl -X GET http://localhost:8080/health
```

**Resposta Esperada:**
```json
{
  "status": "ok"
}
```

---

### 3. **Listar Instâncias Ativas**
```bash
curl -X GET http://localhost:8080/instance/fetchInstances \
  -H "Content-Type: application/json" \
  -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B"
```

**Resposta Esperada:**
```json
{
  "status": 200,
  "data": []  // ou lista de instâncias se houver
}
```

---

### 4. **Testar Criar Instância de Teste**
```bash
curl -X POST http://localhost:8080/instance/create \
  -H "Content-Type: application/json" \
  -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B" \
  -d '{
    "instanceName": "test-instance",
    "qrcode": true
  }'
```

---

### 5. **Verificar Webhooks Configurados**
```bash
# Listar webhooks
curl -X GET http://localhost:8080/webhook/find \
  -H "Content-Type: application/json" \
  -H "apikey: AE8099A0180B46AA9D1598A294D0BB2B"
```

---

### 6. **Testar Conexão com Django**
```bash
# Health do Django
curl -X GET http://localhost:8000/health

# Ver se webhook está pronto
curl -X GET http://localhost:8000/api/webhooks/whatsapp/ \
  -H "Content-Type: application/json"
```

---

## 🔧 Verificações Avançadas

### A. **Verificar Variáveis de Ambiente**
```bash
docker exec triagem-evolution env | grep -E "EVOLUTION|DATABASE|WEBHOOK"
```

### B. **Verificar Espaço em Disco**
```bash
docker exec triagem-evolution df -h /evolution
```

### C. **Verificar Permissões de Volumes**
```bash
ls -la /var/lib/docker/volumes/triagem-mvp_evolution_data/_data/
```

### D. **Testar Banco de Dados Diretamente**
```bash
# Conectar ao PostgreSQL
docker exec -it triagem-postgres psql -U triagem_user -d triagem_db

# Dentro do psql:
SELECT version();
\dt  -- listar tabelas da Evolution

# Sair com \q
```

### E. **Verificar Logs de Erro Específicos**
```bash
# Todos os erros
docker logs triagem-evolution 2>&1 | grep -i error

# Erros de conexão
docker logs triagem-evolution 2>&1 | grep -i "connection\|connect"

# Erros de autenticação
docker logs triagem-evolution 2>&1 | grep -i "auth\|apikey"
```

---

## 🚨 Troubleshooting

### Problema: "Connection refused"
```bash
# Solução: Verificar se a porta 8080 está aberta
netstat -tuln | grep 8080

# Se não aparecer, reiniciar container
docker restart triagem-evolution
```

### Problema: "Database connection failed"
```bash
# Verificar credenciais PostgreSQL
docker logs triagem-postgres -f

# Testar conexão manualmente
docker exec triagem-postgres psql -U triagem_user -d triagem_db -c "SELECT 1;"
```

### Problema: "API Key invalid"
```bash
# Verificar se a chave está correta no .env
cat /root/triagem-mvp/.env | grep EVOLUTION_API_KEY

# Verificar se está sendo passada corretamente
docker exec triagem-evolution env | grep EVOLUTION_API_KEY
```

### Problema: Webhook não está recebendo eventos
```bash
# 1. Verificar se webhook está habilitado
docker logs triagem-evolution | grep -i webhook

# 2. Verificar se Django está respondendo
curl -v http://localhost:8000/api/webhooks/whatsapp/

# 3. Testar webhook manualmente
curl -X POST http://localhost:8000/api/webhooks/whatsapp/ \
  -H "Content-Type: application/json" \
  -d '{"test": "message"}'
```

---

## 📈 Monitoramento Contínuo

### Script de Monitoramento
```bash
# Monitorar em tempo real
watch -n 5 'docker ps | grep evolution'

# Ver uso de recursos
docker stats triagem-evolution

# Ver histórico de restarts
docker inspect triagem-evolution | grep -A 5 "RestartCount"
```

---

## ✨ Checklist Final

- [ ] Container está rodando (`docker ps` mostra triagem-evolution)
- [ ] Health check retorna 200 (`curl http://localhost:8080/health`)
- [ ] API Key válida (instâncias podem ser listadas)
- [ ] Banco de dados conectado
- [ ] Logs sem erros críticos
- [ ] Django backend respondendo
- [ ] Webhook configurado corretamente
- [ ] Espaço em disco suficiente

---

## 🎯 Próximos Passos

Se tudo está OK:
1. ✅ Criar instância WhatsApp
2. ✅ Gerar QR Code
3. ✅ Conectar via Mobile
4. ✅ Testar envio de mensagens
5. ✅ Verificar webhooks recebidos

Se há erros:
1. ❌ Verifique logs detalhados
2. ❌ Verifique conectividade de rede
3. ❌ Verifique permissões de volumes
4. ❌ Considere reiniciar stack: `docker compose restart`

---

## 📞 Suporte

Para mais informações:
- Documentação Official: https://github.com/EvolutionAPI/evolution-api
- Logs detalhados: `docker logs triagem-evolution -f --timestamps`
