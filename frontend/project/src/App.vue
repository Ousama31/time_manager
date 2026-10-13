<template>
  <div class="app-root">
    <!-- Offline status badge -->
    <div v-if="!isOnline" class="offline-badge" role="status">
      <span class="offline-dot"></span>
      <span>Mode hors-ligne</span>
      <span v-if="queueCount > 0" class="badge-count">({{ queueCount }} en attente)</span>
    </div>

    <!-- Reconnection Sync Spinner Dialog (Exigence Sujet) -->
    <div v-if="isSyncing" class="sync-overlay" role="dialog" aria-modal="true" aria-label="Synchronisation">
      <div class="sync-card">
        <div class="sync-spinner"></div>
        <h3>Synchronisation en cours…</h3>
        <p>Envoi de vos actions hors-ligne au serveur.</p>
        <div v-if="queueCount > 0" class="sync-counter">{{ queueCount }} requête(s) restante(s)</div>
      </div>
    </div>

    <router-view />
  </div>
</template>

<script>
import { StatusBar, Style } from '@capacitor/status-bar'
import offlineSync from './offlineSync'

export default {
  name: 'App',
  data() {
    return {
      isOnline: true,
      isSyncing: false,
      queueCount: 0,
      unsubscribeSync: null
    }
  },
  async mounted() {
    if (typeof window !== 'undefined' && window.Capacitor && window.Capacitor.isNativePlatform()) {
      try {
        await StatusBar.setStyle({ style: Style.Dark })
      } catch (e) {
        console.warn('StatusBar not available', e)
      }
    }

    this.unsubscribeSync = offlineSync.subscribe(({ isOnline, isSyncing, queueCount }) => {
      this.isOnline = isOnline
      this.isSyncing = isSyncing
      this.queueCount = queueCount
    })
  },
  beforeUnmount() {
    if (this.unsubscribeSync) this.unsubscribeSync()
  }
}
</script>

<style>
.app-root {
  min-height: 100vh;
  position: relative;
}

.offline-badge {
  position: fixed;
  top: calc(10px + env(safe-area-inset-top));
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: #f97316;
  color: #fff;
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 7px;
  box-shadow: 0 4px 14px rgba(249, 115, 22, 0.35);
  pointer-events: none;
}

.offline-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #fff;
  animation: pulse-dot 1.4s infinite ease-in-out;
}

.badge-count {
  opacity: 0.9;
  font-size: 11px;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 0.3; transform: scale(0.8); }
  50% { opacity: 1; transform: scale(1.2); }
}

.sync-overlay {
  position: fixed;
  inset: 0;
  z-index: 10000;
  background: rgba(15, 23, 42, 0.65);
  backdrop-filter: blur(4px);
  display: grid;
  place-items: center;
  padding: 20px;
}

.sync-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 28px 24px;
  max-width: 320px;
  width: 100%;
  text-align: center;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.sync-card h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 700;
  color: #1e293b;
}

.sync-card p {
  margin: 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.4;
}

.sync-counter {
  margin-top: 4px;
  font-size: 12px;
  font-weight: 650;
  color: #0284c7;
  background: #e0f2fe;
  padding: 4px 10px;
  border-radius: 999px;
}

.sync-spinner {
  width: 44px;
  height: 44px;
  border: 4px solid #e2e8f0;
  border-top-color: #0284c7;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 6px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
