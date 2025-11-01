import { Injectable } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({ providedIn: 'root' })
export class DoctorGuard implements CanActivate {
    constructor(private auth: AuthService, private router: Router) { }
    canActivate(): boolean | UrlTree {
        if (this.auth.isLoggedIn() && this.auth.isDoctor()) return true;
        // se está logado mas não é médico, vai pro chatbot
        if (this.auth.isLoggedIn()) return this.router.parseUrl('/home');
        return this.router.parseUrl('/auth/login');
    }
}
