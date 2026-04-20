import { Module } from '@nestjs/common';
import { BmiController } from './bmi.controller.js';
import { BmiService } from './bmi.service.js';

@Module({
  controllers: [BmiController],
  providers: [BmiService],
})
export class BmiModule {}
