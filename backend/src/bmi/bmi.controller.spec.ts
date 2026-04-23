import { Test, TestingModule } from '@nestjs/testing';
import { BmiController } from './bmi.controller.js';
import { BmiService } from './bmi.service.js';

jest.mock('prom-client', () => ({
  Counter: jest.fn().mockImplementation(() => ({ inc: jest.fn() })),
  Histogram: jest.fn().mockImplementation(() => ({ observe: jest.fn() })),
}));

describe('BmiController', () => {
  let controller: BmiController;
  let service: BmiService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BmiController],
      providers: [BmiService],
    }).compile();

    controller = module.get<BmiController>(BmiController);
    service = module.get<BmiService>(BmiService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('calculate', () => {
    it('should return BMI result from service', () => {
      const dto = { weight: 70, height: 1.75 };
      const result = controller.calculate(dto);

      expect(result.bmi).toBe(22.86);
      expect(result.classification).toBe('Peso normal');
    });

    it('should delegate calculation to BmiService', () => {
      const spy = jest.spyOn(service, 'calculate');
      const dto = { weight: 70, height: 1.75 };

      controller.calculate(dto);

      expect(spy).toHaveBeenCalledWith(dto);
    });
  });
});
