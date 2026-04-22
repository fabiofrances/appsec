import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';

describe('BMI API (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /bmi/calculate', () => {
    it('should calculate BMI and return result', () => {
      return request(app.getHttpServer())
        .post('/bmi/calculate')
        .send({ weight: 70, height: 1.75 })
        .expect(201)
        .expect((res) => {
          expect(res.body.bmi).toBe(22.86);
          expect(res.body.classification).toBe('Normal weight');
          expect(res.body.weight).toBe(70);
          expect(res.body.height).toBe(1.75);
        });
    });

    it('should return 400 for missing weight', () => {
      return request(app.getHttpServer())
        .post('/bmi/calculate')
        .send({ height: 1.75 })
        .expect(400);
    });

    it('should return 400 for missing height', () => {
      return request(app.getHttpServer())
        .post('/bmi/calculate')
        .send({ weight: 70 })
        .expect(400);
    });

    it('should return 400 for negative weight', () => {
      return request(app.getHttpServer())
        .post('/bmi/calculate')
        .send({ weight: -10, height: 1.75 })
        .expect(400);
    });

    it('should return 400 for height above max', () => {
      return request(app.getHttpServer())
        .post('/bmi/calculate')
        .send({ weight: 70, height: 5 })
        .expect(400);
    });
  });

  describe('GET /health', () => {
    it('should return healthy status', () => {
      return request(app.getHttpServer())
        .get('/health')
        .expect(200)
        .expect((res) => {
          expect(res.body.status).toBe('ok');
        });
    });
  });
});
