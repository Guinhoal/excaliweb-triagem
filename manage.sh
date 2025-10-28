#!/bin/bash

# Script de gerenciamento do sistema de triagem hospitalar

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

show_help() {
    echo "🏥 Sistema de Triagem Hospitalar - Gerenciamento"
    echo
    echo "Uso: ./manage.sh [COMANDO]"
    echo
    echo "Comandos disponíveis:"
    echo "  start          - Iniciar todos os serviços"
    echo "  stop           - Parar todos os serviços"
    echo "  restart        - Reiniciar todos os serviços"
    echo "  status         - Ver status dos containers"
    echo "  logs           - Ver logs dos serviços"
    echo "  backup         - Fazer backup manual do banco"
    echo "  restore        - Restaurar backup do banco"
    echo "  update         - Atualizar e reconstruir containers"
    echo "  shell-django   - Acessar shell do Django"
    echo "  shell-db       - Acessar shell do PostgreSQL"
    echo "  monitor        - Monitorar recursos em tempo real"
    echo "  cleanup        - Limpar containers e volumes não utilizados"
    echo "  ssl-setup      - Configurar SSL/TLS (Let's Encrypt)"
    echo "  firewall       - Configurar firewall básico"
    echo
}

start_services() {
    log "Iniciando serviços do sistema de triagem..."
    docker compose up -d
    log "✅ Todos os serviços foram iniciados!"
    show_urls
}

stop_services() {
    log "Parando todos os serviços..."
    docker compose down
    log "✅ Todos os serviços foram parados!"
}

restart_services() {
    log "Reiniciando serviços..."
    docker compose down
    docker compose up -d
    log "✅ Serviços reiniciados!"
}

show_status() {
    log "Status dos containers:"
    docker compose ps
    echo
    log "Uso de recursos:"
    docker stats --no-stream
}

show_logs() {
    if [ -z "$2" ]; then
        log "Mostrando logs de todos os serviços (últimas 100 linhas):"
        docker compose logs --tail=100 -f
    else
        log "Mostrando logs do serviço: $2"
        docker compose logs --tail=100 -f $2
    fi
}

backup_database() {
    log "Iniciando backup manual do banco de dados..."
    BACKUP_FILE="backups/manual_backup_$(date +%Y%m%d_%H%M%S).sql"
    docker exec triagem-postgres pg_dump -U triagem_user triagem_db > $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        log "✅ Backup criado: $BACKUP_FILE"
    else
        error "❌ Erro ao criar backup!"
        exit 1
    fi
}

restore_database() {
    if [ -z "$2" ]; then
        error "Especifique o arquivo de backup: ./manage.sh restore arquivo.sql"
        exit 1
    fi
    
    if [ ! -f "$2" ]; then
        error "Arquivo de backup não encontrado: $2"
        exit 1
    fi
    
    warn "⚠️  Esta operação irá substituir todos os dados atuais!"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Restaurando backup: $2"
        docker exec -i triagem-postgres psql -U triagem_user -d triagem_db < $2
        log "✅ Backup restaurado!"
    else
        log "Operação cancelada."
    fi
}

update_system() {
    log "Atualizando sistema..."
    docker compose down
    docker compose pull
    docker compose build --no-cache
    docker compose up -d
    log "✅ Sistema atualizado!"
}

django_shell() {
    log "Acessando shell do Django..."
    docker exec -it triagem-django python manage.py shell
}

database_shell() {
    log "Acessando shell do PostgreSQL..."
    docker exec -it triagem-postgres psql -U triagem_user -d triagem_db
}

monitor_resources() {
    log "Monitorando recursos (pressione Ctrl+C para sair)..."
    watch -n 2 'docker stats --no-stream'
}

cleanup_docker() {
    log "Limpando containers e imagens não utilizados..."
    docker system prune -f
    docker volume prune -f
    log "✅ Limpeza concluída!"
}

setup_ssl() {
    log "Configurando SSL com Let's Encrypt..."
    
    if ! command -v certbot &> /dev/null; then
        log "Instalando certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    read -p "Digite seu domínio (ex: triagem.exemplo.com): " DOMAIN
    read -p "Digite seu email: " EMAIL
    
    certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive
    
    log "✅ SSL configurado para $DOMAIN"
}

setup_firewall() {
    log "Configurando firewall básico..."
    
    # Instalar UFW se necessário
    apt-get update
    apt-get install -y ufw
    
    # Configurações básicas
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Permitir SSH
    ufw allow ssh
    
    # Permitir HTTP e HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Permitir portas específicas do projeto
    ufw allow 5678/tcp  # N8N
    ufw allow 8080/tcp  # Evolution API
    
    # Ativar firewall
    ufw --force enable
    
    log "✅ Firewall configurado!"
    ufw status verbose
}

show_urls() {
    echo
    log "🌐 URLs dos serviços:"
    echo "   Frontend (Angular): http://localhost"
    echo "   Backend API: http://localhost/api/"
    echo "   N8N: http://localhost:5678"
    echo "   Evolution API (porta direta): http://localhost:${EVOLUTION_PORT:-8080}"
    echo "   Evolution API (via Nginx): http://localhost${EVOLUTION_PATH:-/evolution}"
    echo "   Admin Django: http://localhost/api/admin/"
    echo
}

# Função principal
case "$1" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs $@
        ;;
    "backup")
        backup_database
        ;;
    "restore")
        restore_database $@
        ;;
    "update")
        update_system
        ;;
    "shell-django")
        django_shell
        ;;
    "shell-db")
        database_shell
        ;;
    "monitor")
        monitor_resources
        ;;
    "cleanup")
        cleanup_docker
        ;;
    "ssl-setup")
        setup_ssl
        ;;
    "firewall")
        setup_firewall
        ;;
    *)
        show_help
        ;;
esac
