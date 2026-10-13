<template>
  <button
    :class="[placement === 'bottom' ? 'bottom-nav-item' : 'nav-item', { active }]"
    :aria-current="active ? 'page' : null"
    type="button"
    @click="$emit('select')"
  >
    <svg v-if="item.icon === 'home'" class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m3.5 10.5 8.5-7 8.5 7"/><path d="M5.5 9.5v10h5v-6h3v6h5v-10"/></svg>
    <svg v-else-if="item.icon === 'times'" class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg>
    <svg v-else-if="item.icon === 'chart'" class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M4 19.5h16M6.5 16v-4M12 16V7M17.5 16v-7"/><path d="m5 9 5-4 4 3 5-4"/></svg>
    <svg v-else-if="item.icon === 'schedule'" class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="5.5" width="16" height="15" rx="2"/><path d="M8 3.5v4M16 3.5v4M4 10h16"/></svg>
    <svg v-else-if="item.icon === 'profile'" class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"/><path d="M4.5 20c.5-3.2 3.4-5.3 7.5-5.3s7 2.1 7.5 5.3"/></svg>
    <svg v-else class="navigation-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M16 5.5a3.2 3.2 0 0 1 0 6.2M17 14a5 5 0 0 1 3.5 4.8"/></svg>
    <span>{{ item.label }}</span>
  </button>
</template>

<script>
export default {
  name: 'AppNavItem',
  props: {
    item: { type: Object, required: true },
    active: { type: Boolean, default: false },
    placement: { type: String, default: 'sidebar', validator: (value) => ['sidebar', 'bottom'].includes(value) }
  },
  emits: ['select']
}
</script>

<style scoped>
.navigation-icon { width: 21px; height: 21px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.bottom-nav-item .navigation-icon { width: 22px; height: 22px; }
</style>
