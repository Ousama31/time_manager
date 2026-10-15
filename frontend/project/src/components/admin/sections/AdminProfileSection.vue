<template>
        <section class="admin-profile-section" aria-labelledby="profile-heading">
          <div class="profile-page-heading dashboard-heading"><p class="admin-eyebrow dashboard-eyebrow">ACCOUNT DETAILS</p><h2 id="profile-heading" class="dashboard-title">Profile</h2><p class="dashboard-description">Your Time Manager account information.</p></div>
          <article class="card profile-card dashboard-surface dashboard-profile-card"><span class="profile-avatar dashboard-profile-avatar">{{ initials }}</span><div><h3 class="dashboard-profile-name">{{ displayName }}</h3><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role dashboard-profile-role">Administrator</span></div></article>
          <button class="profile-logout dashboard-profile-logout" type="button" @click="disconnect">Log out</button>
        </section>
</template>

<script>
export default {
  name: 'AdminProfileSection',

  props: {
    initials: { type: String, required: true },
    displayName: { type: String, required: true },
    profile: { type: Object, required: true }
  },
  methods: { disconnect() { this.$emit('logout') } }
}
</script>

<style>
.admin-dashboard .admin-profile-section { max-width: 720px; }
.admin-dashboard .profile-page-heading { margin-bottom: 20px; }
.admin-dashboard .profile-page-heading h2 { margin: 0; color: var(--app-text); font-size: 28px; letter-spacing: -.6px; }
.admin-dashboard .profile-page-heading > p:last-child { margin: 6px 0 0; color: var(--app-muted); font-size: 14px; }
.admin-dashboard .profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: var(--app-surface); box-shadow: var(--app-shadow-profile); }
.admin-dashboard .profile-avatar { display: grid; width: 62px; height: 62px; flex: 0 0 62px; place-items: center; border-radius: 50%; color: #fff; background: var(--app-accent); font-size: 19px; font-weight: 700; }
.admin-dashboard .profile-card h3 { margin: 0 0 6px; color: var(--app-text); font-size: 18px; }
.admin-dashboard .profile-card p { margin: 0; color: var(--app-muted); font-size: 14px; }
.admin-dashboard .profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.admin-dashboard .profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid var(--app-border); border-radius: 11px; color: #48515c; background: var(--app-surface); font: inherit; font-weight: 600; cursor: pointer; transition: background .16s ease, border-color .16s ease; }
.admin-dashboard .profile-logout:hover, .admin-dashboard .profile-logout:focus-visible { border-color: #d2d8e2; background: #f7f9fc; outline: none; }
.admin-dashboard .profile-page-heading h2 { font-size: 32px; }
.admin-dashboard .profile-page-heading > p:last-child, .admin-dashboard .profile-card p { font-size: 16px; }
.admin-dashboard .profile-card { padding: 28px; }
.admin-dashboard .profile-card h3 { font-size: 21px; }
.admin-dashboard .profile-logout { min-height: 50px; font-size: 15px; }
</style>
