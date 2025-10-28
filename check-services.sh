#!/bin/bash

# Script para verificar se todos os serviços do Triagem MVP estão funcionando
# Uso: ./check-services.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis
EVOLUTION_API_KEY="${EVOLUTION_API_KEY:-AE8099A0180B46AA9D1598A294D0BB2B}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-triagem_2025_secure_password}"

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Função para exibir resultado
check_result() {
    local test_name=$1
    local result=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Função para verificar container
check_container() {
    local container_name=$1
    docker ps --filter "name=$container_name" --filter "status=running" --format "{{.Names}}" | grep -q "$container_name"
}

# Função para verificar health
check_health() {
    local container_name=$1
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    [ "$health" = "healthy" ] || [ -z "$health" ]
}

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     VERIFICAÇÃO DE SERVIÇOS - TRIAGEM MVP                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# ========== VERIFICAÇÃO DE CONTAINERS ==========
echo -e "${CYAN}[1] VERIFICANDO CONTAINERS${NC}\n"

check_container "triagem-postgres" && result=0 || result=1
check_result "PostgreSQL Container" $result

check_container "triagem-django" && result=0 || result=1
check_result "Django Container" $result

check_container "triagem-nginx" && result=0 || result=1
check_result "Nginx Container" $result

check_container "triagem-n8n" && result=0 || result=1
check_result "N8N Container" $result

check_container "triagem-evolution" && result=0 || result=1
check_result "Evolution API Container" $result

check_container "triagem-redis" && result=0 || result=1
check_result "Redis Container" $result

check_container "triagem-backup" && result=0 || result=1
check_result "Backup Container" $result

echo ""

# ========== VERIFICAÇÃO DE HEALTH ==========
echo -e "${CYAN}[2] VERIFICANDO HEALTH DOS SERVIÇOS${NC}\n"

check_health "triagem-postgres" && result=0 || result=1
check_result "PostgreSQL Health" $result

check_health "triagem-backup" && result=0 || result=1
check_result "Backup Health" $result

echo ""

# ========== VERIFICAÇÃO DE CONECTIVIDADE ==========
echo -e "${CYAN}[3] VERIFICANDO CONECTIVIDADE${NC}\n"

# PostgreSQL
if docker exec triagem-postgres psql -U triagem_user -d triagem_db -c "SELECT 1;" &>/dev/null; then
    result=0
else
    result=1
fi
check_result "PostgreSQL Database Connection" $result

# Django Health
if curl -s http://localhost:8000/health | grep -q "ok"; then
    result=0
else
    result=1
fi
check_result "Django Health Endpoint" $result

# Django API
if curl -s http://localhost:8000/api/docs/ | grep -q "swagger"; then
    result=0
else
    result=1
fi
check_result "Django API Documentation" $result

# Nginx
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200"; then
    result=0
else
    result=1
fi
check_result "Nginx Frontend" $result

# N8N
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/ | grep -q "200"; then
    result=0
else
    result=1
fi
check_result "N8N Interface" $result

# Redis
if docker exec triagem-redis redis-cli ping | grep -q "PONG"; then
    result=0
else
    result=1
fi
check_result "Redis Connection" $result

# Evolution API
if curl -s -H "apikey: $EVOLUTION_API_KEY" http://localhost:8080/instance/fetchInstances | grep -q "id"; then
    result=0
else
    result=1
fi
check_result "Evolution API" $result

echo ""

# ========== VERIFICAÇÃO DE SCHEMAS DO BANCO ==========
echo -e "${CYAN}[4] VERIFICANDO SCHEMAS DO BANCO DE DADOS${NC}\n"

# Schema público (Django)
if docker exec triagem-postgres psql -U triagem_user -d triagem_db -c "\dt" | grep -q "triage_patient"; then
    result=0
else
    result=1
fi
check_result "Django Tables (Schema Public)" $result

# Schema evolution_api
if docker exec triagem-postgres psql -U triagem_user -d triagem_db -c "\dt evolution_api.*" | grep -q "Instance"; then
    result=0
else
    result=1
fi
check_result "Evolution Tables (Schema evolution_api)" $result

echo ""

# ========== VERIFICAÇÃO DE PORTAS ==========
echo -e "${CYAN}[5] VERIFICANDO PORTAS EXPOSTAS${NC}\n"

# Função para verificar porta
check_port() {
    local port=$1
    netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "
}

check_port 80 && result=0 || result=1
check_result "Porta 80 (HTTP)" $result

check_port 443 && result=0 || result=1
check_result "Porta 443 (HTTPS)" $result

check_port 5432 && result=0 || result=1
check_result "Porta 5432 (PostgreSQL)" $result

check_port 5678 && result=0 || result=1
check_result "Porta 5678 (N8N)" $result

check_port 6379 && result=0 || result=1
check_result "Porta 6379 (Redis)" $result

check_port 8000 && result=0 || result=1
check_result "Porta 8000 (Django)" $result

check_port 8080 && result=0 || result=1
check_result "Porta 8080 (Evolution)" $result

echo ""

# ========== VERIFICAÇÃO DE VOLUMES ==========
echo -e "${CYAN}[6] VERIFICANDO VOLUMES${NC}\n"

if docker volume ls | grep -q "triagem-mvp_postgres_data"; then
    result=0
else
    result=1
fi
check_result "Volume PostgreSQL" $result

if docker volume ls | grep -q "triagem-mvp_evolution_data"; then
    result=0
else
    result=1
fi
check_result "Volume Evolution" $result

if docker volume ls | grep -q "triagem-mvp_n8n_data"; then
    result=0
else
    result=1
fi
check_result "Volume N8N" $result

echo ""

# ========== RESUMO FINAL ==========
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      RESUMO DA VERIFICAÇÃO                     ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Total de Testes:     ${CYAN}$TOTAL_TESTS${NC}"
echo -e "${BLUE}║${NC} Testes Aprovados:    ${GREEN}$PASSED_TESTS${NC}"
echo -e "${BLUE}║${NC} Testes Falhados:     ${RED}$FAILED_TESTS${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ TODOS OS SERVIÇOS ESTÃO FUNCIONANDO CORRETAMENTE!${NC}\n"
    
    echo -e "${CYAN}Serviços disponíveis:${NC}"
    echo -e "  • Frontend: ${YELLOW}http://localhost/${NC}"
    echo -e "  • Django API: ${YELLOW}http://localhost:8000/api/docs/${NC}"
    echo -e "  • Django Admin: ${YELLOW}http://localhost:8000/admin/${NC}"
    echo -e "  • N8N: ${YELLOW}http://localhost:5678/${NC}"
    echo -e "  • Evolution API: ${YELLOW}http://localhost:8080/${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}⚠ ALGUNS SERVIÇOS APRESENTARAM PROBLEMAS!${NC}"
    echo -e "${YELLOW}Execute 'docker compose logs <service>' para mais detalhes.${NC}\n"
    exit 1
fi
