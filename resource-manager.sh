#!/bin/bash

# Script para gerenciar recursos e economia do droplet

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

show_help() {
    echo "💰 Gerenciador de Recursos - DigitalOcean"
    echo
    echo "Uso: ./resource-manager.sh [COMANDO]"
    echo
    echo "Comandos:"
    echo "  dev-mode      - Modo desenvolvimento (todos serviços)"
    echo "  minimal       - Modo mínimo (só PostgreSQL)"
    echo "  sleep-mode    - Modo dormir (só dados essenciais)"
    echo "  wake-up       - Acordar tudo"
    echo "  status        - Ver consumo de recursos"
    echo "  backup-all    - Backup completo antes de parar"
    echo
}

dev_mode() {
    log "🔧 Iniciando modo desenvolvimento (todos os serviços)..."
    ./manage.sh start
}

minimal_mode() {
    log "⚡ Iniciando modo mínimo (só PostgreSQL + Redis)..."
    docker compose up -d postgres redis
    log "✅ Consumo mínimo: ~100MB RAM"
}

sleep_mode() {
    log "😴 Entrando em modo dormir..."
    ./manage.sh backup
    ./manage.sh stop
    log "✅ Todos os serviços parados. Dados preservados."
    log "💰 Economia máxima (só sistema operacional rodando)"
}

wake_up() {
    log "☀️ Acordando sistema..."
    ./manage.sh start
}

show_status() {
    log "📊 Status atual do sistema:"
    echo
    echo "=== CONTAINERS ==="
    docker compose ps 2>/dev/null || echo "Nenhum container rodando"
    echo
    echo "=== RECURSOS ==="
    free -h
    echo
    echo "=== DISCO ==="
    df -h /
    echo
    echo "=== CONSUMO DOCKER ==="
    docker stats --no-stream 2>/dev/null || echo "Nenhum container ativo"
}

backup_all() {
    log "💾 Fazendo backup completo..."
    ./manage.sh backup
    
    # Backup adicional dos volumes
    log "Fazendo backup dos volumes Docker..."
    sudo tar -czf "backups/volumes_backup_$(date +%Y%m%d_%H%M%S).tar.gz" \
        /var/lib/docker/volumes/triagem-mvp_postgres_data/ \
        /var/lib/docker/volumes/triagem-mvp_n8n_data/ 2>/dev/null || true
    
    log "✅ Backup completo finalizado!"
}

case "$1" in
    "dev-mode")
        dev_mode
        ;;
    "minimal")
        minimal_mode
        ;;
    "sleep-mode")
        sleep_mode
        ;;
    "wake-up")
        wake_up
        ;;
    "status")
        show_status
        ;;
    "backup-all")
        backup_all
        ;;
    *)
        show_help
        ;;
esac