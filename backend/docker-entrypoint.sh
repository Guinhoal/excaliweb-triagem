#!/bin/bash
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[Django]${NC} $1"; }
warn() { echo -e "${YELLOW}[Django]${NC} $1"; }
error() { echo -e "${RED}[Django]${NC} $1"; }

log "Iniciando aplicação Django..."

# Esperar o banco de dados estar disponível
log "Aguardando conexão com o banco de dados..."
while ! nc -z postgres 5432; do
  sleep 1
done
log "✅ Banco de dados disponível!"

# Executar migrações
log "Executando migrações do banco de dados..."
python manage.py makemigrations triage --noinput || true
python manage.py migrate --noinput

# Coletar arquivos estáticos
log "Coletando arquivos estáticos..."
python manage.py collectstatic --noinput --clear || true

# Criar superusuário se não existir
log "Verificando superusuário..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@triagem.com', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
EOF

# Carregar dados iniciais se existir
if [ -f "fixtures/initial_data.json" ]; then
    log "Carregando dados iniciais..."
    python manage.py loaddata fixtures/initial_data.json
fi

log "✅ Inicialização concluída!"

# Executar comando passado como parâmetro
exec "$@"
