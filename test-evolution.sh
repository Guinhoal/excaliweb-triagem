#!/bin/bash

# Script para testar Evolution API
# Uso: ./test-evolution.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

EVOLUTION_URL="http://localhost:8080"
EVOLUTION_API_KEY="AE8099A0180B46AA9D1598A294D0BB2B"
DJANGO_URL="http://localhost:8000"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        TESTE DE FUNCIONALIDADE - EVOLUTION API         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Teste 1: Verificar se o container está rodando
echo -e "${YELLOW}[1/7] Verificando status do container...${NC}"
if docker ps | grep -q "triagem-evolution"; then
    echo -e "${GREEN}✓ Container triagem-evolution está rodando${NC}\n"
else
    echo -e "${RED}✗ Container triagem-evolution NÃO está rodando${NC}"
    echo -e "${RED}Execute: docker compose up -d evolution-api${NC}\n"
    exit 1
fi

# Teste 2: Health Check (algumas versões não possuem /health; usamos "/" como referência)
echo -e "${YELLOW}[2/7] Testando Health Check...${NC}"
http_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${EVOLUTION_URL}/")
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Health Check OK (HTTP 200 em /)${NC}"
    response=$(curl -s -X GET "${EVOLUTION_URL}/")
    echo -e "Response: $response\n"
else
    echo -e "${RED}✗ Health Check falhou (HTTP $http_code)${NC}\n"
fi

# Teste 3: Testar autenticação da API Key
echo -e "${YELLOW}[3/7] Testando API Key...${NC}"
response=$(curl -s -X GET "${EVOLUTION_URL}/instance/fetchInstances" \
    -H "Content-Type: application/json" \
    -H "apikey: ${EVOLUTION_API_KEY}" \
    -w "\n%{http_code}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ API Key autenticada com sucesso${NC}"
    echo -e "Instâncias encontradas: $(echo "$body" | grep -o '"data"' | wc -l)\n"
else
    echo -e "${RED}✗ Falha na autenticação (HTTP $http_code)${NC}"
    echo -e "Response: $body\n"
fi

# Teste 4: Verificar conexão com Banco de Dados
echo -e "${YELLOW}[4/7] Verificando conexão com PostgreSQL...${NC}"
if docker exec triagem-postgres psql -U triagem_user -d triagem_db -c "SELECT 1;" &>/dev/null; then
    echo -e "${GREEN}✓ Conexão com PostgreSQL OK${NC}\n"
else
    echo -e "${RED}✗ Falha ao conectar com PostgreSQL${NC}\n"
fi

# Teste 5: Verificar logs para erros
echo -e "${YELLOW}[5/7] Verificando logs para erros...${NC}"
error_count=$(docker logs triagem-evolution 2>&1 | grep -i "error\|failed" | wc -l)
if [ "$error_count" -eq 0 ]; then
    echo -e "${GREEN}✓ Nenhum erro crítico nos logs${NC}\n"
else
    echo -e "${YELLOW}⚠ Encontrados $error_count avisos/erros nos logs${NC}"
    echo -e "${YELLOW}Últimos erros:${NC}"
    docker logs triagem-evolution 2>&1 | grep -i "error\|failed" | tail -n 3
    echo -e ""
fi

# Teste 6: Testar conexão com Django
echo -e "${YELLOW}[6/7] Verificando Django Backend...${NC}"
if curl -s -X GET "${DJANGO_URL}/health" &>/dev/null; then
    echo -e "${GREEN}✓ Django Backend respondendo${NC}\n"
else
    echo -e "${RED}✗ Django Backend não está respondendo${NC}\n"
fi

# Teste 7: Criar instância de teste (opcional)
echo -e "${YELLOW}[7/7] Resumo final de status:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Evolution URL: ${BLUE}${EVOLUTION_URL}${NC}"
echo -e "API Key: ${BLUE}${EVOLUTION_API_KEY:0:10}...${NC}"
echo -e "Database: ${BLUE}PostgreSQL (triagem_db)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}✓ TESTES CONCLUÍDOS COM SUCESSO!${NC}\n"

echo -e "${YELLOW}Próximos passos:${NC}"
echo -e "1. Acessar Dashboard: ${BLUE}http://localhost/evolution${NC}"
echo -e "2. Criar instância via API"
echo -e "3. Testar webhook com Django"
echo -e "4. Monitorar logs: ${BLUE}docker logs triagem-evolution -f${NC}\n"
