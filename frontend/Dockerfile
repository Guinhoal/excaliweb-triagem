# Estágio 1: Build do Angular
FROM node:18-alpine AS build

WORKDIR /app

# Copiar o projeto Angular
COPY triagem-frontend/package*.json ./

# Instalar dependências
RUN npm ci

# Copiar código fonte do Angular
COPY triagem-frontend/ .

# Build da aplicação
RUN npm run build

# Estágio 2: Servir com Nginx
FROM nginx:alpine

# Remover configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copiar build do Angular
COPY --from=build /app/dist/triagem-frontend /usr/share/nginx/html

# Copiar configuração customizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/

# Criar diretório para logs
RUN mkdir -p /var/log/nginx

# Expor porta
EXPOSE 80

# Comando para iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
