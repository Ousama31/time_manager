<template>
  <div class="workspace-shell">
    <aside class="sidebar">
      <div class="brand-lockup">
        <span class="brand-mark" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="8.25"/><path d="M12 7v5l3.4 2"/></svg>
        </span>
        <span>Time Manager</span>
      </div>

      <nav class="side-navigation" aria-label="Main navigation">
        <AppNavItem v-for="item in navigation" :key="item.key" :item="item" :active="activeTab === item.key" @select="$emit('navigate', item.key)" />
      </nav>

      <button class="sidebar-logout" type="button" @click="$emit('logout')">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10 4H5.5A1.5 1.5 0 0 0 4 5.5v13A1.5 1.5 0 0 0 5.5 20H10M14 8l4 4-4 4M8 12h10"/></svg>
        <span>Log out</span>
      </button>
    </aside>

    <div class="main-column">
      <main class="page-content"><slot /></main>
    </div>

    <nav class="bottom-navigation" aria-label="Main navigation" :style="{ '--item-count': navigation.length }">
      <AppNavItem v-for="item in navigation" :key="item.key" placement="bottom" :item="item" :active="activeTab === item.key" @select="$emit('navigate', item.key)" />
    </nav>
  </div>
</template>

<script>
import AppNavItem from './AppNavItem.vue'

export default {
  name: 'AppShell',
  components: { AppNavItem },
  props: {
    navigation: { type: Array, default: () => [] },
    activeTab: { type: String, default: '' }
  },
  emits: ['navigate', 'logout']
}
</script>

<style scoped>
.workspace-shell { --accent: var(--app-accent); display: flex; min-height: 100vh; color: var(--app-text); background: var(--app-background); font-family: inherit; }
.sidebar { position: fixed; inset: 0 auto 0 0; z-index: 4; display: flex; width: 248px; flex-direction: column; padding: 24px 16px; border-right: 1px solid var(--app-border); color: var(--app-text); background: var(--app-sidebar); }
.brand-lockup { display: flex; height: 54px; align-items: center; gap: 12px; padding: 0 8px; color: var(--app-text); font-size: 18px; font-weight: 700; letter-spacing: -.3px; }
.brand-mark { display: grid; width: 40px; height: 40px; place-items: center; border-radius: 12px; background: var(--accent); }
.brand-mark svg { width: 24px; stroke: #fff; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.side-navigation { display: grid; gap: 7px; margin-top: 42px; }
.nav-item { position: relative; display: flex; min-height: 48px; align-items: center; gap: 13px; padding: 0 14px; border: 0; border-radius: 12px; color: #6b778b; background: transparent; text-align: left; font: inherit; font-size: 14px; cursor: pointer; transition: color .16s ease, background .16s ease; }
.nav-item:hover, .nav-item:focus-visible, .nav-item.active { color: var(--app-accent-strong); background: var(--app-sidebar-active); outline: none; }
.nav-item.active { font-weight: 650; }
.nav-item.active::after { position: absolute; top: 11px; right: 0; width: 3px; height: 26px; border-radius: 4px; background: var(--app-accent); content: ''; }
.sidebar-logout { display: flex; align-items: center; gap: 12px; margin: auto 0 4px; padding: 12px 14px; border: 0; border-radius: 10px; color: #6b778b; background: transparent; text-align: left; font: inherit; cursor: pointer; }
.sidebar-logout:hover, .sidebar-logout:focus-visible { color: #b42318; background: #fff1f0; outline: none; }
.sidebar-logout svg { width: 19px; height: 19px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.main-column { width: calc(100% - 248px); min-width: 0; min-height: 100vh; margin-left: 248px; }
.page-content { width: min(100%, 1500px); margin: 0 auto; padding: 36px clamp(28px, 4vw, 64px) 52px; }
.bottom-navigation { display: none; }
@media (max-width: 999px) {
  .workspace-shell {
    display: block;
    padding-top: env(safe-area-inset-top);
    padding-bottom: calc(76px + env(safe-area-inset-bottom));
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
  }
  .sidebar { display: none; }
  .main-column { width: 100%; min-height: 100vh; margin: 0; }
  .page-content { padding: 20px 18px 30px; }
  .bottom-navigation {
    position: fixed;
    right: 0;
    bottom: 0;
    left: 0;
    z-index: 5;
    display: grid;
    grid-template-columns: repeat(var(--item-count), minmax(0, 1fr));
    padding: 8px max(7px, env(safe-area-inset-right)) calc(8px + env(safe-area-inset-bottom)) max(7px, env(safe-area-inset-left));
    border-top: 1px solid var(--app-border);
    background: rgb(255 255 255 / 97%);
    box-shadow: 0 -5px 20px rgb(31 41 55 / 4%);
    backdrop-filter: blur(18px);
  }
  .bottom-nav-item { display: grid; min-height: 52px; justify-items: center; align-content: center; gap: 4px; border: 0; border-radius: 10px; color: #89919c; background: transparent; font: inherit; font-size: 10px; cursor: pointer; }
  .bottom-nav-item.active { color: var(--app-accent-strong); background: var(--app-accent-soft); }
}
@media (max-width: 560px) {
  .page-content {
    padding-top: 16px;
    padding-right: max(14px, env(safe-area-inset-right));
    padding-left: max(14px, env(safe-area-inset-left));
    padding-bottom: 24px;
  }
}

/* Accessible sizing shared by manager and administrator workspaces. */
.sidebar { width: 264px; padding: 27px 18px; }
.brand-lockup { height: 58px; font-size: 20px; }
.brand-mark { width: 44px; height: 44px; }
.brand-mark svg { width: 27px; }
.side-navigation { gap: 9px; margin-top: 46px; }
.nav-item { min-height: 54px; gap: 14px; font-size: 16px; }
.sidebar-logout { min-height: 48px; font-size: 15px; }
.sidebar-logout svg { width: 21px; height: 21px; }
.main-column { width: calc(100% - 264px); margin-left: 264px; }
.page-content { padding-top: 42px; padding-bottom: 60px; }

@media (max-width: 999px) {
  .main-column { width: 100%; margin: 0; }
  .page-content { padding: 28px 22px 36px; }
  .bottom-nav-item { min-height: 58px; font-size: 12px; }
}

@media (max-width: 560px) {
  .page-content { padding: 22px 15px 30px; }
  .bottom-nav-item { min-height: 56px; font-size: 11px; }
}
</style>
