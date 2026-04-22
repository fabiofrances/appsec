import { describe, it, expect, vi, beforeEach } from 'vitest'
import { calculateBmi } from '../bmi.service'

const mockPost = vi.hoisted(() => vi.fn())

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({ post: mockPost })),
  },
}))

describe('bmi.service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should return BMI result from API response', async () => {
    const mockResult = { bmi: 22.86, classification: 'Normal weight', weight: 70, height: 1.75 }
    mockPost.mockResolvedValue({ data: mockResult })

    const result = await calculateBmi({ weight: 70, height: 1.75 })

    expect(mockPost).toHaveBeenCalledWith('/bmi/calculate', { weight: 70, height: 1.75 })
    expect(result).toEqual(mockResult)
  })
})
