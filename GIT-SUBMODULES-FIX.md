# Correção de Submódulos Git

## Problema Identificado

As pastas `backend/` e `frontend/triagem-frontend/` estavam sendo tratadas como **submódulos Git** ao invés de diretórios normais do projeto. Isso ocorreu porque essas pastas tinham seus próprios repositórios `.git` internos.

### Sintomas do Problema

1. No GitHub, as pastas apareciam como links vazios (ícone de pasta com seta)
2. Ao clonar o repositório, essas pastas estavam vazias
3. O comando `git ls-tree HEAD backend` mostrava tipo `160000` (indicador de submódulo)
4. Não era possível visualizar o código dessas pastas no GitHub

### Causa Raiz

Durante o desenvolvimento inicial, os comandos `git init` foram executados dentro das pastas `backend/` e `frontend/triagem-frontend/`, criando repositórios Git separados. Quando o projeto principal foi commitado, o Git automaticamente tratou essas pastas como submódulos.

## Solução Aplicada

### Passo 1: Remover os repositórios Git internos
```bash
rm -rf backend/.git
rm -rf frontend/triagem-frontend/.git
```

### Passo 2: Remover as pastas do índice Git (como submódulos)
```bash
git rm -r --cached backend frontend/triagem-frontend
```

### Passo 3: Adicionar novamente como diretórios normais
```bash
git add backend/ frontend/triagem-frontend/
```

### Passo 4: Commit e push
```bash
git commit -m "fix: Convertido backend e frontend de submódulos para pastas normais"
git push origin main
```

## Resultado

✅ Agora as pastas `backend/` e `frontend/triagem-frontend/` são tratadas como diretórios normais do repositório

✅ Todo o código está visível no GitHub

✅ Ao clonar o repositório, todas as pastas e arquivos estarão presentes

## Como Evitar Este Problema

### ❌ Não faça:
```bash
cd backend/
git init  # NUNCA faça isso dentro de um subdiretório do projeto
```

### ✅ Faça:
- Sempre inicialize o Git apenas na **raiz do projeto**
- Use `git status` regularmente para verificar o estado dos arquivos
- Se precisar de submódulos reais, use `git submodule add <url>` explicitamente

## Verificação

Para verificar se uma pasta é um submódulo:

```bash
# Se retornar "160000", é um submódulo
git ls-tree HEAD nome-da-pasta

# Verificar se existe .git dentro da pasta
ls -la nome-da-pasta/.git
```

## Referências

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Removing Git Submodules](https://stackoverflow.com/questions/1260748/how-do-i-remove-a-submodule)

---

**Data da correção:** 2025-11-01  
**Commit:** ab58a53
