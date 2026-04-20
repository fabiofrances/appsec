import { Module } from '@nestjs/common';
import { BmiModule } from './bmi/bmi.module.js';
import { HealthModule } from './health/health.module.js';

@Module({
  imports: [BmiModule, HealthModule],
})
export class AppModule {}
