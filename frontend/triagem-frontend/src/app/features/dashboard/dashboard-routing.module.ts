import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './dashboard/dashboard.component';
import { DoctorGuard } from '../../core/guards/doctor.guard';

const routes: Routes = [
  {
    path: '',
    component: DashboardComponent,
    canActivate: [DoctorGuard]
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DashboardRoutingModule { }
