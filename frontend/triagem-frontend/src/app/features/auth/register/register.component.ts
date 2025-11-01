import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, RegisterData } from '../../../core/services/auth.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent implements OnInit {

  registerData: RegisterData = {
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    role: 'patient',
    cpf: '',
    crm: '',
    phone_number: ''
  };

  isLoading: boolean = false;
  errorMessage: string = '';
  successMessage: string = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) { }

  ngOnInit(): void {
    // Verificar se já está logado
    if (this.authService.isLoggedIn()) {
      if (this.authService.isDoctor()) {
        this.router.navigate(['/dashboard']);
      } else {
        this.router.navigate(['/home']);
      }
    }
  }

  onRoleChange(): void {
    // Limpar CRM quando mudar para paciente
    if (this.registerData.role === 'patient') {
      this.registerData.crm = '';
    }
  }

  // Helpers de máscara
  private onlyDigits(value: string): string {
    return (value || '').replace(/\D+/g, '');
  }

  onCpfInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const digits = this.onlyDigits(input.value).slice(0, 11);
    // Formatar como 000.000.000-00
    let formatted = digits;
    if (digits.length > 3) formatted = digits.slice(0, 3) + '.' + digits.slice(3);
    if (digits.length > 6) formatted = formatted.slice(0, 7) + '.' + digits.slice(6);
    if (digits.length > 9) formatted = formatted.slice(0, 11) + '-' + digits.slice(9);
    this.registerData.cpf = formatted;
  }

  onPhoneInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const digits = this.onlyDigits(input.value).slice(0, 11); // formato brasileiro
    // Formatar como (31) 99999-9999 ou (31) 9999-9999
    let formatted = digits;
    if (digits.length > 0) formatted = '(' + digits.slice(0, 2);
    if (digits.length >= 2) formatted = '(' + digits.slice(0, 2) + ') ' + digits.slice(2);
    // decidir 4 ou 5 dígitos no prefixo
    if (digits.length > 6) {
      // 11 dígitos => 5+4
      const nine = digits.length > 10 ? 5 : 4;
      const start = digits.slice(2, 2 + nine);
      const end = digits.slice(2 + nine);
      formatted = '(' + digits.slice(0, 2) + ') ' + start + (end ? '-' + end : '');
    }
    this.registerData.phone_number = formatted;
  }

  onRegister(): void {
    // Validações básicas
    if (!this.registerData.name || !this.registerData.email || !this.registerData.password) {
      this.errorMessage = 'Por favor, preencha todos os campos obrigatórios.';
      return;
    }

    // Validação específica para médico
    if (this.registerData.role === 'doctor' && !this.registerData.crm) {
      this.errorMessage = 'CRM é obrigatório para médicos.';
      return;
    }

    if (this.registerData.password !== this.registerData.confirmPassword) {
      this.errorMessage = 'As senhas não coincidem.';
      return;
    }

    // Alinha com o validator padrão do Django (UserAttributeSimilarityValidator/MinimumLengthValidator)
    if (this.registerData.password.length < 8) {
      this.errorMessage = 'A senha deve ter pelo menos 8 caracteres.';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';

    try {
      this.authService.register(this.registerData).subscribe({
        next: (response) => {
          this.successMessage = `Cadastro realizado com sucesso como ${this.registerData.role === 'doctor' ? 'médico' : 'paciente'}!`;
          const role = response.user?.role;
          setTimeout(() => {
            if (role === 'doctor') {
              this.router.navigate(['/dashboard']);
            } else {
              // paciente vai para completar perfil
              this.router.navigate(['/auth/complete-profile']);
            }
          }, 1500);
        },
        error: (error) => {
          this.isLoading = false;
          this.errorMessage = error.message || 'Erro ao fazer cadastro. Tente novamente.';
        },
        complete: () => {
          this.isLoading = false;
        }
      });
    } catch (error: any) {
      this.isLoading = false;
      this.errorMessage = error.message || 'Erro ao fazer cadastro. Tente novamente.';
    }
  }
}
