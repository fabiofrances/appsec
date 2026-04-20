<template>
  <form class="bmi-form" @submit.prevent="onSubmit">
    <div class="field">
      <label for="weight">Peso (kg)</label>
      <input
        id="weight"
        v-model.number="weight"
        type="number"
        min="1"
        max="500"
        step="0.1"
        placeholder="Ex: 70"
        required
      />
    </div>

    <div class="field">
      <label for="height">Altura (m)</label>
      <input
        id="height"
        v-model.number="height"
        type="number"
        min="0.5"
        max="3"
        step="0.01"
        placeholder="Ex: 1.75"
        required
      />
    </div>

    <button type="submit" :disabled="loading">
      {{ loading ? 'Calculando...' : 'Calcular IMC' }}
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{ loading: boolean }>()
const emit = defineEmits<{ submit: [weight: number, height: number] }>()

const weight = ref<number | null>(null)
const height = ref<number | null>(null)

function onSubmit() {
  if (weight.value && height.value) {
    emit('submit', weight.value, height.value)
  }
}
</script>

<style scoped>
.bmi-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

label {
  font-weight: 600;
  font-size: 0.9rem;
  color: #374151;
}

input {
  padding: 0.65rem 0.9rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
  outline: none;
}

input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}

button {
  padding: 0.75rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

button:hover:not(:disabled) {
  background: #2563eb;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
