#!/bin/bash

echo "=== Opções para Visualizar Logs do Django ==="
echo ""
echo "1. Ver logs em tempo real (pressione Ctrl+C para sair):"
echo "   docker logs -f triagem-django"
echo ""
echo "2. Ver últimas 50 linhas:"
echo "   docker logs triagem-django --tail 50"
echo ""
echo "3. Ver últimas 100 linhas:"
echo "   docker logs triagem-django --tail 100"
echo ""
echo "4. Ver logs e filtrar por INFO/ERROR:"
echo "   docker logs triagem-django --tail 100 | grep -E '\\[INFO\\]|\\[ERROR\\]|\\[DEBUG\\]'"
echo ""
echo "5. Ver logs desde uma hora específica:"
echo "   docker logs triagem-django --since 1h"
echo ""
echo "6. Ver logs de registro de usuários:"
echo "   docker logs triagem-django | grep -i 'creating user\\|profile created'"
echo ""

# Mostrar os últimos logs
echo "=== Últimos 30 logs do Django ==="
docker logs triagem-django --tail 30
