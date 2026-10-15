<template>


          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">Account details</p><h1 class="dashboard-title">Profile</h1><p class="date-line dashboard-description">Your Time Manager account information.</p></div></div>
          <article class="card profile-card dashboard-surface dashboard-profile-card"><InitialAvatar variant="profile-avatar dashboard-profile-avatar" :initials="initials" /><div><h2 class="dashboard-profile-name">{{ displayName }}</h2><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role dashboard-profile-role">Employee</span></div></article>
          <button class="profile-logout dashboard-profile-logout" @click="$emit('logout')">Log out</button>

</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'EmployeeProfileSection',
  components: { InitialAvatar },
  props: {
    initials: { type: String, required: true },
    displayName: { type: String, required: true },
    profile: { type: Object, required: true }
  },
}
</script>

<style>
.employee-dashboard .schedule-empty-card p, .employee-dashboard .profile-card p { margin: 0; color: #89919c; font-size: 14px; }
.employee-dashboard .profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; }
.employee-dashboard .profile-card h2 { margin: 0 0 6px; font-size: 18px; }
.employee-dashboard .profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.employee-dashboard .profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid #e1e4e9; border-radius: 11px; color: #48515c; background: #fff; font: inherit; font-weight: 600; cursor: pointer; }
</style>
