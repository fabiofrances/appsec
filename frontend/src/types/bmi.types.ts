export interface BmiRequest {
  weight: number
  height: number
}

export interface BmiResult {
  bmi: number
  classification: string
  weight: number
  height: number
}

export type BmiClassification =
  | 'Severe underweight'
  | 'Underweight'
  | 'Normal weight'
  | 'Overweight'
  | 'Obesity class I'
  | 'Obesity class II'
  | 'Obesity class III'
