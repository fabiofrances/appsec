import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import BmiForm from '../BmiForm.vue'

describe('BmiForm', () => {
  it('should render weight and height inputs', () => {
    const wrapper = mount(BmiForm, { props: { loading: false } })
    expect(wrapper.find('#weight').exists()).toBe(true)
    expect(wrapper.find('#height').exists()).toBe(true)
  })

  it('should emit submit with weight and height on form submit', async () => {
    const wrapper = mount(BmiForm, { props: { loading: false } })

    await wrapper.find('#weight').setValue(70)
    await wrapper.find('#height').setValue(1.75)
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeTruthy()
    expect(wrapper.emitted('submit')![0]).toEqual([70, 1.75])
  })

  it('should disable button when loading is true', () => {
    const wrapper = mount(BmiForm, { props: { loading: true } })
    const button = wrapper.find('button')
    expect(button.attributes('disabled')).toBeDefined()
    expect(button.text()).toBe('Calculando...')
  })

  it('should show default button text when not loading', () => {
    const wrapper = mount(BmiForm, { props: { loading: false } })
    expect(wrapper.find('button').text()).toBe('Calcular IMC')
  })
})
