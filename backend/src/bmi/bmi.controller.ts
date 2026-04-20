import { Body, Controller, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { BmiService } from './bmi.service.js';
import { CalculateBmiDto } from './dto/calculate-bmi.dto.js';
import { BmiResultDto } from './dto/bmi-result.dto.js';

@ApiTags('BMI')
@Controller('bmi')
export class BmiController {
  constructor(private readonly bmiService: BmiService) {}

  @Post('calculate')
  @ApiOperation({ summary: 'Calculate BMI' })
  @ApiResponse({ status: 201, description: 'BMI calculated successfully', type: BmiResultDto })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  calculate(@Body() dto: CalculateBmiDto): BmiResultDto {
    return this.bmiService.calculate(dto);
  }
}
