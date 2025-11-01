import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { TotemRoutingModule } from './totem-routing.module';
import { HomeComponent } from './home/home.component';
import { PrintComponent } from './print/print.component';


@NgModule({
  declarations: [
    HomeComponent,
    PrintComponent
  ],
  imports: [
    CommonModule,
    RouterModule,
    TotemRoutingModule
  ]
})
export class TotemModule { }
