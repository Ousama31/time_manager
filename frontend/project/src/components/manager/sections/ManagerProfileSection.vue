<template>
        <section class="manager-profile-section">
          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">ACCOUNT DETAILS</p><h1 class="dashboard-title">Profile</h1><p class="page-subtitle dashboard-description">Your Time Manager account information.</p></div></div>
          <article class="card profile-card dashboard-surface dashboard-profile-card"><InitialAvatar variant="profile-avatar dashboard-profile-avatar" :initials="initials" /><div><h2 class="dashboard-profile-name">{{ displayName }}</h2><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role dashboard-profile-role">Manager</span></div></article>
          <button class="profile-logout dashboard-profile-logout" type="button" @click="$emit('logout')">Log out</button>
        </section>
</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'ManagerProfileSection',
  components: { InitialAvatar },
  props: {
    initials: { type: String, required: true },
    displayName: { type: String, required: true },
    profile: { type: Object, required: true }
  },
}
</script>

<style>
.manager-dashboard .manager-profile-section { max-width: 720px; }
.manager-dashboard .profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: #fff; box-shadow: var(--app-shadow-profile); }
.manager-dashboard .profile-card h2 { margin: 0 0 6px; font-size: 18px; }
.manager-dashboard .profile-card p { margin: 0; color: var(--app-muted); font-size: 14px; }
.manager-dashboard .profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.manager-dashboard .profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid var(--app-border); border-radius: 11px; color: #48515c; background: #fff; font: inherit; font-weight: 600; cursor: pointer; transition: background .16s ease, border-color .16s ease; }
.manager-dashboard .profile-logout:hover, .manager-dashboard .profile-logout:focus-visible { border-color: #d2d8e2; background: #f7f9fc; outline: none; }
.manager-dashboard .profile-card { padding: 28px; }
.manager-dashboard .profile-card h2 { font-size: 21px; }
.manager-dashboard .profile-card p { font-size: 16px; }
.manager-dashboard .profile-role { font-size: 13px; }
.manager-dashboard .profile-logout { min-height: 50px; padding-inline: 20px; font-size: 15px; }
</style>
