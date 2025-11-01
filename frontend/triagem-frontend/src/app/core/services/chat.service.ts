import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface ChatMessage {
  id?: number;
  sender: 'user' | 'ai' | 'doctor';
  text: string;
  timestamp: Date;
  isTyping?: boolean;
}

export interface TriageResponse {
  triage_id: number;
  triage_code: string;
  risk_level: string;
  confidence: number;
  next_action: 'direct' | 'review' | 'immediate';
  recommendation: string;
  status: string;
  message_id: number;
  redirect_to_doctor: boolean;
}

@Injectable({ providedIn: 'root' })
export class ChatService {
  private readonly API_URL = environment.apiBaseUrl;
  private messagesSubject = new BehaviorSubject<ChatMessage[]>([]);
  private currentTriageSubject = new BehaviorSubject<TriageResponse | null>(null);
  
  public messages$ = this.messagesSubject.asObservable();
  public currentTriage$ = this.currentTriageSubject.asObservable();

  constructor(private http: HttpClient) {
    this.initializeChat();
  }

  private initializeChat(): void {
    const welcomeMessage: ChatMessage = {
      sender: 'ai',
      text: `
        <div>
          <p><strong>Olá! 👋 Sou seu assistente de triagem virtual.</strong></p>
          <p>Estou aqui para te ajudar a avaliar seus sintomas e orientar sobre o melhor atendimento.</p>
          <p><strong>Como posso ajudá-lo hoje?</strong></p>
          <small><em>Descreva seus sintomas ou o que está sentindo...</em></small>
        </div>
      `,
      timestamp: new Date()
    };
    this.messagesSubject.next([welcomeMessage]);
  }

  sendMessage(message: string): Observable<TriageResponse> {
    // Adicionar mensagem do usuário
    const userMessage: ChatMessage = {
      sender: 'user',
      text: message,
      timestamp: new Date()
    };

    const currentMessages = this.messagesSubject.value;
    this.messagesSubject.next([...currentMessages, userMessage]);

    // Mostrar indicador de digitação
    this.showTypingIndicator();

    // Enviar para API
    return this.http.post<TriageResponse>(`${this.API_URL}/pre-triage/chat/`, {
      message: message
    });
  }

  handleAIResponse(response: TriageResponse): void {
    this.hideTypingIndicator();
    
    // Adicionar resposta da IA
    const aiMessage: ChatMessage = {
      id: response.message_id,
      sender: 'ai',
      text: this.formatAIResponse(response),
      timestamp: new Date()
    };

    const currentMessages = this.messagesSubject.value;
    this.messagesSubject.next([...currentMessages, aiMessage]);
    
    // Atualizar triagem atual
    this.currentTriageSubject.next(response);
  }

  private formatAIResponse(response: TriageResponse): string {
    const riskColors: { [key: string]: string } = {
      'Baixo': '#28a745',
      'Medio': '#fd7e14', 
      'Alto': '#dc3545',
      'Urgente': '#6f42c1',
      'Verde': '#28a745',
      'Amarelo': '#ffc107',
      'Laranja': '#fd7e14',
      'Vermelho': '#dc3545'
    };
    
    const riskEmojis: { [key: string]: string } = {
      'Baixo': '🟢',
      'Medio': '🟡', 
      'Alto': '🟠',
      'Urgente': '🔴',
      'Verde': '🟢',
      'Amarelo': '🟡',
      'Laranja': '🟠',
      'Vermelho': '🔴'
    };    let actionText = '';
    if (response.next_action === 'direct') {
      actionText = `
        <div style="background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; padding: 12px; margin: 8px 0;">
          <p><strong>✅ Código de Triagem Gerado:</strong></p>
          <p style="font-size: 18px; font-weight: bold; color: #155724;">${response.triage_code}</p>
          <p><small>Apresente este código na recepção do hospital.</small></p>
        </div>
      `;
    } else if (response.next_action === 'review') {
      actionText = `
        <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 12px; margin: 8px 0;">
          <p><strong>⚠️ Encaminhando para revisão médica...</strong></p>
          <p><small>Um médico irá analisar seu caso em breve.</small></p>
        </div>
      `;
    } else {
      actionText = `
        <div style="background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 8px; padding: 12px; margin: 8px 0;">
          <p><strong>🚨 Procure atendimento médico IMEDIATAMENTE</strong></p>
          <p><small>Dirija-se ao pronto socorro mais próximo.</small></p>
        </div>
      `;
    }

    return `
      <div>
        <div style="border-left: 4px solid ${riskColors[response.risk_level] || '#28a745'}; padding-left: 12px; margin: 8px 0;">
          <p><strong>Classificação de Risco:</strong> ${riskEmojis[response.risk_level] || '🟢'} ${response.risk_level}</p>
          <p><strong>Confiabilidade da Análise:</strong> ${response.confidence.toFixed(1)}%</p>
        </div>
        
        <p><strong>Recomendação:</strong></p>
        <p>${response.recommendation}</p>
        
        ${actionText}
        
        <p><small><em>Esta análise é baseada nas informações fornecidas e não substitui avaliação médica presencial.</em></small></p>
      </div>
    `;
  }

  private showTypingIndicator(): void {
    const typingMessage: ChatMessage = {
      sender: 'ai',
      text: '',
      timestamp: new Date(),
      isTyping: true
    };

    const currentMessages = this.messagesSubject.value;
    this.messagesSubject.next([...currentMessages, typingMessage]);
  }

  private hideTypingIndicator(): void {
    const currentMessages = this.messagesSubject.value;
    const filteredMessages = currentMessages.filter(msg => !msg.isTyping);
    this.messagesSubject.next(filteredMessages);
  }

  clearChat(): void {
    this.messagesSubject.next([]);
    this.currentTriageSubject.next(null);
    this.initializeChat();
  }

  getCurrentTriage(): TriageResponse | null {
    return this.currentTriageSubject.value;
  }
}