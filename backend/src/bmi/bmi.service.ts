import { Injectable } from '@nestjs/common';
import { Counter, Histogram } from 'prom-client';
import { CalculateBmiDto } from './dto/calculate-bmi.dto.js';
import { BmiResultDto } from './dto/bmi-result.dto.js';

@Injectable()
export class BmiService {
  private readonly calculationCounter: Counter;
  private readonly bmiHistogram: Histogram;

  constructor() {
    this.calculationCounter = new Counter({
      name: 'bmi_calculations_total',
      help: 'Total number of BMI calculations',
      labelNames: ['classification'],
    });

    this.bmiHistogram = new Histogram({
      name: 'bmi_value_distribution',
      help: 'Distribution of BMI values',
      buckets: [16, 18.5, 25, 30, 35, 40],
    });
  }

  calculate(dto: CalculateBmiDto): BmiResultDto {
    const bmi = parseFloat((dto.weight / (dto.height * dto.height)).toFixed(2));
    const classification = this.classify(bmi);

    this.calculationCounter.inc({ classification });
    this.bmiHistogram.observe(bmi);

    return { bmi, classification, weight: dto.weight, height: dto.height };
  }

  private classify(bmi: number): string {
    if (bmi < 16) return 'Magreza grave';
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    if (bmi < 35) return 'Obesidade grau I';
    if (bmi < 40) return 'Obesidade grau II';
    return 'Obesidade grau III';
  }
}
