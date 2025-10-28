#!/bin/bash

# Script para testar Evolution API
set -e

API_KEY="${EVOLUTION_API_KEY:-AE8099A0180B46AA9D1598A294D0BB2B}"
API_URL="http://localhost:8080"
INSTANCE_NAME="${1:-test_whatsapp_instance}"

echo "🚀 Testando Evolution API..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Verificar health
echo ""
echo "1️⃣  Verificando saúde da API..."
if curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo "   ✅ API está respondendo"
else
    echo "   ⚠️  API ainda não está pronta (pode levar alguns segundos)"
fi

# 2. Criar instância
echo ""
echo "2️⃣  Criando instância: $INSTANCE_NAME"
RESPONSE=$(curl -s -X POST "$API_URL/instance/create" \
    -H "apikey: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"instanceName\":\"$INSTANCE_NAME\"}")

echo "   Resposta: $RESPONSE"

# 3. Listar instâncias
echo ""
echo "3️⃣  Listando instâncias..."
INSTANCES=$(curl -s -X GET "$API_URL/instance/fetchInstances" \
    -H "apikey: $API_KEY")

echo "   Instâncias encontradas:"
echo "$INSTANCES" | head -20

# 4. Conectar instância (gerar QR code)
echo ""
echo "4️⃣  Gerando QR code para: $INSTANCE_NAME"
QR_RESPONSE=$(curl -s -X GET "$API_URL/instance/connect/$INSTANCE_NAME" \
    -H "apikey: $API_KEY")

if echo "$QR_RESPONSE" | grep -q "base64" || echo "$QR_RESPONSE" | grep -q "qrcode"; then
    echo "   ✅ QR code gerado com sucesso!"
    echo "   Response: $(echo "$QR_RESPONSE" | head -100)"
else
    echo "   📋 Resposta: $QR_RESPONSE"
fi

# 5. Verificar status da instância
echo ""
echo "5️⃣  Verificando status da instância..."
STATUS=$(curl -s -X GET "$API_URL/instance/connectionState/$INSTANCE_NAME" \
    -H "apikey: $API_KEY")

echo "   Status: $STATUS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Testes concluídos!"
echo ""
echo "📝 Próximas ações:"
echo "   1. Escanear o QR code com seu WhatsApp Web"
echo "   2. Aguardar conexão (pode levar 10-30 segundos)"
echo "   3. Verificar status com: docker logs triagem-evolution-api"
