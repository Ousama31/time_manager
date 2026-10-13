<template>
  <AppShell :navigation="navigation" :active-tab="activeTab" @navigate="activeTab = $event" @logout="disconnect">
        <template v-if="activeTab === 'home'">
          <div class="page-heading home-heading">
            <div>
              <p class="eyebrow">{{ greeting }}</p>
              <h1>{{ displayName }} <span aria-hidden="true">👋</span></h1>
              <p class="date-line">{{ todayLabel }}</p>
            </div>
            <button class="refresh-button" aria-label="Refresh dashboard" :disabled="loading" @click="loadDashboard">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 7v5h-5M4 17v-5h5"/><path d="M5.5 9A7 7 0 0 1 17.4 6L20 8M4 16l2.6 2A7 7 0 0 0 18.5 15"/></svg>
              <span>Refresh</span>
            </button>
          </div>

          <p v-if="errorMessage" class="notice error-notice" role="alert">{{ errorMessage }}</p>
          <p v-if="successMessage" class="notice success-notice" role="status">{{ successMessage }}</p>

          <section class="top-card-grid" aria-label="Today's work overview">
            <article class="card current-card">
              <div class="card-heading-row">
                <div class="card-title-group"><span class="icon-tile accent-tile"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><div><p class="card-kicker">Current working time</p><h2>{{ clockState === 'working' ? 'You are working' : clockState === 'break' ? 'You are on break' : 'You are clocked out' }}</h2></div></div>
                <span :class="['status-pill', clockState === 'working' ? 'status-working' : clockState === 'break' ? 'status-break' : 'status-idle']"><i></i>{{ clockState === 'working' ? 'Working' : clockState === 'break' ? 'On break' : 'Not working' }}</span>
              </div>
              <div class="current-time-row">
                <div><strong class="large-time">{{ clockState !== 'off' ? elapsedLabel : '—' }}</strong><span class="muted-line">{{ clockState !== 'off' ? `${clockState === 'break' ? 'Break started' : 'Working since'} ${formatTime(clockStart)}` : 'Clock in to start your day' }}</span></div>
                <div class="clock-actions">
                  <button class="clock-button" :disabled="clockBusy || !userId" @click="toggleClock">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg>
                    {{ clockBusy ? 'Saving…' : clockState === 'off' ? 'Clock In' : 'Clock Out' }}
                  </button>
                  <button v-if="clockState !== 'off'" class="clock-button break-button" :disabled="clockBusy || !userId" @click="toggleBreak">
                    {{ clockBusy ? 'Saving…' : clockState === 'break' ? 'End Break' : 'Break' }}
                  </button>
                </div>
              </div>
            </article>

            <article class="card today-card">
              <div class="card-heading-row">
                <div><p class="card-kicker">Today's hours</p><h2>Time tracked today</h2></div>
                <span class="icon-tile pale-tile"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 19.5h16M6.5 16V11M12 16V6M17.5 16V9"/></svg></span>
              </div>
              <div class="progress-content">
                <div class="progress-ring" :style="{ '--progress': `${todayProgress}%` }"><span>{{ todayProgress }}%</span></div>
                <div class="progress-summary"><strong class="metric-time">{{ todayHoursLabel }}</strong><p class="daily-target">of <strong>8h</strong> daily target</p></div>
              </div>
            </article>
          </section>

          <section class="middle-card-grid">
            <article class="card weekly-card">
              <div class="section-heading"><div><p class="card-kicker">Your overview</p><h2>Weekly hours</h2></div><span class="subtle-label">This week</span></div>
              <strong class="weekly-total">{{ weekHoursLabel }}</strong>
              <WeeklyHoursChart :days="weekDays" :label="`Weekly work hours: ${weekHoursLabel}`" />
            </article>

            <article class="card recent-card">
              <div class="section-heading"><div><p class="card-kicker">Your activity</p><h2>Recent entries</h2></div><button class="text-action" @click="activeTab = 'times'">See all</button></div>
              <div v-if="recentEntries.length" class="entry-list">
                <div v-for="entry in recentEntries" :key="entry.id" class="entry-row">
                  <span class="entry-dot" :class="entry.kind === 'break' ? 'entry-dot-break' : 'entry-dot-work'"></span>
                  <span class="entry-name">{{ entry.kind === 'break' ? 'Break' : 'Work session' }}</span>
                  <span class="entry-time">{{ formatTime(entry.start) }} – {{ formatTime(entry.end) }}</span>
                </div>
              </div>
              <div v-else class="empty-state compact-empty">No work or break entries yet.</div>
            </article>
          </section>

        </template>

        <template v-else-if="activeTab === 'times'">
          <div class="page-heading"><div><p class="eyebrow">Time records</p><h1>My Times</h1><p class="date-line">Review your recorded work sessions.</p></div><button class="refresh-button" aria-label="Refresh time records" :disabled="loading" @click="loadDashboard"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 7v5h-5M4 17v-5h5"/><path d="M5.5 9A7 7 0 0 1 17.4 6L20 8M4 16l2.6 2A7 7 0 0 0 18.5 15"/></svg><span>Refresh</span></button></div>
          <article class="card times-panel"><div class="section-heading"><div><p class="card-kicker">Recorded activity</p><h2>Work and break entries</h2></div><span class="subtle-label">{{ workingTimes.length }} {{ workingTimes.length === 1 ? 'entry' : 'entries' }}</span></div>
            <div v-if="workingTimes.length" class="times-table"><div class="times-table-head"><span>Type</span><span>Date</span><span>Started</span><span>Ended</span><span>Duration</span></div><div v-for="entry in sortedWorkingTimes" :key="entry.id" class="times-table-row"><span>{{ entry.kind === 'break' ? 'Break' : 'Work' }}</span><span>{{ formatDate(entry.start) }}</span><span>{{ formatTime(entry.start) }}</span><span>{{ formatTime(entry.end) }}</span><strong>{{ durationLabel(entry.start, entry.end) }}</strong></div></div>
            <div v-else class="empty-state">Your completed work and break entries will appear here.</div>
          </article>
        </template>

        <template v-else>
          <div class="page-heading"><div><p class="eyebrow">Account details</p><h1>Profile</h1><p class="date-line">Your Time Manager account information.</p></div></div>
          <article class="card profile-card"><InitialAvatar variant="profile-avatar" :initials="initials" /><div><h2>{{ displayName }}</h2><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role">Employee</span></div></article>
          <button class="profile-logout" @click="disconnect">Log out</button>
        </template>

        <p v-if="activeTab !== 'home' && errorMessage" class="notice error-notice" role="alert">{{ errorMessage }}</p>
  </AppShell>
</template>

<script>
import api from '../api'
import { getDisplayName, getInitials } from '../utils/identity'
import InitialAvatar from './InitialAvatar.vue'
import AppShell from './AppShell.vue'
import WeeklyHoursChart from './WeeklyHoursChart.vue'

export default {
  name: 'Home',
  components: { AppShell, InitialAvatar, WeeklyHoursChart },
  data() {
    return {
      userId: sessionStorage.getItem('userId'),
      profile: {},
      workingTimes: [],
      clockState: 'off',
      clockStart: null,
      now: Date.now(),
      clockBusy: false,
      loading: false,
      activeTab: 'home',
      errorMessage: '',
      successMessage: '',
      tick: null
    }
  },
  computed: {
    navigation() {
      return [
        { key: 'home', label: 'Home', icon: 'home' },
        { key: 'times', label: 'My Times', icon: 'times' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    displayName() {
      return getDisplayName(this.profile, 'Welcome', ['username', 'name'])
    },
    initials() {
      return getInitials(this.displayName)
    },
    greeting() {
      const hour = new Date(this.now).getHours()
      if (hour < 12) return 'Good morning,'
      if (hour < 18) return 'Good afternoon,'
      return 'Good evening,'
    },
    todayLabel() {
      return new Date(this.now).toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })
    },
    todayEntries() {
      const today = new Date(this.now).toDateString()
      return this.workingTimes.filter((entry) => entry.kind !== 'break' && new Date(entry.start).toDateString() === today)
    },
    todaySeconds() {
      const completed = this.todayEntries.reduce((sum, entry) => sum + this.durationSeconds(entry.start, entry.end), 0)
      const live = this.clockState === 'working' && this.clockStart && new Date(this.clockStart).toDateString() === new Date(this.now).toDateString()
        ? Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))
        : 0
      return completed + live
    },
    todayHoursLabel() {
      return this.formatDuration(this.todaySeconds)
    },
    todayProgress() {
      return Math.min(100, Math.round((this.todaySeconds / (8 * 3600)) * 100))
    },
    elapsedLabel() {
      return this.clockStart ? this.formatDuration(Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))) : '0h 00m'
    },
    sortedWorkingTimes() {
      return [...this.workingTimes].sort((a, b) => new Date(b.start) - new Date(a.start))
    },
    recentEntries() {
      const entries = this.sortedWorkingTimes.slice(0, 4).map((entry) => ({ ...entry, kind: entry.kind || 'work' }))
      if (this.clockState === 'break' && this.clockStart) {
        return [{ id: 'active-break', kind: 'break', start: this.clockStart, end: null }, ...entries].slice(0, 4)
      }
      return entries
    },
    weekDates() {
      const today = new Date(this.now)
      const mondayOffset = (today.getDay() + 6) % 7
      const monday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - mondayOffset)
      return Array.from({ length: 7 }, (_, index) => new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + index))
    },
    weekDays() {
      const todayKey = new Date(this.now).toDateString()
      const durations = this.weekDates.map((date) => this.workingTimes.reduce((sum, entry) => {
        if (entry.kind === 'break') return sum
        if (new Date(entry.start).toDateString() !== date.toDateString()) return sum
        return sum + this.durationSeconds(entry.start, entry.end)
      }, 0))
      const liveIndex = this.weekDates.findIndex((date) => date.toDateString() === todayKey)
      if (liveIndex >= 0 && this.clockState === 'working' && this.clockStart) durations[liveIndex] += Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))
      const maxSeconds = Math.max(8 * 3600, ...durations)
      return this.weekDates.map((date, index) => ({
        key: date.toISOString(),
        label: date.toLocaleDateString(undefined, { weekday: 'short' }),
        height: Math.max(4, Math.round((durations[index] / maxSeconds) * 100)),
        isToday: date.toDateString() === todayKey
      }))
    },
    weekHoursLabel() {
      let total = 0
      this.weekDates.forEach((date) => {
        this.workingTimes.forEach((entry) => {
          if (entry.kind === 'break') return
          if (new Date(entry.start).toDateString() === date.toDateString()) total += this.durationSeconds(entry.start, entry.end)
        })
      })
      if (this.clockState === 'working' && this.clockStart) total += Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))
      return this.formatDuration(total)
    },
  },
  mounted() {
    this.loadProfile()
    this.loadDashboard()
    this.tick = window.setInterval(() => { this.now = Date.now() }, 1000)
  },
  beforeUnmount() {
    if (this.tick) window.clearInterval(this.tick)
  },
  methods: {
    async loadProfile() {
      if (!this.userId) return
      try {
        const response = await api.get(`/users/${this.userId}`)
        this.profile = response.data.data || {}
      } catch (error) {
        console.error('Could not load profile:', error)
      }
    },
    async loadDashboard() {
      if (!this.userId) return
      this.loading = true
      this.errorMessage = ''
      try {
        const [clockResponse, timesResponse] = await Promise.all([
          api.get(`/clocks/${this.userId}`),
          api.get(`/workingtime/${this.userId}`)
        ])
        const clock = clockResponse.data.data
        this.clockState = clock?.state || (clock?.status ? 'working' : 'off')
        this.clockStart = this.clockState !== 'off' ? clock.time : null
        this.workingTimes = timesResponse.data.data || []
      } catch (error) {
        console.error('Could not load time data:', error)
        this.errorMessage = 'We could not load your time data. Please try again.'
      } finally {
        this.loading = false
      }
    },
    async toggleClock() {
      if (!this.userId || this.clockBusy) return
      this.clockBusy = true
      this.errorMessage = ''
      this.successMessage = ''
      const previousState = this.clockState
      const previousStart = this.clockState !== 'off' ? this.clockStart : null
      try {
        const response = await api.post(`/clocks/${this.userId}`, { action: 'clock' })
        const clock = response.data.data
        this.clockState = clock?.state || (clock?.status ? 'working' : 'off')
        this.clockStart = this.clockState !== 'off' ? clock.time : null
        if (previousStart && this.clockState === 'off' && clock?.time) {
          await api.post(`/workingtime/${this.userId}`, { workingtime: { start: previousStart, end: clock.time, kind: previousState === 'break' ? 'break' : 'work' } })
          await this.loadDashboard()
        }
        this.successMessage = this.clockState === 'working' ? 'You are clocked in. Have a focused day!' : 'Your work session has been saved.'
      } catch (error) {
        console.error('Could not update clock:', error)
        this.errorMessage = 'We could not update your clock. Please try again.'
        this.loadDashboard()
      } finally {
        this.clockBusy = false
      }
    },
    async toggleBreak() {
      if (!this.userId || this.clockBusy || this.clockState === 'off') return
      this.clockBusy = true
      this.errorMessage = ''
      this.successMessage = ''
      const previousState = this.clockState
      const previousStart = this.clockStart
      try {
        const response = await api.post(`/clocks/${this.userId}`, { action: 'break' })
        const clock = response.data.data
        this.clockState = clock?.state || (clock?.status ? 'working' : 'off')
        this.clockStart = this.clockState !== 'off' ? clock.time : null
        if (previousStart && clock?.time) {
          const kind = previousState === 'working' ? 'work' : 'break'
          await api.post(`/workingtime/${this.userId}`, { workingtime: { start: previousStart, end: clock.time, kind } })
          await this.loadDashboard()
        }
        this.successMessage = this.clockState === 'break' ? 'Break started. Take a moment to recharge.' : 'Break ended. Your work session has resumed.'
      } catch (error) {
        console.error('Could not update break:', error)
        this.errorMessage = 'We could not update your break. Please try again.'
        this.loadDashboard()
      } finally {
        this.clockBusy = false
      }
    },
    async disconnect() {
      try {
        await api.post('/users/sign_out')
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        sessionStorage.clear()
        this.$router.push('/login')
      }
    },
    durationSeconds(start, end) {
      if (!start || !end) return 0
      const seconds = Math.floor((new Date(end).getTime() - new Date(start).getTime()) / 1000)
      return Number.isFinite(seconds) ? Math.max(0, seconds) : 0
    },
    formatDuration(seconds) {
      const hours = Math.floor(seconds / 3600)
      const minutes = Math.floor((seconds % 3600) / 60)
      return `${hours}h ${String(minutes).padStart(2, '0')}m`
    },
    durationLabel(start, end) {
      return this.formatDuration(this.durationSeconds(start, end))
    },
    formatTime(value) {
      if (!value) return '—'
      return new Date(value).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })
    },
    formatDate(value) {
      if (!value) return '—'
      return new Date(value).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
    }
  }
}
</script>

<style scoped>
.workspace-shell { --accent: var(--app-accent); --ink: var(--app-text); --muted: var(--app-muted); --line: #e5eae6; display: flex; min-height: 100vh; color: var(--ink); background: var(--app-background); font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif; }
.sidebar { position: fixed; inset: 0 auto 0 0; z-index: 4; display: flex; width: 248px; flex-direction: column; padding: 24px 16px; color: #fff; background: #102c4b; }
.brand-lockup { display: flex; height: 54px; align-items: center; gap: 12px; padding: 0 8px; font-size: 18px; font-weight: 700; letter-spacing: -.3px; }
.brand-mark { display: grid; width: 40px; height: 40px; place-items: center; border-radius: 12px; background: var(--accent); }
.brand-mark svg { width: 24px; stroke: #fff; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.side-navigation { display: grid; gap: 7px; margin-top: 42px; }
.nav-item { position: relative; display: flex; min-height: 48px; align-items: center; gap: 13px; padding: 0 14px; border: 0; border-radius: 12px; color: #aebed0; background: transparent; text-align: left; font: inherit; font-size: 14px; cursor: pointer; }
.nav-item.active { color: #f2f8ff; background: #183d62; }
.nav-item.active::after { position: absolute; top: 11px; right: 0; width: 3px; height: 26px; border-radius: 4px; background: #76baff; content: ''; }
.sidebar-logout { display: flex; align-items: center; gap: 12px; margin: auto 0 4px; padding: 12px 14px; border: 0; color: #adbdce; background: none; text-align: left; font: inherit; cursor: pointer; }
.sidebar-logout svg, .logout-button svg { width: 19px; height: 19px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.main-column { width: calc(100% - 248px); min-width: 0; min-height: 100vh; margin-left: 248px; }
.topbar { position: sticky; top: 0; z-index: 3; display: flex; height: 76px; align-items: center; justify-content: space-between; padding: 0 clamp(28px, 4vw, 64px); border-bottom: 1px solid #e9ebf0; background: rgb(255 255 255 / 96%); backdrop-filter: blur(16px); }
.topbar-caption { color: #7e8792; font-size: 14px; }
.topbar-user { display: flex; align-items: center; gap: 12px; }
.user-avatar, .profile-avatar { display: grid; width: 42px; height: 42px; flex: 0 0 42px; place-items: center; border-radius: 50%; color: #fff; background: var(--accent); font-size: 14px; font-weight: 700; }
.topbar-user-copy { display: grid; gap: 2px; }
.topbar-user-copy strong { font-size: 13px; }
.topbar-user-copy small { color: #8c929b; font-size: 12px; }
.logout-button { display: none; width: 38px; height: 38px; place-items: center; margin-left: 8px; border: 0; border-radius: 10px; color: #747c86; background: #f4f5f8; cursor: pointer; }
.page-content { width: min(100%, 1500px); margin: 0 auto; padding: 36px clamp(28px, 4vw, 64px) 52px; }
.page-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 18px; margin-bottom: 26px; }
.eyebrow, .card-kicker { margin: 0 0 7px; color: #8b929d; font-size: 12px; font-weight: 650; letter-spacing: .04em; text-transform: uppercase; }
.page-heading h1 { margin: 0; color: #20242c; font-size: clamp(26px, 3vw, 34px); font-weight: 720; letter-spacing: -.8px; }
.date-line { margin: 8px 0 0; color: #8b929d; font-size: 14px; }
.refresh-button { display: flex; min-height: 40px; align-items: center; gap: 8px; padding: 0 13px; border: 1px solid #dfe3e9; border-radius: 10px; color: #4d5968; background: #fff; font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; }
.refresh-button:disabled { opacity: .6; }
.refresh-button svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.top-card-grid { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(280px, .8fr); gap: 16px; }
.middle-card-grid { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(300px, .8fr); gap: 16px; margin-top: 16px; }
.card { min-width: 0; border: 1px solid #eceef2; border-radius: 20px; background: #fff; box-shadow: 0 6px 20px rgb(27 41 61 / 5%); }
.current-card, .today-card { min-height: 226px; padding: 24px; }
.card-heading-row, .section-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.card-title-group { display: flex; min-width: 0; align-items: center; gap: 13px; }
.icon-tile { display: grid; width: 44px; height: 44px; flex: 0 0 44px; place-items: center; border-radius: 13px; }
.icon-tile svg { width: 21px; height: 21px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.accent-tile { color: #fff; background: var(--accent); }
.pale-tile { color: var(--accent); background: var(--app-accent-soft); }
.card-kicker { margin-bottom: 4px; }
.card h2 { margin: 0; font-size: 16px; font-weight: 650; letter-spacing: -.15px; }
.status-pill { display: inline-flex; flex: 0 0 auto; align-items: center; gap: 7px; padding: 7px 10px; border-radius: 999px; font-size: 11px; font-weight: 650; }
.status-pill i { width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
.status-working { color: #16804a; background: #e9f8ef; }
.status-break { color: #946200; background: #fff4d8; }
.status-idle { color: #717986; background: #f0f2f5; }
.current-time-row { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-top: 28px; }
.current-time-row > div { display: grid; gap: 5px; }
.large-time { color: #20242c; font-size: clamp(32px, 4vw, 42px); font-weight: 740; letter-spacing: -1.7px; line-height: 1; }
.muted-line { color: #8b929d; font-size: 13px; }
.clock-actions { display: flex; align-items: center; gap: 10px; }
.current-time-row > .clock-actions { display: flex; gap: 10px; }
.clock-button { display: inline-flex; min-width: 144px; min-height: 48px; align-items: center; justify-content: center; gap: 9px; padding: 0 19px; border: 0; border-radius: 12px; color: #fff; background: var(--accent); font: inherit; font-size: 14px; font-weight: 650; box-shadow: 0 5px 12px rgb(22 132 248 / 18%); cursor: pointer; }
.clock-button:disabled { opacity: .55; cursor: not-allowed; }
.clock-button.break-button { color: #745000; background: #f3b536; box-shadow: 0 5px 12px rgb(243 181 54 / 18%); }
.clock-button.break-button:hover:not(:disabled) { background: #e8a91d; }
.clock-button svg { width: 18px; height: 18px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.today-card { display: flex; flex-direction: column; justify-content: space-between; }
.today-card .card-kicker { margin-bottom: 5px; }
.progress-content { display: flex; align-items: center; gap: clamp(18px, 2.5vw, 30px); margin: 12px 0 2px; }
.progress-ring { --ring-size: clamp(116px, 10.5vw, 140px); display: grid; width: var(--ring-size); height: var(--ring-size); flex: 0 0 var(--ring-size); place-items: center; border-radius: 50%; background: conic-gradient(var(--accent) var(--progress), #e6e9ee 0); transform: rotate(-90deg); }
.progress-ring::before { grid-area: 1 / 1; width: calc(var(--ring-size) - 28px); height: calc(var(--ring-size) - 28px); border-radius: 50%; background: #fff; content: ''; }
.progress-ring span { z-index: 1; grid-area: 1 / 1; color: #333a44; font-size: clamp(19px, 1.8vw, 23px); font-weight: 700; transform: rotate(90deg); }
.metric-time { font-size: clamp(30px, 2.7vw, 36px); font-weight: 720; letter-spacing: -.7px; }
.progress-summary { display: grid; align-content: center; gap: 6px; }
.daily-target { margin: 0; color: #647184; font-size: 15px; font-weight: 550; }
.daily-target strong { color: var(--app-accent-strong); font-size: 16px; font-weight: 700; }
.progress-content p { margin: 0; }
.weekly-card, .recent-card { min-height: 260px; padding: 22px 24px; }
.section-heading { align-items: flex-start; }
.section-heading h2 { font-size: 16px; }
.subtle-label { color: #9aa0a9; font-size: 12px; }
.weekly-total { display: block; margin-top: 10px; font-size: 25px; font-weight: 720; letter-spacing: -.5px; }
.text-action { padding: 6px 2px; border: 0; color: var(--accent); background: transparent; font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; }
.entry-list { margin-top: 14px; }
.entry-row { display: flex; min-height: 42px; align-items: center; gap: 10px; border-bottom: 1px solid #eef0f4; }
.entry-row:last-child { border-bottom: 0; }
.entry-dot { width: 8px; height: 8px; flex: 0 0 8px; border-radius: 50%; }
.entry-dot-work { background: var(--accent); }
.entry-dot-break { background: #f3b536; }
.entry-name { overflow: hidden; color: #343a44; font-size: 13px; text-overflow: ellipsis; white-space: nowrap; }
.entry-time { margin-left: auto; color: #8d949e; font-size: 12px; white-space: nowrap; }
.empty-state { display: grid; min-height: 180px; place-items: center; color: #9299a3; text-align: center; font-size: 14px; }
.compact-empty { min-height: 150px; font-size: 13px; }
.schedule-card { display: flex; min-height: 88px; align-items: center; gap: 15px; margin-top: 16px; padding: 16px 20px; }
.schedule-copy { display: grid; min-width: 0; gap: 3px; }
.schedule-copy .card-kicker { margin: 0; }
.schedule-copy strong { font-size: 14px; }
.schedule-copy small { color: #9299a3; font-size: 12px; }
.schedule-card .text-action { margin-left: auto; }
.notice { margin: -8px 0 18px; padding: 11px 14px; border-radius: 10px; font-size: 13px; }
.error-notice { color: #a83232; background: #fff0f0; }
.success-notice { color: #145f9f; background: #e8f3ff; }
.times-panel { padding: 24px; }
.times-table { margin-top: 18px; }
.times-table-head, .times-table-row { display: grid; grid-template-columns: .8fr 1fr 1fr 1fr .8fr; align-items: center; gap: 12px; min-height: 48px; border-bottom: 1px solid #eef0f4; font-size: 13px; }
.times-table-head { min-height: 36px; color: #9299a3; font-size: 11px; font-weight: 650; text-transform: uppercase; }
.times-table-row strong { font-weight: 650; }
.schedule-empty-card { display: grid; min-height: 300px; justify-items: center; align-content: center; padding: 28px; text-align: center; }
.large-tile { width: 58px; height: 58px; }
.large-tile svg { width: 26px; height: 26px; }
.schedule-empty-card h2 { margin: 18px 0 6px; font-size: 19px; }
.schedule-empty-card p, .profile-card p { margin: 0; color: #89919c; font-size: 14px; }
.profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; }
.profile-avatar { width: 62px; height: 62px; flex-basis: 62px; font-size: 19px; }
.profile-card h2 { margin: 0 0 6px; font-size: 18px; }
.profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid #e1e4e9; border-radius: 11px; color: #48515c; background: #fff; font: inherit; font-weight: 600; cursor: pointer; }
.bottom-navigation { display: none; }

@media (max-width: 999px) {
  .workspace-shell { display: block; padding-bottom: calc(76px + env(safe-area-inset-bottom)); }
  .sidebar { display: none; }
  .main-column { width: 100%; min-height: 100vh; margin: 0; }
  .topbar { height: 62px; padding: 0 19px; }
  .topbar-caption { font-size: 13px; }
  .topbar-user { gap: 9px; }
  .user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 12px; }
  .topbar-user-copy strong { font-size: 12px; }
  .topbar-user-copy small { font-size: 11px; }
  .logout-button { display: grid; }
  .page-content { padding: 24px 18px 30px; }
  .page-heading { align-items: center; margin-bottom: 20px; }
  .page-heading h1 { font-size: 27px; }
  .eyebrow { font-size: 11px; }
  .date-line { font-size: 13px; }
  .refresh-button { width: 40px; min-width: 40px; justify-content: center; padding: 0; }
  .refresh-button span { display: none; }
  .top-card-grid, .middle-card-grid { grid-template-columns: 1fr; gap: 12px; }
  .middle-card-grid { margin-top: 12px; }
  .card { border-radius: 19px; box-shadow: 0 5px 16px rgb(27 41 61 / 5%); }
  .current-card { min-height: auto; padding: 19px; }
  .today-card { min-height: 170px; padding: 19px; }
  .card h2 { font-size: 15px; }
  .icon-tile { width: 40px; height: 40px; flex-basis: 40px; border-radius: 12px; }
  .status-pill { padding: 6px 8px; font-size: 10px; }
  .current-time-row { align-items: center; margin-top: 24px; }
  .large-time { font-size: 34px; }
  .clock-button { min-width: 132px; min-height: 48px; padding: 0 15px; }
  .progress-content { gap: 18px; margin: 18px 0 0; }
  .weekly-card, .recent-card { min-height: auto; padding: 19px; }
  .schedule-card { min-height: 78px; gap: 12px; margin-top: 12px; padding: 14px; }
  .schedule-card .text-action { display: none; }
  .schedule-copy strong { font-size: 13px; }
  .bottom-navigation { position: fixed; right: 0; bottom: 0; left: 0; z-index: 5; display: grid; grid-template-columns: repeat(4, 1fr); padding: 8px 7px calc(8px + env(safe-area-inset-bottom)); border-top: 1px solid #e7e9ee; background: rgb(255 255 255 / 96%); backdrop-filter: blur(18px); }
  .bottom-nav-item { display: grid; min-height: 52px; justify-items: center; align-content: center; gap: 4px; border: 0; color: #838a95; background: transparent; font: inherit; font-size: 10px; cursor: pointer; }
  .bottom-nav-item svg { width: 20px; height: 20px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
  .bottom-nav-item.active { color: var(--accent); font-weight: 650; }
  .times-panel { padding: 19px; }
  .times-table-head { display: none; }
  .times-table-row { grid-template-columns: 1fr auto; gap: 4px 12px; padding: 10px 0; }
  .times-table-row span:first-child { grid-column: 1 / -1; color: #7d8691; font-size: 11px; }
  .times-table-row span:nth-child(2)::before { content: 'Date '; color: #9aa0a9; }
  .times-table-row span:nth-child(3)::before { content: 'Started '; color: #9aa0a9; }
  .times-table-row span:nth-child(4)::before { content: 'Ended '; color: #9aa0a9; }
  .times-table-row strong { grid-column: 2; grid-row: 2 / 4; }
  .schedule-empty-card { min-height: 260px; }
}

@media (max-width: 380px) {
  .page-content { padding-right: 13px; padding-left: 13px; }
  .current-card, .today-card, .weekly-card, .recent-card { padding: 16px; }
  .card-title-group { gap: 9px; }
  .status-pill { gap: 5px; font-size: 9px; }
  .current-time-row { align-items: flex-start; flex-direction: column; }
  .clock-actions { width: 100%; }
  .clock-actions .clock-button { min-width: 0; flex: 1; }
  .clock-actions .clock-button { width: auto; }
  .entry-row { gap: 7px; }
  .entry-time { font-size: 11px; }
}

@media (max-width: 560px) {
  .page-content { padding-top: 20px; padding-bottom: 22px; }
  .page-heading { margin-bottom: 17px; }
  .page-heading h1 { font-size: 29px; letter-spacing: -.8px; }
  .date-line { margin-top: 5px; font-size: 12px; }
  .topbar-caption { max-width: 38vw; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .topbar-user-copy strong { max-width: 42vw; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .topbar-user-copy small { display: none; }
  .current-time-row { align-items: flex-start; flex-direction: column; gap: 14px; }
  .clock-actions { width: 100%; }
  .clock-actions .clock-button { min-width: 0; min-height: 52px; flex: 1 1 0; padding: 0 10px; border-radius: 14px; font-size: 14px; }
  .current-card, .today-card, .weekly-card, .recent-card, .times-panel { border-radius: 21px; }
  .entry-row { min-height: 53px; }
  .entry-name { font-size: 14px; }
  .entry-time { font-size: 13px; }
  .text-action { font-size: 14px; }
  .progress-ring { --ring-size: 120px; }
  .metric-time { font-size: 32px; }
  .times-table-row { grid-template-columns: minmax(0, 1fr) auto; }
  .times-table-row strong { white-space: nowrap; }
}

/* Larger, easier-to-read employee dashboard controls and content. */
.topbar { height: 84px; }
.topbar-caption { font-size: 16px; }
.topbar-user-copy strong { font-size: 15px; }
.topbar-user-copy small { font-size: 13px; }
.page-heading { margin-bottom: 30px; }
.page-heading h1 { font-size: clamp(30px, 3.2vw, 40px); }
.date-line { font-size: 15px; }
.card { border-radius: 22px; }
.current-card, .today-card { min-height: 250px; padding: 28px; }
.card h2 { font-size: 19px; }
.card-kicker { font-size: 13px; }
.status-pill { padding: 9px 12px; font-size: 13px; }
.large-time { font-size: clamp(36px, 3.4vw, 46px); }
.clock-button { min-width: 164px; min-height: 56px; padding-inline: 22px; font-size: 16px; }
.metric-time { font-size: 32px; }
.metric-caption, .metric-percent { font-size: 14px; }
.weekly-card, .recent-card { min-height: 290px; padding: 27px 29px; }
.entry-row { min-height: 50px; gap: 12px; }
.entry-name { font-size: 15px; }
.entry-time { font-size: 14px; }
.text-action { font-size: 15px; }
.times-panel { padding: 28px; }
.times-table-head, .times-table-row { min-height: 56px; font-size: 15px; }
.times-table-head { font-size: 13px; }
.bottom-nav-item { min-height: 58px; font-size: 12px; }

@media (max-width: 999px) {
  .topbar { height: 70px; }
  .page-heading h1 { font-size: 32px; }
  .current-card, .today-card { min-height: 0; padding: 22px; }
  .weekly-card, .recent-card { min-height: 0; padding: 22px; }
  .clock-button { min-height: 54px; }
  .bottom-nav-item { min-height: 56px; font-size: 11px; }
}

@media (max-width: 560px) {
  .topbar { height: 62px; }
  .page-content { padding-top: 20px; padding-bottom: 24px; }
  .home-heading { padding-top: 24px; }
  .page-heading h1 { font-size: 30px; }
  .card h2 { font-size: 17px; }
  .large-time { font-size: 36px; }
  .clock-button { min-height: 54px; font-size: 15px; }
  .entry-row { min-height: 55px; }
  .times-panel { padding: 18px; }
}
</style>
