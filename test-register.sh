#!/bin/bash

echo "=== Testando registro de PACIENTE ==="
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva Teste",
    "email": "joao.teste@example.com",
    "password": "senha123456",
    "role": "patient",
    "cpf": "12345678901",
    "phone_number": "31999887766"
  }' | jq .

echo ""
echo "=== Testando registro de MÉDICO ==="
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dra. Maria Santos",
    "email": "maria.dra@example.com",
    "password": "senha123456",
    "role": "doctor",
    "cpf": "98765432109",
    "crm": "CRM12345",
    "phone_number": "31988776655"
  }' | jq .

echo ""
echo "=== Verificando logs do Django ==="
