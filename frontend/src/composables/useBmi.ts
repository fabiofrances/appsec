import { ref } from 'vue'
import { calculateBmi } from '@/services/bmi.service'
import type { BmiResult } from '@/types/bmi.types'

export function useBmi() {
  const result = ref<BmiResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function calculate(weight: number, height: number) {
    loading.value = true
    error.value = null
    result.value = null
    try {
      result.value = await calculateBmi({ weight, height })
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Erro ao calcular o IMC.'
    } finally {
      loading.value = false
    }
  }

  function reset() {
    result.value = null
    error.value = null
  }

  return { result, loading, error, calculate, reset }
}
