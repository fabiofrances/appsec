import { Test, TestingModule } from '@nestjs/testing';
import { BmiService } from './bmi.service.js';

jest.mock('prom-client', () => ({
  Counter: jest.fn().mockImplementation(() => ({ inc: jest.fn() })),
  Histogram: jest.fn().mockImplementation(() => ({ observe: jest.fn() })),
}));

describe('BmiService', () => {
  let service: BmiService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [BmiService],
    }).compile();

    service = module.get<BmiService>(BmiService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculate', () => {
    it('should return correct BMI value', () => {
      const result = service.calculate({ weight: 70, height: 1.75 });
      expect(result.bmi).toBe(22.86);
    });

    it('should return weight and height in result', () => {
      const result = service.calculate({ weight: 70, height: 1.75 });
      expect(result.weight).toBe(70);
      expect(result.height).toBe(1.75);
    });

    it('should classify severe underweight (BMI < 16)', () => {
      const result = service.calculate({ weight: 40, height: 1.75 });
      expect(result.classification).toBe('Severe underweight');
    });

    it('should classify underweight (BMI 16–18.4)', () => {
      const result = service.calculate({ weight: 50, height: 1.75 });
      expect(result.classification).toBe('Underweight');
    });

    it('should classify normal weight (BMI 18.5–24.9)', () => {
      const result = service.calculate({ weight: 70, height: 1.75 });
      expect(result.classification).toBe('Normal weight');
    });

    it('should classify overweight (BMI 25–29.9)', () => {
      const result = service.calculate({ weight: 85, height: 1.75 });
      expect(result.classification).toBe('Overweight');
    });

    it('should classify obesity class I (BMI 30–34.9)', () => {
      const result = service.calculate({ weight: 100, height: 1.75 });
      expect(result.classification).toBe('Obesity class I');
    });

    it('should classify obesity class II (BMI 35–39.9)', () => {
      const result = service.calculate({ weight: 115, height: 1.75 });
      expect(result.classification).toBe('Obesity class II');
    });

    it('should classify obesity class III (BMI >= 40)', () => {
      const result = service.calculate({ weight: 140, height: 1.75 });
      expect(result.classification).toBe('Obesity class III');
    });
  });
});
