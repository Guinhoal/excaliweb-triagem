import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { PrintComponent } from './print/print.component';

const routes: Routes = [
  {
    path: '',
    component: HomeComponent
  },
  {
    path: 'print',
    component: PrintComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class TotemRoutingModule { }
