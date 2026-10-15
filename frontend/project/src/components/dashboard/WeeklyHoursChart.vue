<template>
  <div
    :class="['weekly-hours-chart', `weekly-hours-chart--${variant}`]"
    role="img"
    :aria-label="label"
  >
    <div
      v-for="day in days"
      :key="day.key"
      :class="variant === 'employee' ? 'week-column' : 'bar-day'"
    >
      <div class="bar-track">
        <div class="bar-fill" :style="{ height: `${day.height}%` }"></div>
      </div>
      <span v-if="variant === 'employee'" :class="['week-day', { 'is-today': day.isToday }]">{{ day.label }}</span>
      <small v-else>{{ day.label }}</small>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WeeklyHoursChart',
  props: {
    days: { type: Array, required: true },
    label: { type: String, required: true },
    variant: { type: String, default: 'employee', validator: (value) => ['employee', 'manager'].includes(value) }
  }
}
</script>

<style scoped>
.weekly-hours-chart { display: flex; align-items: flex-end; }
.bar-track { display: flex; align-items: flex-end; overflow: hidden; }
.bar-fill { width: 100%; transition: height 250ms ease; }

.weekly-hours-chart--employee { height: 150px; justify-content: flex-start; gap: clamp(12px, 3vw, 28px); margin-top: 8px; padding: 0 4px; }
.weekly-hours-chart--employee .week-column { display: grid; height: 100%; min-width: 18px; flex: 1; grid-template-rows: 1fr auto; justify-items: center; gap: 8px; }
.weekly-hours-chart--employee .bar-track { width: min(100%, 28px); height: 100%; border-radius: 8px; background: #edf0f5; }
.weekly-hours-chart--employee .bar-fill { min-height: 4px; border-radius: 8px; background: var(--app-accent); }
.weekly-hours-chart--employee .week-day { color: #9aa0a9; font-size: 11px; }
.weekly-hours-chart--employee .week-day.is-today { color: var(--app-accent); font-weight: 700; }

.weekly-hours-chart--manager { height: 160px; justify-content: space-around; gap: 12px; margin-top: 16px; padding: 0 clamp(8px, 3vw, 32px); }
.weekly-hours-chart--manager .bar-day { display: grid; width: auto; height: 100%; min-width: 30px; flex: 1; justify-items: center; align-content: end; gap: 8px; }
.weekly-hours-chart--manager .bar-track { width: 25px; height: 86px; border-radius: 7px; background: #e8ebf1; }
.weekly-hours-chart--manager .bar-fill { min-height: 0; border-radius: 7px; background: #1683f8; transition-duration: .25s; }
.weekly-hours-chart--manager small { color: #929baa; font-size: 12px; }

@media (max-width: 999px) {
  .weekly-hours-chart--employee { height: 128px; gap: 12px; }
}
</style>
