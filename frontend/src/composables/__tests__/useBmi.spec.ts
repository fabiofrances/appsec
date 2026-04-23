import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useBmi } from '../useBmi'
import * as bmiService from '@/services/bmi.service'

vi.mock('@/services/bmi.service')

const mockResult = { bmi: 22.86, classification: 'Peso normal', weight: 70, height: 1.75 }

describe('useBmi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should initialize with null result and no error', () => {
    const { result, error, loading } = useBmi()
    expect(result.value).toBeNull()
    expect(error.value).toBeNull()
    expect(loading.value).toBe(false)
  })

  it('should set result after successful calculation', async () => {
    vi.mocked(bmiService.calculateBmi).mockResolvedValue(mockResult)

    const { result, loading, calculate } = useBmi()
    await calculate(70, 1.75)

    expect(result.value).toEqual(mockResult)
    expect(loading.value).toBe(false)
  })

  it('should set error on failure', async () => {
    vi.mocked(bmiService.calculateBmi).mockRejectedValue(new Error('Network error'))

    const { error, calculate } = useBmi()
    await calculate(70, 1.75)

    expect(error.value).toBe('Network error')
  })

  it('should reset result and error on reset()', async () => {
    vi.mocked(bmiService.calculateBmi).mockResolvedValue(mockResult)

    const { result, error, calculate, reset } = useBmi()
    await calculate(70, 1.75)
    reset()

    expect(result.value).toBeNull()
    expect(error.value).toBeNull()
  })

  it('should set loading to true during calculation', async () => {
    let loadingDuringCall = false
    vi.mocked(bmiService.calculateBmi).mockImplementation(async () => {
      loadingDuringCall = true
      return mockResult
    })

    const { loading, calculate } = useBmi()
    await calculate(70, 1.75)

    expect(loadingDuringCall).toBe(true)
    expect(loading.value).toBe(false)
  })
})
