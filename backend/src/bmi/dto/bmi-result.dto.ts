import { ApiProperty } from '@nestjs/swagger';

export class BmiResultDto {
  @ApiProperty({ example: 22.86 })
  bmi: number;

  @ApiProperty({ example: 'Normal weight' })
  classification: string;

  @ApiProperty({ example: 70 })
  weight: number;

  @ApiProperty({ example: 1.75 })
  height: number;
}
