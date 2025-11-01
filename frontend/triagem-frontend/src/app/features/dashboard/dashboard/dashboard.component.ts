import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

export interface Patient {
  id: number;
  name: string;
  age: number;
  symptom: string;
  duration: string;
  otherSymptoms: string;
  urgency: 'red' | 'orange' | 'yellow' | 'green';
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  doctorName: string = '';

  patients: Patient[] = [
    {
      id: 1,
      name: 'João Silva',
      age: 45,
      symptom: 'Dor no peito e falta de ar',
      duration: '3 horas',
      otherSymptoms: 'Tontura',
      urgency: 'red'
    },
    {
      id: 2,
      name: 'Maria Oliveira',
      age: 32,
      symptom: 'Febre alta e dor de garganta',
      duration: '2 dias',
      otherSymptoms: 'Dor no corpo',
      urgency: 'yellow'
    },
    {
      id: 3,
      name: 'Carlos Pereira',
      age: 68,
      symptom: 'Tosse persistente',
      duration: '3 semanas',
      otherSymptoms: 'Perda de peso',
      urgency: 'orange'
    },
    {
      id: 4,
      name: 'Ana Costa',
      age: 25,
      symptom: 'Dor de cabeça leve',
      duration: '1 dia',
      otherSymptoms: 'Nenhum',
      urgency: 'green'
    },
    {
      id: 5,
      name: 'Roberto Santos',
      age: 55,
      symptom: 'Dor abdominal intensa',
      duration: '6 horas',
      otherSymptoms: 'Náuseas e vômitos',
      urgency: 'orange'
    }
  ];

  // Propriedades para controle de visualização
  viewMode: 'grid' | 'list' | 'carousel' = 'grid';
  sortBy: 'urgency' | 'name' | 'age' | 'duration' = 'urgency';
  sortDirection: 'asc' | 'desc' = 'desc';
  sortedPatients: Patient[] = [];

  // Propriedades para carrossel
  currentSlide: number = 0;

  selectedPatient: Patient | null = null;
  showModal: boolean = false;
  doctorNotes: string = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) { }

  ngOnInit(): void {
    // Verificar se está logado e é médico
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/auth/login']);
      return;
    }

    if (!this.authService.isDoctor()) {
      this.router.navigate(['/home']);
      return;
    }

    // Obter dados do médico
    const currentUser = this.authService.getCurrentUser();
    this.doctorName = currentUser?.name || 'Médico';

    // Inicializar pacientes ordenados
    this.sortPatients();
  }

  getPatientsByUrgency(urgency: string): Patient[] {
    return this.patients.filter(patient => patient.urgency === urgency);
  }

  getUrgencyLabel(urgency: string): string {
    const labels: { [key: string]: string } = {
      'red': 'Emergência',
      'orange': 'Muita Urgência',
      'yellow': 'Urgência',
      'green': 'Pouca Urgência'
    };
    return labels[urgency] || 'Desconhecido';
  }

  openPatientModal(patient: Patient): void {
    this.selectedPatient = patient;
    this.showModal = true;
    this.doctorNotes = '';
  }

  closeModal(): void {
    this.showModal = false;
    this.selectedPatient = null;
    this.doctorNotes = '';
  }

  sendAnalysis(): void {
    if (!this.doctorNotes.trim() || !this.selectedPatient) {
      alert('Por favor, digite uma análise antes de enviar.');
      return;
    }

    // Aqui seria feita a integração com a API do backend
    console.log('Enviando análise:', {
      patient: this.selectedPatient,
      analysis: this.doctorNotes
    });

    alert(`Análise enviada para ${this.selectedPatient.name}!`);
    this.closeModal();
  }

  markAsCompleted(): void {
    if (!this.selectedPatient) return;

    // Remover paciente da lista (simula atendimento concluído)
    this.patients = this.patients.filter(p => p.id !== this.selectedPatient!.id);

    // Atualizar lista ordenada
    this.sortPatients();

    // Ajustar slide do carrossel se necessário
    if (this.currentSlide >= this.sortedPatients.length && this.sortedPatients.length > 0) {
      this.currentSlide = this.sortedPatients.length - 1;
    }

    alert(`${this.selectedPatient.name} foi marcado como atendido!`);
    this.closeModal();
  }

  // Métodos de controle de visualização
  setViewMode(mode: 'grid' | 'list' | 'carousel'): void {
    this.viewMode = mode;
    this.currentSlide = 0; // Reset carousel position
  }

  // Métodos de ordenação
  sortPatients(): void {
    this.sortedPatients = [...this.patients].sort((a, b) => {
      let comparison = 0;

      switch (this.sortBy) {
        case 'urgency':
          const urgencyOrder = { 'red': 4, 'orange': 3, 'yellow': 2, 'green': 1 };
          comparison = urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
          break;
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        case 'age':
          comparison = a.age - b.age;
          break;
        case 'duration':
          // Simplified duration comparison (assumes consistent format)
          const getDurationValue = (duration: string): number => {
            if (duration.includes('semana')) return parseInt(duration) * 7 * 24;
            if (duration.includes('dia')) return parseInt(duration) * 24;
            if (duration.includes('hora')) return parseInt(duration);
            return 0;
          };
          comparison = getDurationValue(a.duration) - getDurationValue(b.duration);
          break;
      }

      return this.sortDirection === 'asc' ? comparison : -comparison;
    });
  }

  toggleSortDirection(): void {
    this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    this.sortPatients();
  }

  // Métodos do carrossel
  nextSlide(): void {
    if (this.currentSlide < this.sortedPatients.length - 1) {
      this.currentSlide++;
    }
  }

  previousSlide(): void {
    if (this.currentSlide > 0) {
      this.currentSlide--;
    }
  }

  goToSlide(index: number): void {
    this.currentSlide = index;
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/home']);
  }
}
