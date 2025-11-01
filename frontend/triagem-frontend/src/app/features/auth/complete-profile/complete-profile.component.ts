import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, PatientDetailsPayload } from '../../../core/services/auth.service';

@Component({
    selector: 'app-complete-profile',
    templateUrl: './complete-profile.component.html',
    styleUrls: ['./complete-profile.component.scss']
})
export class CompleteProfileComponent {
    details: PatientDetailsPayload = {
        age: undefined,
        blood_type: '',
        allergy: ''
    };
    isLoading = false;
    errorMessage = '';
    successMessage = '';

    constructor(private authService: AuthService, private router: Router) { }

    save(): void {
        this.isLoading = true;
        this.errorMessage = '';
        this.successMessage = '';
        this.authService.savePatientDetails(this.details).subscribe({
            next: () => {
                this.successMessage = 'Perfil atualizado com sucesso!';
                setTimeout(() => this.router.navigate(['/home']), 700);
            },
            error: (err) => {
                this.errorMessage = err?.message || 'Falha ao salvar perfil.';
                this.isLoading = false;
            },
            complete: () => {
                this.isLoading = false;
            }
        });
    }
}
