#!/bin/bash

# Script para gerenciar apenas o frontend Angular com configuração simples

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

CONTAINER_NAME="triagem-frontend-simple"
IMAGE_NAME="triagem-frontend:simple"
PORT="3000"

show_help() {
    echo "🎨 Frontend Angular - Gerenciamento Simples"
    echo
    echo "Uso: ./frontend-only.sh [COMANDO]"
    echo
    echo "Comandos disponíveis:"
    echo "  build          - Construir imagem do frontend"
    echo "  start          - Iniciar container do frontend"
    echo "  stop           - Parar container do frontend"
    echo "  restart        - Reiniciar container do frontend"
    echo "  rebuild        - Reconstruir e reiniciar frontend"
    echo "  logs           - Ver logs do frontend"
    echo "  status         - Ver status do container"
    echo "  remove         - Remover container e imagem"
    echo "  shell          - Acessar shell do container"
    echo
    echo "O frontend estará disponível em: http://localhost:$PORT"
    echo
}

build_frontend() {
    log "Construindo imagem do frontend..."
    cd frontend
    docker build -f Dockerfile-simple -t $IMAGE_NAME .
    if [ $? -eq 0 ]; then
        log "✅ Imagem construída com sucesso!"
    else
        error "❌ Erro ao construir imagem!"
        exit 1
    fi
    cd ..
}

start_frontend() {
    # Verificar se o container já existe
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
            warn "Container já está rodando!"
            return
        else
            log "Iniciando container existente..."
            docker start $CONTAINER_NAME
        fi
    else
        log "Criando e iniciando novo container..."
        docker run -d \
            --name $CONTAINER_NAME \
            -p $PORT:80 \
            --restart unless-stopped \
            $IMAGE_NAME
    fi
    
    if [ $? -eq 0 ]; then
        log "✅ Frontend iniciado com sucesso!"
        log "🌐 Acesse em: http://localhost:$PORT"
        log "🌐 Ou pelo IP da droplet: http://137.184.79.225:$PORT"
    else
        error "❌ Erro ao iniciar frontend!"
        exit 1
    fi
}

stop_frontend() {
    log "Parando container do frontend..."
    docker stop $CONTAINER_NAME
    if [ $? -eq 0 ]; then
        log "✅ Frontend parado com sucesso!"
    else
        warn "Container pode não estar rodando"
    fi
}

restart_frontend() {
    log "Reiniciando frontend..."
    stop_frontend
    sleep 2
    start_frontend
}

rebuild_frontend() {
    log "Reconstruindo frontend..."
    stop_frontend
    docker rm $CONTAINER_NAME 2>/dev/null
    build_frontend
    start_frontend
}

show_logs() {
    log "Mostrando logs do frontend (pressione Ctrl+C para sair):"
    docker logs -f $CONTAINER_NAME
}

show_status() {
    log "Status do container frontend:"
    docker ps -a --filter name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    echo
    
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        log "✅ Frontend está rodando!"
        log "🌐 URLs de acesso:"
        echo "   Local: http://localhost:$PORT"
        echo "   Droplet: http://137.184.79.225:$PORT"
    else
        warn "⚠️ Frontend não está rodando"
    fi
}

remove_frontend() {
    warn "⚠️ Esta operação irá remover o container e a imagem!"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removendo container e imagem..."
        docker stop $CONTAINER_NAME 2>/dev/null
        docker rm $CONTAINER_NAME 2>/dev/null
        docker rmi $IMAGE_NAME 2>/dev/null
        log "✅ Frontend removido!"
    else
        log "Operação cancelada."
    fi
}

shell_frontend() {
    log "Acessando shell do container frontend..."
    docker exec -it $CONTAINER_NAME sh
}

# Verificar se Docker está rodando
if ! docker info &> /dev/null; then
    error "❌ Docker não está rodando!"
    exit 1
fi

# Função principal
case "$1" in
    "build")
        build_frontend
        ;;
    "start")
        start_frontend
        ;;
    "stop")
        stop_frontend
        ;;
    "restart")
        restart_frontend
        ;;
    "rebuild")
        rebuild_frontend
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "remove")
        remove_frontend
        ;;
    "shell")
        shell_frontend
        ;;
    *)
        show_help
        ;;
esac