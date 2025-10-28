#!/bin/bash
# Gerenciador simplificado do Frontend (Angular + Nginx)
# Usa docker-compose-frontend.yml

set -euo pipefail

COMPOSE_FILE="docker-compose-frontend.yml"
SERVICE_NAME="frontend"
CONTAINER_NAME="triagem-frontend"
IMAGE_NAME="triagem-frontend:stable"
HEALTH_URL="http://localhost:3000/health"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERR]${NC} $1"; }

need_compose() {
  if ! command -v docker &>/dev/null; then err "Docker não encontrado"; exit 1; fi
  if ! docker compose version &>/dev/null; then err "docker compose não disponível (use Docker >= 20.10)"; exit 1; fi
  if [ ! -f "$COMPOSE_FILE" ]; then err "Arquivo $COMPOSE_FILE não encontrado no diretório atual"; exit 1; fi
}

build() {
  need_compose
  info "Construindo imagem do frontend..."
  docker compose -f $COMPOSE_FILE build $SERVICE_NAME
  ok "Imagem construída: $IMAGE_NAME"
}

pull() {
  need_compose
  info "Pull de bases (se aplicável)..."
  docker compose -f $COMPOSE_FILE pull $SERVICE_NAME || true
  ok "Pull concluído"
}

start() {
  need_compose
  info "Subindo serviço frontend..."
  docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
  ok "Container iniciado"
  status_short
}

stop() {
  need_compose
  info "Parando serviço frontend..."
  docker compose -f $COMPOSE_FILE stop $SERVICE_NAME || true
  ok "Serviço parado"
}

rm_container() {
  need_compose
  info "Removendo container..."
  docker compose -f $COMPOSE_FILE rm -f $SERVICE_NAME || true
  ok "Container removido"
}

restart() {
  need_compose
  info "Reiniciando..."
  docker compose -f $COMPOSE_FILE restart $SERVICE_NAME
  ok "Reiniciado"
  status_short
}

rebuild() {
  need_compose
  stop || true
  rm_container || true
  build
  start
}

logs() {
  need_compose
  info "Logs (Ctrl+C para sair) ..."
  docker compose -f $COMPOSE_FILE logs -f --tail=200 $SERVICE_NAME
}

status() {
  need_compose
  info "Status detalhado:";
  docker compose -f $COMPOSE_FILE ps $SERVICE_NAME
  echo
  status_short
}

status_short() {
  if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    local health="$(curl -s -m 2 "$HEALTH_URL" || true)"
    if [ -n "$health" ]; then ok "Health endpoint responde: $health"; else warn "Health endpoint não respondeu (talvez build inicial)"; fi
    local port_map="$(docker ps --filter name=$CONTAINER_NAME --format '{{.Ports}}')"
    info "Acesso local: http://localhost:3000"; info "Mapeamento de portas: $port_map"
  else
    warn "Container não está rodando"
  fi
}

shell() {
  need_compose
  if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    info "Abrindo shell..."
    docker exec -it $CONTAINER_NAME sh
  else
    err "Container não está em execução"
    exit 1
  fi
}

image_clean() {
  need_compose
  warn "Removendo imagem $IMAGE_NAME (se não usada)..."
  docker rmi $IMAGE_NAME 2>/dev/null || true
  ok "Imagem removida (ou não existia)"
}

remove_all() {
  need_compose
  warn "Esta operação remove container e imagem. Continuar? (y/N)"; read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    stop || true
    rm_container || true
    image_clean || true
    ok "Frontend totalmente removido"
  else
    info "Operação cancelada"
  fi
}

health() {
  curl -i "$HEALTH_URL" || true
}

inspect() {
  need_compose
  info "Inspect container..."
  docker inspect $CONTAINER_NAME || true
}

usage() {
  cat <<EOF
🎨 Gerenciador Frontend
Uso: ./frontend-manage.sh <comando>
Comandos:
  build       Construir imagem
  pull        Pull da imagem base
  start       Subir container
  stop        Parar container
  restart     Reiniciar container
  rebuild     Reconstruir (build limpo + start)
  logs        Ver logs (follow)
  status      Status detalhado
  shell       Shell dentro do container
  remove      Remover container + imagem
  health      Testar endpoint de saúde
  inspect     docker inspect do container
  help        Mostrar esta ajuda

Arquivo compose: $COMPOSE_FILE
Endpoint: http://localhost:3000
EOF
}

cmd="${1:-help}"
shift || true
case "$cmd" in
  build) build ;;
  pull) pull ;;
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  rebuild) rebuild ;;
  logs) logs ;;
  status) status ;;
  shell) shell ;;
  remove) remove_all ;;
  health) health ;;
  inspect) inspect ;;
  help|--help|-h) usage ;;
  *) err "Comando desconhecido: $cmd"; echo; usage; exit 1 ;;
 esac
