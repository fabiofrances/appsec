<template>
  <main class="page">
    <div class="card">
      <h1>Calculadora de IMC</h1>
      <p class="subtitle">Índice de Massa Corporal (OMS)</p>

      <BmiResult v-if="result" :result="result" @reset="reset" />

      <template v-else>
        <BmiForm :loading="loading" @submit="calculate" />
        <p v-if="error" class="error">{{ error }}</p>
      </template>
    </div>
  </main>
</template>

<script setup lang="ts">
import BmiForm from '@/components/BmiForm.vue'
import BmiResult from '@/components/BmiResult.vue'
import { useBmi } from '@/composables/useBmi'

const { result, loading, error, calculate, reset } = useBmi()
</script>

<style scoped>
.page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f1f5f9;
  padding: 1rem;
}

.card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
  padding: 2.5rem 2rem;
  width: 100%;
  max-width: 420px;
}

h1 {
  font-size: 1.6rem;
  font-weight: 800;
  color: #1e293b;
  margin: 0 0 0.25rem;
  text-align: center;
}

.subtitle {
  text-align: center;
  font-size: 0.85rem;
  color: #64748b;
  margin: 0 0 2rem;
}

.error {
  margin-top: 0.75rem;
  color: #dc2626;
  font-size: 0.9rem;
  text-align: center;
}
</style>
