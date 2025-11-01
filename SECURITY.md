# Segurança

## ⚠️ IMPORTANTE: Proteção de Credenciais

### Nunca commite arquivos sensíveis!

Este projeto utiliza variáveis de ambiente para armazenar credenciais sensíveis. **NUNCA** commite os seguintes arquivos:

- `.env` - Contém todas as credenciais do projeto
- Arquivos de backup do banco de dados
- Chaves SSH ou certificados SSL
- Tokens de API ou senhas

### Como configurar o ambiente

1. **Sempre use o `.env.example` como referência**
   ```bash
   cp .env.example .env
   ```

2. **Configure suas próprias credenciais no `.env`**
   - Gere chaves fortes e únicas
   - Nunca compartilhe o arquivo `.env`
   - Use diferentes credenciais em produção e desenvolvimento

### Arquivos já protegidos pelo .gitignore

O arquivo `.gitignore` já está configurado para ignorar:
- `.env` e variações
- Dados do banco de dados (`postgres-data/`, `redis/data/`)
- Backups (`/backups/`)
- Certificados SSL (`/nginx/ssl/*.key`, etc.)
- Cache e arquivos temporários

### Em caso de vazamento acidental

Se você acidentalmente commitou credenciais:

1. **NUNCA** use `git revert` - isso não remove do histórico
2. **Reescreva o histórico Git:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch ARQUIVO_SENSIVEL" \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push:**
   ```bash
   git push --force
   ```
4. **IMPORTANTE**: Revogue e regenere TODAS as credenciais que foram expostas
   - Groq API Key: https://console.groq.com
   - Evolution API Key: Regenere no painel
   - Senhas do banco de dados
   - Django SECRET_KEY

### Boas práticas

- ✅ Use `.env.example` como template
- ✅ Gere chaves únicas e longas
- ✅ Revise o `.gitignore` antes do primeiro commit
- ✅ Use ferramentas como `git-secrets` para detectar vazamentos
- ❌ Nunca commite `.env`
- ❌ Nunca compartilhe credenciais em chats ou emails
- ❌ Nunca use credenciais de produção em desenvolvimento

### Ferramentas úteis

- **git-secrets**: Previne commits com secrets
  ```bash
  git secrets --scan
  ```

- **gitleaks**: Detecta secrets no histórico
  ```bash
  gitleaks detect
  ```

## Reportar Vulnerabilidades

Se você encontrar uma vulnerabilidade de segurança, **NÃO** abra uma issue pública. Entre em contato diretamente com os mantenedores.
