import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../core/services/auth.service';

@Component({
    selector: 'app-startup-redirect',
    template: ''
})
export class StartupRedirectComponent implements OnInit {
    constructor(private auth: AuthService, private router: Router) { }
    ngOnInit(): void {
        if (this.auth.isLoggedIn()) {
            if (this.auth.isDoctor()) {
                this.router.navigate(['/dashboard']);
            } else {
                this.router.navigate(['/home']);
            }
        } else {
            this.router.navigate(['/home']);
        }
    }
}
