import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface PreTriagePayload {
  patient?: number; // patient_id (opcional: será inferido pelo backend)
  channel?: 'web' | 'whatsapp' | 'totem';
  symptoms_text?: string;
}

@Injectable({ providedIn: 'root' })
export class TriageService {
  private readonly API_URL = environment.apiBaseUrl;

  constructor(private http: HttpClient) {}

  createPreTriage(payload: PreTriagePayload, token: string): Observable<any> {
    const headers = new HttpHeaders({ 'Authorization': `Bearer ${token}` });
    return this.http.post(`${this.API_URL}/pre-triage/`, payload, { headers });
  }
}
