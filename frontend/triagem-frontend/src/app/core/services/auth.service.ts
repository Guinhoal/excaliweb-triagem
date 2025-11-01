import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface LoginData {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
  role: 'patient' | 'doctor';
  cpf?: string;
  crm?: string; // obrigatório quando role = 'doctor'
  phone_number?: string;
}

export interface PatientDetailsPayload {
  age?: number;
  blood_type?: string;
  allergy?: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: number;
    name: string;
    email: string;
    role: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly TOKEN_KEY = 'auth_token';
  private readonly USER_KEY = 'user_data';
  private readonly API_URL = environment.apiBaseUrl;

  constructor(private http: HttpClient) { }

  login(credentials: LoginData): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/auth/login`, credentials)
      .pipe(
        tap(response => {
          localStorage.setItem(this.TOKEN_KEY, response.token);
          localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
        })
      );
  }

  register(userData: RegisterData): Observable<AuthResponse> {
    if (userData.password !== userData.confirmPassword) {
      throw new Error('Senhas não coincidem');
    }
    if (userData.password.length < 8) {
      throw new Error('A senha deve ter pelo menos 8 caracteres');
    }
    // Normalizar campos opcionais
    const stripNonDigits = (v?: string) => (v ? v.replace(/\D+/g, '') : undefined);
    const payload: any = {
      name: userData.name,
      email: userData.email,
      password: userData.password,
      role: userData.role || 'patient'
    };
    const cpfDigits = stripNonDigits(userData.cpf);
    const phoneDigits = stripNonDigits(userData.phone_number);
    if (cpfDigits) payload.cpf = cpfDigits; // backend aceita 11 dígitos; serializer max_length 15
    if (phoneDigits) payload.phone_number = phoneDigits;
    if (userData.role === 'doctor' && userData.crm) payload.crm = userData.crm.trim();

    return this.http.post<AuthResponse>(`${this.API_URL}/auth/register`, payload).pipe(
      tap(response => {
        localStorage.setItem(this.TOKEN_KEY, response.token);
        localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
      }),
      catchError((err) => {
        // Extrair mensagens detalhadas do backend (Django validators, campos específicos)
        const e = err?.error;
        let message = 'Erro ao fazer cadastro. Verifique os dados informados.';
        if (e) {
          // Campos comuns: password, email, cpf, crm, non_field_errors, detail
          if (typeof e === 'string') {
            message = e;
          } else if (Array.isArray(e)) {
            message = e.join(' ');
          } else if (e.password) {
            message = Array.isArray(e.password) ? e.password.join(' ') : String(e.password);
          } else if (e.email) {
            message = Array.isArray(e.email) ? e.email.join(' ') : String(e.email);
          } else if (e.cpf) {
            message = Array.isArray(e.cpf) ? e.cpf.join(' ') : String(e.cpf);
          } else if (e.crm) {
            message = Array.isArray(e.crm) ? e.crm.join(' ') : String(e.crm);
          } else if (e.non_field_errors) {
            message = Array.isArray(e.non_field_errors) ? e.non_field_errors.join(' ') : String(e.non_field_errors);
          } else if (e.detail) {
            message = String(e.detail);
          }
        }
        return throwError(() => new Error(message));
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.USER_KEY);
  }

  isLoggedIn(): boolean {
    return !!localStorage.getItem(this.TOKEN_KEY);
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  getCurrentUser(): any {
    const userData = localStorage.getItem(this.USER_KEY);
    return userData ? JSON.parse(userData) : null;
  }

  isDoctor(): boolean {
    const user = this.getCurrentUser();
    return user && user.role === 'doctor';
  }

  // Paciente: completar perfil (detalhes)
  savePatientDetails(details: PatientDetailsPayload): Observable<any> {
    const token = this.getToken();
    if (!token) {
      throw new Error('Usuário não autenticado');
    }
    // Authorization será anexado pelo interceptor. Aqui mantemos fallback se necessário.
    const headers = { 'Authorization': `Bearer ${token}` };

    // Normalizar payload: remover strings vazias e converter age invalid para null/omitir
    const payload: any = {};
    if (typeof details.age === 'number') {
      payload.age = details.age;
    } else if (details.age === undefined || details.age === null) {
      // não envia
    }
    if (typeof details.blood_type === 'string') {
      const bt = details.blood_type.trim();
      if (bt) payload.blood_type = bt;
    }
    if (typeof details.allergy === 'string') {
      const al = details.allergy.trim();
      if (al) payload.allergy = al;
    }

    return this.http.post(`${this.API_URL}/patients/me/details/`, payload, { headers }).pipe(
      catchError((err) => {
        if (err?.status === 401) {
          return throwError(() => new Error('Sessão expirada. Faça login novamente.'));
        }
        // Extrair mensagens de validação por campo, se houver
        const e = err?.error;
        let message = 'Falha ao salvar perfil.';
        if (e) {
          if (typeof e === 'string') message = e;
          else if (Array.isArray(e)) message = e.join(' ');
          else if (e.detail) message = String(e.detail);
          else {
            const msgs: string[] = [];
            for (const key of ['age', 'blood_type', 'allergy', 'non_field_errors']) {
              const val = (e as any)[key];
              if (val) msgs.push(Array.isArray(val) ? val.join(' ') : String(val));
            }
            if (msgs.length) message = msgs.join(' ');
          }
        }
        return throwError(() => new Error(message));
      })
    );
  }
}
