<template>
  <section class="shared-profile-section" :class="`shared-profile-section--${variant}`" aria-labelledby="profile-heading">
    <div class="dashboard-heading">
      <p class="dashboard-eyebrow">ACCOUNT DETAILS</p>
      <h1 id="profile-heading" class="dashboard-title">Profile</h1>
      <p class="dashboard-description">Your Time Manager account information.</p>
    </div>
    <article class="card dashboard-surface dashboard-profile-card">
      <InitialAvatar variant="profile-avatar dashboard-profile-avatar" :initials="initials" />
      <div>
        <h2 class="dashboard-profile-name">{{ displayName }}</h2>
        <p>{{ profile.email || 'Email not available' }}</p>
        <span class="dashboard-profile-role">{{ roleLabel }}</span>
      </div>
    </article>
    <button class="dashboard-profile-logout" type="button" @click="$emit('logout')">Log out</button>
  </section>
</template>

<script>
import InitialAvatar from './InitialAvatar.vue'

export default {
  name: 'ProfileSection',
  components: { InitialAvatar },
  props: {
    initials: { type: String, required: true },
    displayName: { type: String, required: true },
    profile: { type: Object, required: true },
    roleLabel: { type: String, required: true },
    variant: { type: String, default: 'employee' }
  },
  emits: ['logout']
}
</script>

<style>
.workspace-shell .shared-profile-section { max-width: 720px; }
.workspace-shell .dashboard-profile-avatar { display: grid; place-items: center; border-radius: 50%; color: #fff; background: var(--app-accent); font-weight: 700; }
.workspace-shell .shared-profile-section--admin > .dashboard-heading { margin-bottom: 20px; }
.workspace-shell .shared-profile-section--admin .dashboard-title { font-size: clamp(32px, 3vw, 36px); }
</style>
