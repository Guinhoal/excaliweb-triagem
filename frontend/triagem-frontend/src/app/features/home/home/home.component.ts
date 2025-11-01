import { Component, OnInit, ElementRef, ViewChild } from '@angular/core';
import { AuthService } from '../../../core/services/auth.service';
import { TriageService } from '../../../core/services/triage.service';

export interface ChatMessage {
  text: string;
  sender: 'user' | 'bot';
}

export interface PatientData {
  name?: string;
  age?: string;
  symptom?: string;
  duration?: string;
  otherSymptoms?: string;
}

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  @ViewChild('chatMessages') chatMessages!: ElementRef;
  @ViewChild('userInputElement') userInputElement!: ElementRef;

  messages: ChatMessage[] = [];
  userInput: string = '';
  isTyping: boolean = false;
  showAnalysisSection: boolean = false;
  isDoctorLoggedIn: boolean = false;
  doctorNotes: string = '';

  conversationStep: number = 0;
  patientData: PatientData = {};
  isCorrecting: boolean = false;

  constructor(public authService: AuthService, private triageService: TriageService) { }

  ngOnInit(): void {
    this.isDoctorLoggedIn = this.authService.isLoggedIn() && this.authService.isDoctor();
    // Não inicializa o chat automaticamente
    // this.initializeChat();
  }

  logout(): void {
    this.authService.logout();
    this.isDoctorLoggedIn = false;
    // Limpa o chat
    this.messages = [];
    this.userInput = '';
    this.showAnalysisSection = false;
    this.conversationStep = 0;
    this.patientData = {};
  }

  initializeChat(): void {
    // Chat será inicializado apenas quando o usuário enviar a primeira mensagem
  }

  sendMessage(): void {
    // Limpar espaços em branco do input
    const trimmedInput = this.userInput.trim();
    
    // Verificar se há texto
    if (!trimmedInput) {
      return;
    }

    // Verificar se o usuário está logado
    if (!this.authService.isLoggedIn()) {
      this.addBotMessage('⚠️ Por favor, faça login para utilizar o chat. <a href="/auth/login" style="color: #007bff; text-decoration: underline;">Clique aqui para fazer login</a>');
      this.userInput = '';
      return;
    }

    // Site em manutenção - redirecionar para WhatsApp
    this.addBotMessage('🔧 <strong>Site em Manutenção</strong><br><br>Nosso chat está temporariamente indisponível. Por favor, entre em contato conosco através do WhatsApp para continuar seu atendimento.<br><br>📱 <strong>WhatsApp:</strong> <a href="https://wa.me/5531999999999" target="_blank" style="color: #25D366; text-decoration: underline;">Clique aqui para conversar</a>');
    this.userInput = '';
    return;

    /* Código comentado para quando voltar do modo manutenção
    const message = this.userInput.trim();
    this.addUserMessage(message);
    this.userInput = '';

    this.isTyping = true;
    setTimeout(() => {
      this.processUserMessage(message);
      this.isTyping = false;
    }, 1000);
    */
  }

  addUserMessage(text: string): void {
    this.messages.push({ text, sender: 'user' });
    this.scrollToBottom();
  }

  addBotMessage(text: string): void {
    this.isTyping = true;
    setTimeout(() => {
      this.isTyping = false;
      this.messages.push({ text, sender: 'bot' });
      this.scrollToBottom();
    }, 1500);
  }

  processUserMessage(message: string): void {
    if (message.toLowerCase().includes('corrigir')) {
      this.isCorrecting = true;
      this.addBotMessage('O que você gostaria de corrigir? Digite o número:<br>1 - Sintoma principal<br>2 - Duração<br>3 - Outros sintomas');
      return;
    }

    if (this.isCorrecting) {
      this.handleCorrection(message);
      return;
    }

    switch (this.conversationStep) {
      case 0:
        this.handleMainSymptom(message);
        break;
      case 1:
        this.handleDuration(message);
        break;
      case 2:
        this.handleOtherSymptoms(message);
        break;
      default:
        this.addBotMessage('Obrigado! Sua triagem foi finalizada. Um médico analisará suas informações em breve.');
    }
  }

  handleMainSymptom(symptom: string): void {
    this.patientData.symptom = symptom;
    this.addBotMessage('Há quanto tempo você está sentindo isso? (exemplo: 2 dias, 1 semana, etc.)');
    this.conversationStep = 1;
  }

  handleDuration(duration: string): void {
    this.patientData.duration = duration;
    this.addBotMessage('Você tem algum outro sintoma? Se sim, descreva. Se não, digite "não":');
    this.conversationStep = 2;
  }

  handleOtherSymptoms(symptoms: string): void {
    this.patientData.otherSymptoms = symptoms.toLowerCase() === 'não' ? 'Nenhum' : symptoms;
    this.conversationStep = 3;

    // Obter dados do usuário logado
    const user = this.authService.getCurrentUser();
    this.patientData.name = user?.name || 'Não informado';

    this.addBotMessage('Perfeito! Coletei todas as informações necessárias. Vou exibir um resumo dos seus dados:');

    setTimeout(() => {
      this.showAnalysisSection = true;
      // Se logado, tenta enviar a pré-triagem ao backend
      const token = this.authService.getToken();
      const user = this.authService.getCurrentUser();
      if (token && user) {
        const text = `Sintoma: ${this.patientData.symptom}; Duração: ${this.patientData.duration}; Outros: ${this.patientData.otherSymptoms}`;
        this.triageService.createPreTriage({ channel: 'web', symptoms_text: text }, token)
          .subscribe({
            next: (res) => {
              this.addBotMessage(`
        <strong>Resumo da Triagem:</strong><br><br>
        <strong>Nome:</strong> ${this.patientData.name}<br>
        <strong>Sintoma Principal:</strong> ${this.patientData.symptom}<br>
        <strong>Duração:</strong> ${this.patientData.duration}<br>
        <strong>Outros Sintomas:</strong> ${this.patientData.otherSymptoms}<br><br>
        Sua triagem foi registrada! Código: ${res.triage_code} | Risco: ${res.risk_level} | Confiança IA: ${res.ai_confidence}%
        <br><br>
        <em>Caso deseje corrigir alguma informação, digite "corrigir".</em>
      `);
            },
            error: () => {
              this.addBotMessage(`Registro local concluído. Faça login para enviar sua triagem ao hospital.`);
            }
          });
      } else {
        this.addBotMessage(`
        <strong>Resumo da Triagem:</strong><br><br>
        <strong>Nome:</strong> ${this.patientData.name}<br>
        <strong>Sintoma Principal:</strong> ${this.patientData.symptom}<br>
        <strong>Duração:</strong> ${this.patientData.duration}<br>
        <strong>Outros Sintomas:</strong> ${this.patientData.otherSymptoms}<br><br>
        Você não está logado. Faça login para enviar sua triagem ao hospital.
        <br><br>
        <em>Caso deseje corrigir alguma informação, digite "corrigir".</em>
      `);
      }
    }, 2000);
  }

  handleCorrection(message: string): void {
    const option = parseInt(message);
    this.isCorrecting = false;

    switch (option) {
      case 1:
        this.addBotMessage('Digite o sintoma principal correto:');
        this.conversationStep = 0;
        break;
      case 2:
        this.addBotMessage('Digite a duração correta:');
        this.conversationStep = 1;
        break;
      case 3:
        this.addBotMessage('Digite os outros sintomas corretos:');
        this.conversationStep = 2;
        break;
      default:
        this.addBotMessage('Opção inválida. Digite um número de 1 a 3.');
        this.isCorrecting = true;
    }
  }

  sendAnalysis(): void {
    if (!this.doctorNotes.trim()) {
      alert('Por favor, digite uma análise antes de enviar.');
      return;
    }

    // Aqui seria feita a integração com a API do backend
    console.log('Enviando análise:', {
      patient: this.patientData,
      analysis: this.doctorNotes
    });

    alert('Análise enviada com sucesso!');
    this.doctorNotes = '';
  }

  scrollToBottom(): void {
    setTimeout(() => {
      if (this.chatMessages) {
        const element = this.chatMessages.nativeElement;
        element.scrollTop = element.scrollHeight;
      }
    }, 100);
  }
}
