<template>
  <div class="result" :class="colorClass">
    <p class="bmi-value">{{ result.bmi }}</p>
    <p class="classification">{{ result.classification }}</p>
    <p class="detail">{{ result.weight }} kg / {{ result.height }} m</p>
    <button class="reset-btn" @click="emit('reset')">Calcular novamente</button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { BmiResult } from '@/types/bmi.types'

const props = defineProps<{ result: BmiResult }>()
const emit = defineEmits<{ reset: [] }>()

const colorClass = computed(() => {
  const bmi = props.result.bmi
  if (bmi < 18.5) return 'blue'
  if (bmi < 25) return 'green'
  if (bmi < 30) return 'yellow'
  return 'red'
})
</script>

<style scoped>
.result {
  text-align: center;
  padding: 1.5rem;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.result.green  { background: #dcfce7; color: #166534; }
.result.blue   { background: #dbeafe; color: #1e40af; }
.result.yellow { background: #fef9c3; color: #854d0e; }
.result.red    { background: #fee2e2; color: #991b1b; }

.bmi-value {
  font-size: 3rem;
  font-weight: 800;
  margin: 0;
}

.classification {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0;
}

.detail {
  font-size: 0.85rem;
  opacity: 0.75;
  margin: 0;
}

.reset-btn {
  margin-top: 0.75rem;
  padding: 0.5rem 1rem;
  background: transparent;
  border: 2px solid currentColor;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  color: inherit;
  transition: opacity 0.2s;
}

.reset-btn:hover {
  opacity: 0.7;
}
</style>
