import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import BmiResult from '../BmiResult.vue'

const makeResult = (bmi: number, classification: string) => ({
  bmi,
  classification,
  weight: 70,
  height: 1.75,
})

describe('BmiResult', () => {
  it('should display BMI value', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(22.86, 'Peso normal') } })
    expect(wrapper.find('.bmi-value').text()).toBe('22.86')
  })

  it('should display classification', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(22.86, 'Peso normal') } })
    expect(wrapper.find('.classification').text()).toBe('Peso normal')
  })

  it('should apply green class for normal weight', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(22.86, 'Peso normal') } })
    expect(wrapper.find('.result').classes()).toContain('green')
  })

  it('should apply blue class for underweight', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(17, 'Abaixo do peso') } })
    expect(wrapper.find('.result').classes()).toContain('blue')
  })

  it('should apply yellow class for overweight', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(27, 'Sobrepeso') } })
    expect(wrapper.find('.result').classes()).toContain('yellow')
  })

  it('should apply red class for obesity', () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(35, 'Obesidade grau II') } })
    expect(wrapper.find('.result').classes()).toContain('red')
  })

  it('should emit reset when button is clicked', async () => {
    const wrapper = mount(BmiResult, { props: { result: makeResult(22.86, 'Peso normal') } })
    await wrapper.find('.reset-btn').trigger('click')
    expect(wrapper.emitted('reset')).toBeTruthy()
  })
})
