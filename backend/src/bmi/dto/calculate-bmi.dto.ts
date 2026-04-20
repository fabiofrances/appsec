import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsPositive, Min, Max } from 'class-validator';

export class CalculateBmiDto {
  @ApiProperty({ example: 70, description: 'Weight in kilograms' })
  @IsNumber()
  @IsPositive()
  @Max(500)
  weight: number;

  @ApiProperty({ example: 1.75, description: 'Height in meters' })
  @IsNumber()
  @IsPositive()
  @Min(0.5)
  @Max(3)
  height: number;
}
