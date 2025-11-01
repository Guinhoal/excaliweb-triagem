import os
import json
from groq import Groq
from typing import Dict, Tuple
from django.conf import settings

class TriageAIService:
    def __init__(self):
        self.client = Groq(api_key=os.getenv('GROQ_API_KEY'))
        
    def analyze_symptoms(self, symptoms_text: str, patient_details: Dict = None) -> Dict:
        """
        Analisa sintomas usando IA e retorna classificação de risco e confiabilidade
        
        Returns:
        {
            'risk_level': str,  # Verde, Amarelo, Laranja, Vermelho
            'confidence': float,  # 0-100
            'triage_code': str,
            'recommendation': str,
            'next_action': str  # 'direct', 'review', 'immediate'
        }
        """
        try:
            # Construir contexto do paciente
            patient_context = ""
            if patient_details:
                age = patient_details.get('age', 'não informada')
                blood_type = patient_details.get('blood_type', 'não informado')
                allergies = patient_details.get('allergy', 'nenhuma conhecida')
                patient_context = f"Idade: {age}, Tipo sanguíneo: {blood_type}, Alergias: {allergies}"
            
            # Prompt para análise de triagem
            prompt = f"""
Você é um sistema de inteligência artificial especializado em triagem hospitalar baseado no Protocolo de Manchester.

DADOS DO PACIENTE:
{patient_context}

SINTOMAS RELATADOS:
{symptoms_text}

INSTRUÇÕES:
1. Analise os sintomas usando os critérios do Protocolo de Manchester
2. Classifique o risco em: Verde (baixo), Amarelo (moderado), Laranja (alto), Vermelho (crítico)
3. Determine a confiabilidade da sua análise (0-100)
4. Recomende a próxima ação baseada na combinação risco x confiabilidade

CRITÉRIOS DE DECISÃO:
- Confiabilidade > 85% e Risco Verde/Amarelo: LIBERAÇÃO DIRETA
- Confiabilidade 60-85% OU Risco Laranja: REVISÃO MÉDICA
- Confiabilidade < 60% OU Risco Vermelho: ATENDIMENTO IMEDIATO

Responda APENAS em formato JSON válido:
{{
    "risk_level": "Verde|Amarelo|Laranja|Vermelho",
    "confidence": 0-100,
    "reasoning": "explicação detalhada da análise",
    "recommendation": "recomendação clara para o paciente",
    "next_action": "direct|review|immediate",
    "symptoms_summary": "resumo estruturado dos sintomas",
    "priority_score": 0-100
}}
"""

            response = self.client.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama3-8b-8192",
                temperature=0.1,
                max_tokens=1000
            )
            
            # Parse da resposta
            ai_response = response.choices[0].message.content
            
            try:
                result = json.loads(ai_response)
            except json.JSONDecodeError:
                # Fallback em caso de erro no JSON
                result = {
                    "risk_level": "Amarelo",
                    "confidence": 50,
                    "reasoning": "Erro na análise automática",
                    "recommendation": "Procure avaliação médica presencial",
                    "next_action": "review",
                    "symptoms_summary": symptoms_text[:200],
                    "priority_score": 50
                }
            
            # Gerar código de triagem
            result['triage_code'] = self._generate_triage_code(
                result['risk_level'], 
                result['confidence']
            )
            
            return result
            
        except Exception as e:
            # Fallback para erro na API
            return {
                "risk_level": "Amarelo",
                "confidence": 0,
                "reasoning": f"Erro no sistema de IA: {str(e)}",
                "recommendation": "Sistema temporariamente indisponível. Procure triagem presencial.",
                "next_action": "immediate",
                "symptoms_summary": symptoms_text[:200],
                "priority_score": 75,
                "triage_code": "TRI-ERROR-001"
            }
    
    def _generate_triage_code(self, risk_level: str, confidence: float) -> str:
        """Gera código único de triagem baseado no risco e confiabilidade"""
        import random
        import string
        
        risk_prefixes = {
            'Verde': 'V',
            'Amarelo': 'A', 
            'Laranja': 'L',
            'Vermelho': 'R'
        }
        
        confidence_suffix = 'H' if confidence > 80 else 'M' if confidence > 60 else 'L'
        random_part = ''.join(random.choices(string.digits, k=4))
        
        prefix = risk_prefixes.get(risk_level, 'X')
        
        return f"TRI-{prefix}{confidence_suffix}-{random_part}"