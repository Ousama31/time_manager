<template>
  <AppShell class="employee-dashboard" :navigation="navigation" :active-tab="activeTab" @navigate="activeTab = $event" @logout="disconnect">
    <EmployeeOverviewSection
      v-if="activeTab === 'home'"
      :greeting="greeting"
      :display-name="displayName"
      :today-label="todayLabel"
      :error-message="errorMessage"
      :success-message="successMessage"
      :clock-state="clockState"
      :clock-start="clockStart"
      :elapsed-label="elapsedLabel"
      :clock-busy="clockBusy"
      :user-id="userId"
      :today-progress="todayProgress"
      :today-hours-label="todayHoursLabel"
      :week-hours-label="weekHoursLabel"
      :week-days="weekDays"
      @toggle-clock="toggleClock"
      @toggle-break="toggleBreak"
    />
    <EmployeeTimesSection
      v-else-if="activeTab === 'times'"
      :loading="loading"
      :working-times="workingTimes"
      :sorted-working-times="sortedWorkingTimes"
      @refresh="loadDashboard"
    />
    <EmployeeFeedbackSection
      v-else-if="activeTab === 'feedback'"
      :profile="profile"
      v-model:feedback-subject="feedbackSubject"
      v-model:feedback-body="feedbackBody"
      :feedback-busy="feedbackBusy"
      :feedback-error="feedbackError"
      :feedback-success="feedbackSuccess"
      @send-feedback="sendFeedback"
    />
    <ProfileSection v-else variant="employee" role-label="Employee" :initials="initials" :display-name="displayName" :profile="profile" @logout="disconnect" />

        <p v-if="activeTab !== 'home' && errorMessage" class="notice error-notice" role="alert">{{ errorMessage }}</p>
  </AppShell>
</template>

<script>
/** @component Employee home workspace for clock and break actions, work-time history, feedback, and profile. Offline clock actions are queued for later synchronization. */
import api from '../../api'
import { getDisplayName, getInitials } from '../../utils/identity'
import EmployeeOverviewSection from './sections/EmployeeOverviewSection.vue'
import EmployeeTimesSection from './sections/EmployeeTimesSection.vue'
import EmployeeFeedbackSection from './sections/EmployeeFeedbackSection.vue'
import ProfileSection from '../shared/ProfileSection.vue'
import AppShell from '../dashboard/AppShell.vue'
import offlineSync from '../../offlineSync'
import { Haptics, ImpactStyle } from '@capacitor/haptics'
import { openEmailDraft } from '../../utils/emailDraft'
import { durationSeconds as calculateDurationSeconds, formatDuration as formatElapsedDuration, formatDate as formatLocalizedDate, formatTime as formatLocalizedTime } from '../../utils/time'
import { useEmployeeDashboard } from '../../composables/useEmployeeDashboard'

const employeeDashboard = useEmployeeDashboard()

const configuredAutoClockOutSeconds = Number(import.meta.env.VITE_AUTO_CLOCK_OUT_SECONDS)
const AUTO_CLOCK_OUT_SECONDS = configuredAutoClockOutSeconds > 0 ? configuredAutoClockOutSeconds : 8 * 60 * 60 // 8 hours

export default {
  name: 'Home',
  components: { AppShell, EmployeeOverviewSection, EmployeeTimesSection, EmployeeFeedbackSection, ProfileSection },
  /** Create reactive profile, clock, work-time, feedback, and offline-sync state for the employee view. */
  data() {
    return {
      userId: sessionStorage.getItem('userId') || localStorage.getItem('userId'),
      profile: {},
      workingTimes: [],
      clockState: 'off',
      clockStart: null,
      clockSessionStart: null,
      now: Date.now(),
      clockBusy: false,
      loading: false,
      activeTab: 'home',
      feedbackSubject: '',
      feedbackBody: '',
      feedbackBusy: false,
      feedbackError: '',
      feedbackSuccess: '',
      errorMessage: '',
      successMessage: '',
      tick: null,
      unsubscribeSync: null
    }
  },
  computed: {
    /** Define the employee sections shown in the shared dashboard navigation. */
    navigation() {
      return [
        { key: 'home', label: 'Home', icon: 'home' },
        { key: 'times', label: 'My Times', icon: 'times' },
        { key: 'feedback', label: 'Feedback', icon: 'message' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    /** Build the display name shown in the employee greeting and profile. */
    displayName() {
      return getDisplayName(this.profile, 'Welcome', ['username', 'name'])
    },
    /** Build initials for the employee profile avatar. */
    initials() {
      return getInitials(this.displayName)
    },
    /** Choose a greeting based on the current local hour. */
    greeting() {
      const hour = new Date(this.now).getHours()
      if (hour < 12) return 'Good morning,'
      if (hour < 18) return 'Good afternoon,'
      return 'Good evening,'
    },
    /** Format the current date for the home-page heading. */
    todayLabel() {
      return new Date(this.now).toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })
    },
    /** Select today’s completed work intervals, excluding breaks. */
    todayEntries() {
      const today = new Date(this.now).toDateString()
      return this.workingTimes.filter((entry) => entry.kind !== 'break' && new Date(entry.start).toDateString() === today)
    },
    /** Add completed work today to the currently running work interval, if any. */
    todaySeconds() {
      const completed = this.todayEntries.reduce((sum, entry) => sum + this.durationSeconds(entry.start, entry.end), 0)
      const live = this.clockState === 'working' && this.clockStart && new Date(this.clockStart).toDateString() === new Date(this.now).toDateString()
        ? Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))
        : 0
      return completed + live
    },
    /** Format today’s total work time for display. */
    todayHoursLabel() {
      return this.formatDuration(this.todaySeconds)
    },
    /** Calculate today’s progress toward the eight-hour target, capped at 100 percent. */
    todayProgress() {
      return Math.min(100, Math.round((this.todaySeconds / (8 * 3600)) * 100))
    },
    /** Format elapsed time since the current work or break state began. */
    elapsedLabel() {
      return this.clockStart ? this.formatDuration(Math.max(0, Math.floor((this.now - new Date(this.clockStart).getTime()) / 1000))) : '0h 00m'
    },
    /** Sort completed work and break entries newest first. */
    sortedWorkingTimes() {
      return [...this.workingTimes].sort((a, b) => new Date(b.start) - new Date(a.start))
    },
    /** Build the seven local calendar dates from Monday through Sunday for this week. */
    weekDates() {
      const today = new Date(this.now)
      const mondayOffset = (today.getDay() + 6) % 7
      const monday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - mondayOffset)
      return Array.from({ length: 7 }, (_, index) => new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + index))
    },
    /** Build the chart data for each day this week, including the active work interval. */
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
    /** Calculate and format this week’s total work time. */
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
  /** Load profile and time data, update the live clock display, and listen for offline-sync completion. */
  mounted() {
    this.loadProfile()
    this.loadDashboard()
    this.tick = window.setInterval(() => {
      this.now = Date.now()
      const sessionElapsed = this.clockSessionStart
        ? (this.now - new Date(this.clockSessionStart).getTime()) / 1000
        : 0

      if (this.clockState !== 'off' && !this.clockBusy && sessionElapsed >= AUTO_CLOCK_OUT_SECONDS) {
        this.toggleClock()
      }
    }, 1000)

    let wasSyncing = false
    this.unsubscribeSync = offlineSync.subscribe(({ isOnline, isSyncing, queueCount }) => {
      if (wasSyncing && !isSyncing && queueCount === 0) {
        this.loadDashboard()
      }
      wasSyncing = isSyncing
    })
  },
  /** Stop the live clock timer and unsubscribe from offline-sync updates. */
  beforeUnmount() {
    if (this.tick) window.clearInterval(this.tick)
    if (this.unsubscribeSync) this.unsubscribeSync()
  },
  methods: {
    /** Fetch the employee’s assigned manager and open a prefilled email draft. */
    async sendFeedback() {
      if (this.feedbackBusy || !this.feedbackBody.trim()) return
      this.feedbackBusy = true
      this.feedbackError = ''
      this.feedbackSuccess = ''
      try {
        const manager = await employeeDashboard.loadAssignedManager(this.userId)
        const result = openEmailDraft(manager.email, this.feedbackSubject, this.feedbackBody, 'Could not open an email draft. Please check your email app and try again.')
        this.feedbackError = result.error
        this.feedbackSuccess = result.success
      } catch (error) {
        this.feedbackError = error.response?.data?.error || 'Could not open an email draft. Please check your email app and try again.'
      } finally {
        this.feedbackBusy = false
      }
    },
    /** Load the employee profile from cache first, then refresh it from the API when online. */
    async loadProfile() {
      if (!this.userId) return
      const profile = await employeeDashboard.loadProfile(this.userId)
      if (profile) this.profile = profile
    },
    /** Load clock and interval data from cache/API and maintain the local clock-session start time. */
    async loadDashboard() {
      if (!this.userId) return
      this.loading = true
      this.errorMessage = ''

      try {
        const { clock, workingTimes, error, offline } = await employeeDashboard.loadTimeData(this.userId)
        if (clock) {
          this.clockState = clock.state || (clock.status ? 'working' : 'off')
          this.clockStart = this.clockState !== 'off' ? clock.time : null
        }
        if (Array.isArray(workingTimes)) this.workingTimes = workingTimes

        if (!offline && clock) {
          const sessionStartKey = `clockSessionStart:${this.userId}`
          if (this.clockState === 'off') {
            this.clockSessionStart = null
            sessionStorage.removeItem(sessionStartKey)
          } else {
            this.clockSessionStart = sessionStorage.getItem(sessionStartKey) || clock.time
            sessionStorage.setItem(sessionStartKey, this.clockSessionStart)
          }
        }
        if (error && !clock && !workingTimes) {
          this.errorMessage = 'We could not load your time data. Please try again.'
        }
      } finally {
        this.loading = false
      }
    },
    /** Clock in or out online, or queue the transition and completed interval for offline synchronization. */
    async toggleClock() {
      if (!this.userId || this.clockBusy) return
      this.clockBusy = true
      this.errorMessage = ''
      this.successMessage = ''

      try {
        Haptics.impact({ style: ImpactStyle.Medium })
      } catch {}

      const previousState = this.clockState
      const previousStart = this.clockState !== 'off' ? this.clockStart : null
      const nowIso = new Date().toISOString()

      if (!offlineSync.isOnline) {
        const sessionStartKey = `clockSessionStart:${this.userId}`
        if (previousState === 'off') {
          this.clockState = 'working'
          this.clockStart = nowIso
          this.clockSessionStart = nowIso
          sessionStorage.setItem(sessionStartKey, nowIso)
          offlineSync.saveLocalCache(`clock_${this.userId}`, { state: 'working', status: true, time: nowIso })
          offlineSync.enqueue({
            method: 'POST',
            url: `/clocks/${this.userId}`,
            data: { action: 'clock' }
          })
          this.successMessage = 'You are clocked in (offline mode, will sync when connected).'
        } else {
          this.clockState = 'off'
          this.clockStart = null
          this.clockSessionStart = null
          sessionStorage.removeItem(sessionStartKey)
          offlineSync.saveLocalCache(`clock_${this.userId}`, { state: 'off', status: false, time: null })
          offlineSync.enqueue({
            method: 'POST',
            url: `/clocks/${this.userId}`,
            data: { action: 'clock' }
          })
          if (previousStart) {
            const kind = previousState === 'break' ? 'break' : 'work'
            const newEntry = { id: `offline_${Date.now()}`, start: previousStart, end: nowIso, kind }
            this.workingTimes = [newEntry, ...this.workingTimes]
            offlineSync.saveLocalCache(`workingtimes_${this.userId}`, this.workingTimes)
            offlineSync.enqueue({
              method: 'POST',
              url: `/workingtime/${this.userId}`,
              data: { workingtime: { start: previousStart, end: nowIso, kind } }
            })
          }
          this.successMessage = 'Your work session has been saved (offline mode, will sync when connected).'
        }
        this.clockBusy = false
        return
      }

      try {
        const response = await employeeDashboard.submitClockAction(this.userId, 'clock')
        const clock = response.data.data
        this.clockState = clock?.state || (clock?.status ? 'working' : 'off')
        this.clockStart = this.clockState !== 'off' ? clock.time : null
        const sessionStartKey = `clockSessionStart:${this.userId}`
        if (this.clockState === 'off') {
          this.clockSessionStart = null
          sessionStorage.removeItem(sessionStartKey)
        } else if (previousState === 'off') {
          this.clockSessionStart = clock.time
          sessionStorage.setItem(sessionStartKey, clock.time)
        }
        offlineSync.saveLocalCache(`clock_${this.userId}`, clock)
        if (previousStart && this.clockState === 'off' && clock?.time) {
          await employeeDashboard.saveWorkingInterval(this.userId, { start: previousStart, end: clock.time, kind: previousState === 'break' ? 'break' : 'work' })
          await this.loadDashboard()
        }
        this.successMessage = this.clockState === 'working' ? 'You are clocked in. Have a focused day!' : 'Your work session has been saved.'
      } catch (error) {
        console.error('Could not update clock:', error)
        if (!error.response) {
          offlineSync.isOnline = false
          this.clockBusy = false
          return this.toggleClock()
        }
        this.errorMessage = 'We could not update your clock. Please try again.'
        this.loadDashboard()
      } finally {
        this.clockBusy = false
      }
    },
    /** Start or end a break online, or queue the transition and completed interval while offline. */
    async toggleBreak() {
      if (!this.userId || this.clockBusy || this.clockState === 'off') return
      this.clockBusy = true
      this.errorMessage = ''
      this.successMessage = ''

      try {
        Haptics.impact({ style: ImpactStyle.Light })
      } catch {}

      const previousState = this.clockState
      const previousStart = this.clockStart
      const nowIso = new Date().toISOString()

      if (!offlineSync.isOnline) {
        const nextState = previousState === 'break' ? 'working' : 'break'
        this.clockState = nextState
        this.clockStart = nowIso
        offlineSync.saveLocalCache(`clock_${this.userId}`, { state: nextState, status: true, time: nowIso })
        offlineSync.enqueue({
          method: 'POST',
          url: `/clocks/${this.userId}`,
          data: { action: 'break' }
        })

        if (previousStart) {
          const kind = previousState === 'working' ? 'work' : 'break'
          const newEntry = { id: `offline_${Date.now()}`, start: previousStart, end: nowIso, kind }
          this.workingTimes = [newEntry, ...this.workingTimes]
          offlineSync.saveLocalCache(`workingtimes_${this.userId}`, this.workingTimes)
          offlineSync.enqueue({
            method: 'POST',
            url: `/workingtime/${this.userId}`,
            data: { workingtime: { start: previousStart, end: nowIso, kind } }
          })
        }

        this.successMessage = nextState === 'break'
          ? 'Break started (offline mode, will sync when connected).'
          : 'Break ended. Your work session resumed (offline mode, will sync).'
        this.clockBusy = false
        return
      }

      try {
        const response = await employeeDashboard.submitClockAction(this.userId, 'break')
        const clock = response.data.data
        this.clockState = clock?.state || (clock?.status ? 'working' : 'off')
        this.clockStart = this.clockState !== 'off' ? clock.time : null
        offlineSync.saveLocalCache(`clock_${this.userId}`, clock)

        if (previousStart && clock?.time) {
          const kind = previousState === 'working' ? 'work' : 'break'
          await employeeDashboard.saveWorkingInterval(this.userId, { start: previousStart, end: clock.time, kind })
          await this.loadDashboard()
        }
        this.successMessage = this.clockState === 'break' ? 'Break started. Take a moment to recharge.' : 'Break ended. Your work session has resumed.'
      } catch (error) {
        console.error('Could not update break:', error)
        if (!error.response) {
          offlineSync.isOnline = false
          this.clockBusy = false
          return this.toggleBreak()
        }
        this.errorMessage = 'We could not update your break. Please try again.'
        this.loadDashboard()
      } finally {
        this.clockBusy = false
      }
    },
    /** Sign out through the API, clear saved session data, and navigate to sign-in. */
    async disconnect() {
      try {
        await api.post('/users/sign_out')
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        sessionStorage.clear()
        localStorage.removeItem('xsrfToken')
        localStorage.removeItem('userId')
        localStorage.removeItem('role')
        this.$router.push('/login')
      }
    },
    /** Return a non-negative interval duration in seconds, or zero for incomplete/invalid dates. */
    durationSeconds(start, end) {
      return calculateDurationSeconds(start, end)
    },
    /** Format a duration in seconds as hours and zero-padded minutes. */
    formatDuration(seconds) {
      return formatElapsedDuration(seconds)
    },
    /** Calculate and format the duration between two timestamps. */
    durationLabel(start, end) {
      return this.formatDuration(this.durationSeconds(start, end))
    },
    /** Format a timestamp as a localized hour and minute, or an em dash when missing. */
    formatTime(value) {
      return formatLocalizedTime(value)
    },
    /** Format a timestamp as a localized month, day, and year, or an em dash when missing. */
    formatDate(value) {
      return formatLocalizedDate(value)
    }
  }
}
</script>

<style>
.employee-dashboard .workspace-shell { --accent: var(--app-accent); --ink: var(--app-text); --muted: var(--app-muted); --line: #e5eae6; display: flex; min-height: 100vh; color: var(--ink); background: var(--app-background); font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif; }
.employee-dashboard .sidebar { position: fixed; inset: 0 auto 0 0; z-index: 4; display: flex; width: 248px; flex-direction: column; padding: 24px 16px; color: #fff; background: #102c4b; }
.employee-dashboard .brand-lockup { display: flex; height: 54px; align-items: center; gap: 12px; padding: 0 8px; font-size: 18px; font-weight: 700; letter-spacing: -.3px; }
.employee-dashboard .brand-mark { display: grid; width: 40px; height: 40px; place-items: center; border-radius: 12px; background: var(--accent); }
.employee-dashboard .brand-mark svg { width: 24px; stroke: #fff; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.employee-dashboard .side-navigation { display: grid; gap: 7px; margin-top: 42px; }
.employee-dashboard .nav-item { position: relative; display: flex; min-height: 48px; align-items: center; gap: 13px; padding: 0 14px; border: 0; border-radius: 12px; color: #aebed0; background: transparent; text-align: left; font: inherit; font-size: 14px; cursor: pointer; }
.employee-dashboard .nav-item.active { color: #f2f8ff; background: #183d62; }
.employee-dashboard .nav-item.active::after { position: absolute; top: 11px; right: 0; width: 3px; height: 26px; border-radius: 4px; background: #76baff; content: ''; }
.employee-dashboard .sidebar-logout { display: flex; align-items: center; gap: 12px; margin: auto 0 4px; padding: 12px 14px; border: 0; color: #adbdce; background: none; text-align: left; font: inherit; cursor: pointer; }
.employee-dashboard .sidebar-logout svg, .employee-dashboard .logout-button svg { width: 19px; height: 19px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.employee-dashboard .main-column { width: calc(100% - 248px); min-width: 0; min-height: 100vh; margin-left: 248px; }
.employee-dashboard .topbar { position: sticky; top: 0; z-index: 3; display: flex; height: 76px; align-items: center; justify-content: space-between; padding: 0 clamp(28px, 4vw, 64px); border-bottom: 1px solid #e9ebf0; background: rgb(255 255 255 / 96%); backdrop-filter: blur(16px); }
.employee-dashboard .topbar-caption { color: #7e8792; font-size: 14px; }
.employee-dashboard .topbar-user { display: flex; align-items: center; gap: 12px; }
.employee-dashboard .user-avatar { display: grid; width: 42px; height: 42px; flex: 0 0 42px; place-items: center; border-radius: 50%; color: #fff; background: var(--accent); font-size: 14px; font-weight: 700; }
.employee-dashboard .topbar-user-copy { display: grid; gap: 2px; }
.employee-dashboard .topbar-user-copy strong { font-size: 13px; }
.employee-dashboard .topbar-user-copy small { color: #8c929b; font-size: 12px; }
.employee-dashboard .logout-button { display: none; width: 38px; height: 38px; place-items: center; margin-left: 8px; border: 0; border-radius: 10px; color: #747c86; background: #f4f5f8; cursor: pointer; }
.employee-dashboard .page-content { width: min(100%, 1500px); margin: 0 auto; padding: 36px clamp(28px, 4vw, 64px) 52px; }
.employee-dashboard .status-pill { display: inline-flex; flex: 0 0 auto; align-items: center; gap: 7px; padding: 7px 10px; border-radius: 999px; font-size: 11px; font-weight: 650; }
.employee-dashboard .status-pill i { width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
.employee-dashboard .status-working { color: #16804a; background: #e9f8ef; }
.employee-dashboard .status-break { color: #946200; background: #fff4d8; }
.employee-dashboard .status-idle { color: #717986; background: #f0f2f5; }
.employee-dashboard .text-action { padding: 6px 2px; border: 0; color: var(--accent); background: transparent; font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; }
.employee-dashboard .entry-list { margin-top: 14px; }
.employee-dashboard .entry-row { display: flex; min-height: 42px; align-items: center; gap: 10px; border-bottom: 1px solid #eef0f4; }
.employee-dashboard .entry-row:last-child { border-bottom: 0; }
.employee-dashboard .entry-dot { width: 8px; height: 8px; flex: 0 0 8px; border-radius: 50%; }
.employee-dashboard .entry-dot-work { background: var(--accent); }
.employee-dashboard .entry-dot-break { background: #f3b536; }
.employee-dashboard .entry-name { overflow: hidden; color: #343a44; font-size: 13px; text-overflow: ellipsis; white-space: nowrap; }
.employee-dashboard .entry-time { margin-left: auto; color: #8d949e; font-size: 12px; white-space: nowrap; }
.employee-dashboard .compact-empty { min-height: 150px; font-size: 13px; }
.employee-dashboard .schedule-card { display: flex; min-height: 88px; align-items: center; gap: 15px; margin-top: 16px; padding: 16px 20px; }
.employee-dashboard .schedule-copy { display: grid; min-width: 0; gap: 3px; }
.employee-dashboard .schedule-copy strong { font-size: 14px; }
.employee-dashboard .schedule-copy small { color: #9299a3; font-size: 12px; }
.employee-dashboard .schedule-card .text-action { margin-left: auto; }
.employee-dashboard .notice { margin: -8px 0 18px; padding: 11px 14px; border-radius: 10px; font-size: 13px; }
.employee-dashboard .error-notice { color: #a83232; background: #fff0f0; }
.employee-dashboard .schedule-empty-card { display: grid; min-height: 300px; justify-items: center; align-content: center; padding: 28px; text-align: center; }
.employee-dashboard .large-tile { width: 58px; height: 58px; }
.employee-dashboard .large-tile svg { width: 26px; height: 26px; }
.employee-dashboard .schedule-empty-card h2 { margin: 18px 0 6px; font-size: 19px; }
.employee-dashboard .bottom-navigation { display: none; }
  .employee-dashboard .workspace-shell { display: block; padding-bottom: calc(76px + env(safe-area-inset-bottom)); }
  .employee-dashboard .sidebar { display: none; }
  .employee-dashboard .main-column { width: 100%; min-height: 100vh; margin: 0; }
  .employee-dashboard .topbar { height: 62px; padding: 0 19px; }
  .employee-dashboard .topbar-caption { font-size: 13px; }
  .employee-dashboard .topbar-user { gap: 9px; }
  .employee-dashboard .user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 12px; }
  .employee-dashboard .topbar-user-copy strong { font-size: 12px; }
  .employee-dashboard .topbar-user-copy small { font-size: 11px; }
  .employee-dashboard .logout-button { display: grid; }
  .employee-dashboard .page-content { padding: 24px 18px 30px; }
  .employee-dashboard .status-pill { padding: 6px 8px; font-size: 10px; }
  .employee-dashboard .schedule-card { min-height: 78px; gap: 12px; margin-top: 12px; padding: 14px; }
  .employee-dashboard .schedule-card .text-action { display: none; }
  .employee-dashboard .schedule-copy strong { font-size: 13px; }
  .employee-dashboard .bottom-navigation { position: fixed; right: 0; bottom: 0; left: 0; z-index: 5; display: grid; grid-template-columns: repeat(4, 1fr); padding: 8px 7px calc(8px + env(safe-area-inset-bottom)); border-top: 1px solid #e7e9ee; background: rgb(255 255 255 / 96%); backdrop-filter: blur(18px); }
  .employee-dashboard .bottom-nav-item { display: grid; min-height: 52px; justify-items: center; align-content: center; gap: 4px; border: 0; color: #838a95; background: transparent; font: inherit; font-size: 10px; cursor: pointer; }
  .employee-dashboard .bottom-nav-item svg { width: 20px; height: 20px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
  .employee-dashboard .bottom-nav-item.active { color: var(--accent); font-weight: 650; }
  .employee-dashboard .schedule-empty-card { min-height: 260px; }
  .employee-dashboard .page-content { padding-right: 13px; padding-left: 13px; }
  .employee-dashboard .status-pill { gap: 5px; font-size: 9px; }
  .employee-dashboard .entry-row { gap: 7px; }
  .employee-dashboard .entry-time { font-size: 11px; }
  .employee-dashboard .page-content { padding-top: 20px; padding-bottom: 22px; }
  .employee-dashboard .topbar-caption { max-width: 38vw; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .employee-dashboard .topbar-user-copy strong { max-width: 42vw; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .employee-dashboard .topbar-user-copy small { display: none; }
  .employee-dashboard .entry-row { min-height: 53px; }
  .employee-dashboard .entry-name { font-size: 14px; }
  .employee-dashboard .entry-time { font-size: 13px; }
  .employee-dashboard .text-action { font-size: 14px; }
.employee-dashboard .topbar { height: 84px; }
.employee-dashboard .topbar-caption { font-size: 16px; }
.employee-dashboard .topbar-user-copy strong { font-size: 15px; }
.employee-dashboard .topbar-user-copy small { font-size: 13px; }
.employee-dashboard .status-pill { padding: 9px 12px; font-size: 13px; }
.employee-dashboard .metric-caption, .employee-dashboard .metric-percent { font-size: 14px; }
.employee-dashboard .entry-row { min-height: 50px; gap: 12px; }
.employee-dashboard .entry-name { font-size: 15px; }
.employee-dashboard .entry-time { font-size: 14px; }
.employee-dashboard .text-action { font-size: 15px; }
.employee-dashboard .bottom-nav-item { min-height: 58px; font-size: 12px; }
  .employee-dashboard .topbar { height: 70px; }
  .employee-dashboard .bottom-nav-item { min-height: 56px; font-size: 11px; }
  .employee-dashboard .topbar { height: 62px; }
  .employee-dashboard .page-content { padding-top: 20px; padding-bottom: 24px; }
  .employee-dashboard .entry-row { min-height: 55px; }
</style>
