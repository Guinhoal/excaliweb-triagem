# Correções do Sistema de Autenticação

## Problemas Identificados e Resolvidos

### 1. ✅ Problema: Login não funcionava com senha
**Causa:** Não havia um backend de autenticação configurado para aceitar email como username.

**Solução:** 
- Criado arquivo `backend/triage/backends.py` com `EmailBackend` customizado
- Adicionado `AUTHENTICATION_BACKENDS` no `settings.py` para usar o novo backend
- O backend permite login tanto por email quanto por username

**Arquivos Modificados:**
- ✅ `backend/triage/backends.py` (novo)
- ✅ `backend/triagem_excaliweb/settings.py`

### 2. ✅ Problema: Completar perfil retornava erro
**Causa:** O serializer `PatientDetailsSerializer` exigia o campo `patient` no payload, mas esse campo deve ser inferido automaticamente do usuário autenticado.

**Solução:**
- Adicionado `extra_kwargs` no `PatientDetailsSerializer` para marcar `patient` como não obrigatório
- O campo `patient` já estava em `read_only_fields`, mas adicionamos segurança extra

**Arquivos Modificados:**
- ✅ `backend/triage/serializers.py`

## Funcionalidades Testadas e Validadas

### ✅ Registro de Usuário
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Novo Paciente",
    "email": "paciente@teste.com",
    "password": "SenhaForte123!",
    "role": "patient",
    "cpf": "12345678901",
    "phone_number": "31999999999"
  }'
```
**Resultado:** ✅ Usuário criado com sucesso, senha hasheada corretamente

### ✅ Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"paciente@teste.com","password":"SenhaForte123!"}'
```
**Resultado:** ✅ Login bem-sucedido, tokens JWT retornados

### ✅ Completar Perfil do Paciente
```bash
curl -X POST http://localhost:8000/api/patients/me/details/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "age": 35,
    "blood_type": "A+",
    "allergy": "Penicilina"
  }'
```
**Resultado:** ✅ Perfil completado com sucesso

## Como Resetar Senha de Usuário Existente (Se Necessário)

Para usuários criados antes das correções, execute:

```bash
docker exec triagem-django python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.filter(email='EMAIL_DO_USUARIO').first()
if user:
    user.set_password('NOVA_SENHA')
    user.save()
    print('Senha resetada com sucesso')
"
```

## Fluxo Completo de Autenticação

1. **Registro:**
   - Frontend: `POST /api/auth/register`
   - Backend cria usuário com `create_user()` (senha hasheada automaticamente)
   - Retorna token JWT e dados do usuário

2. **Login:**
   - Frontend: `POST /api/auth/login`
   - Backend usa `EmailBackend` para autenticar por email
   - Retorna token JWT e dados do usuário

3. **Completar Perfil (Paciente):**
   - Frontend: `POST /api/patients/me/details/`
   - Backend identifica paciente pelo token JWT
   - Cria ou atualiza `PatientDetails` associado ao paciente

## Segurança

- ✅ Senhas são hasheadas usando `pbkdf2_sha256` (padrão Django)
- ✅ Tokens JWT com expiração de 4 horas (access) e 7 dias (refresh)
- ✅ Autenticação obrigatória para endpoints sensíveis
- ✅ CORS configurado para ambiente de desenvolvimento

## Data da Correção
31 de Outubro de 2025
