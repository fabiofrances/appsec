import axios from 'axios'
import type { BmiRequest, BmiResult } from '@/types/bmi.types'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'http://localhost:3000',
  headers: { 'Content-Type': 'application/json' },
})

export async function calculateBmi(payload: BmiRequest): Promise<BmiResult> {
  const { data } = await api.post<BmiResult>('/bmi/calculate', payload)
  return data
}
