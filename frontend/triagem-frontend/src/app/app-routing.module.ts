import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { StartupRedirectComponent } from './startup/startup-redirect.component';

const routes: Routes = [
  // rota vazia decide com base em storage (pelo resolver simples abaixo)
  {
    path: '',
    component: StartupRedirectComponent
  },
  {
    path: 'home',
    loadChildren: () => import('./features/home/home.module').then(m => m.HomeModule)
  },
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.module').then(m => m.AuthModule)
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./features/dashboard/dashboard.module').then(m => m.DashboardModule)
  },
  {
    path: 'totem',
    loadChildren: () => import('./features/totem/totem.module').then(m => m.TotemModule)
  },
  {
    path: '**',
    redirectTo: '/home'
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
