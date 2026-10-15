<template>
  <span :class="[variant, tone]">{{ initials }}</span>
</template>

<script>
export default {
  name: 'InitialAvatar',
  props: {
    initials: { type: String, required: true },
    variant: { type: String, default: 'user-avatar' },
    tone: { type: String, default: '' }
  }
}
</script>
