import { Injectable } from '@angular/core';
import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  private readonly TOKEN_KEY = 'auth_token';

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = localStorage.getItem(this.TOKEN_KEY);
    const isApiCall = this.isApiUrl(req.url);

    let authReq = req;
    if (token && isApiCall && !req.headers.has('Authorization')) {
      authReq = req.clone({
        setHeaders: { Authorization: `Bearer ${token}` }
      });
    }

    return next.handle(authReq).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401 && isApiCall) {
          // Mensagem padrão para sessão expirada
          const err = new Error('Sessão expirada. Faça login novamente.');
          return throwError(() => err);
        }
        return throwError(() => error);
      })
    );
  }

  private isApiUrl(url: string): boolean {
    // Em prod, apiBaseUrl é '/api'; em dev é 'http://localhost:8000/api'
    const base = environment.apiBaseUrl;
    if (base.startsWith('http')) {
      return url.startsWith(base);
    }
    // relativo ao host atual
    return url.startsWith(base) || url.startsWith(window.location.origin + base);
  }
}
