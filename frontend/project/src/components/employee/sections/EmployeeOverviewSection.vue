<template>

          <div class="page-heading home-heading dashboard-heading">
            <div>
              <p class="eyebrow dashboard-eyebrow">{{ greeting }}</p>
              <h1 class="dashboard-title">{{ displayName }} <span aria-hidden="true">👋</span></h1>
              <p class="date-line dashboard-description">{{ todayLabel }}</p>
            </div>
          </div>

          <p v-if="errorMessage" class="notice error-notice" role="alert">{{ errorMessage }}</p>
          <p v-if="successMessage" class="notice success-notice" role="status">{{ successMessage }}</p>

          <section class="top-card-grid" aria-label="Today's work overview">
            <article class="card current-card dashboard-surface">
              <div class="card-heading-row">
                <div class="card-title-group"><span class="icon-tile accent-tile"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><div><p class="card-kicker">Current working time</p><h2>{{ clockState === 'working' ? 'You are working' : clockState === 'break' ? 'You are on break' : 'You are clocked out' }}</h2></div></div>
                <span :class="['status-pill', clockState === 'working' ? 'status-working' : clockState === 'break' ? 'status-break' : 'status-idle']"><i></i>{{ clockState === 'working' ? 'Working' : clockState === 'break' ? 'On break' : 'Not working' }}</span>
              </div>
              <div class="current-time-row">
                <div><strong class="large-time">{{ clockState !== 'off' ? elapsedLabel : '—' }}</strong><span class="muted-line">{{ clockState !== 'off' ? `${clockState === 'break' ? 'Break started' : 'Working since'} ${formatTime(clockStart)}` : 'Clock in to start your day' }}</span></div>
                <div class="clock-actions">
                  <button class="clock-button" :disabled="clockBusy || !userId" @click="$emit('toggle-clock')">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg>
                    {{ clockBusy ? 'Saving…' : clockState === 'off' ? 'Clock In' : 'Clock Out' }}
                  </button>
                  <button v-if="clockState !== 'off'" class="clock-button break-button" :disabled="clockBusy || !userId" @click="$emit('toggle-break')">
                    {{ clockBusy ? 'Saving…' : clockState === 'break' ? 'End Break' : 'Break' }}
                  </button>
                </div>
              </div>
            </article>

            <article class="card today-card dashboard-surface">
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
            <article class="card weekly-card dashboard-surface">
              <div class="section-heading"><div><p class="card-kicker">Your overview</p><h2>Weekly hours</h2></div><span class="subtle-label">This week</span></div>
              <strong class="weekly-total">{{ weekHoursLabel }}</strong>
              <WeeklyHoursChart :days="weekDays" :label="`Weekly work hours: ${weekHoursLabel}`" />
            </article>
          </section>


</template>

<script>
import WeeklyHoursChart from '../../dashboard/WeeklyHoursChart.vue'
import { formatTime } from '../../../utils/time'
export default {
  name: 'EmployeeOverviewSection',
  components: { WeeklyHoursChart },
  props: {
    greeting: { type: String, required: true },
    displayName: { type: String, required: true },
    todayLabel: { type: String, required: true },
    errorMessage: { type: String, default: '' },
    successMessage: { type: String, default: '' },
    clockState: { type: String, required: true },
    clockStart: { type: [String, Date], default: null },
    elapsedLabel: { type: String, required: true },
    clockBusy: { type: Boolean, required: true },
    userId: { type: [String, Number], default: '' },
    todayProgress: { type: Number, required: true },
    todayHoursLabel: { type: String, required: true },
    weekHoursLabel: { type: String, required: true },
    weekDays: { type: Array, required: true }
  },
  methods: { formatTime }
}
</script>

<style>
.employee-dashboard .page-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 18px; margin-bottom: 26px; }
.employee-dashboard .eyebrow, .employee-dashboard .card-kicker { margin: 0 0 7px; color: #8b929d; font-size: 12px; font-weight: 650; letter-spacing: .04em; text-transform: uppercase; }
.employee-dashboard .page-heading h1 { margin: 0; color: #20242c; font-size: clamp(26px, 3vw, 34px); font-weight: 720; letter-spacing: -.8px; }
.employee-dashboard .date-line { margin: 8px 0 0; color: #8b929d; font-size: 14px; }
.employee-dashboard .top-card-grid { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(280px, .8fr); gap: 16px; }
.employee-dashboard .middle-card-grid { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(300px, .8fr); gap: 16px; margin-top: 16px; }
.employee-dashboard .card { min-width: 0; border: 1px solid #eceef2; border-radius: 20px; background: #fff; box-shadow: 0 6px 20px rgb(27 41 61 / 5%); }
.employee-dashboard .current-card, .employee-dashboard .today-card { min-height: 226px; padding: 24px; }
.employee-dashboard .card-heading-row, .employee-dashboard .section-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.employee-dashboard .card-title-group { display: flex; min-width: 0; align-items: center; gap: 13px; }
.employee-dashboard .icon-tile { display: grid; width: 44px; height: 44px; flex: 0 0 44px; place-items: center; border-radius: 13px; }
.employee-dashboard .icon-tile svg { width: 21px; height: 21px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.employee-dashboard .accent-tile { color: #fff; background: var(--accent); }
.employee-dashboard .pale-tile { color: var(--accent); background: var(--app-accent-soft); }
.employee-dashboard .card-kicker { margin-bottom: 4px; }
.employee-dashboard .card h2 { margin: 0; font-size: 16px; font-weight: 650; letter-spacing: -.15px; }
.employee-dashboard .current-time-row { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-top: 28px; }
.employee-dashboard .current-time-row > div { display: grid; gap: 5px; }
.employee-dashboard .large-time { color: #20242c; font-size: clamp(32px, 4vw, 42px); font-weight: 740; letter-spacing: -1.7px; line-height: 1; }
.employee-dashboard .muted-line { color: #8b929d; font-size: 13px; }
.employee-dashboard .clock-actions { display: flex; align-items: center; gap: 10px; }
.employee-dashboard .current-time-row > .clock-actions { display: flex; gap: 10px; }
.employee-dashboard .clock-button { display: inline-flex; min-width: 144px; min-height: 48px; align-items: center; justify-content: center; gap: 9px; padding: 0 19px; border: 0; border-radius: 12px; color: #fff; background: var(--accent); font: inherit; font-size: 14px; font-weight: 650; box-shadow: 0 5px 12px rgb(22 132 248 / 18%); cursor: pointer; }
.employee-dashboard .clock-button:disabled { opacity: .55; cursor: not-allowed; }
.employee-dashboard .clock-button.break-button { color: #745000; background: #f3b536; box-shadow: 0 5px 12px rgb(243 181 54 / 18%); }
.employee-dashboard .clock-button.break-button:hover:not(:disabled) { background: #e8a91d; }
.employee-dashboard .clock-button svg { width: 18px; height: 18px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.employee-dashboard .today-card { display: flex; flex-direction: column; justify-content: space-between; }
.employee-dashboard .today-card .card-kicker { margin-bottom: 5px; }
.employee-dashboard .progress-content { display: flex; align-items: center; gap: clamp(18px, 2.5vw, 30px); margin: 12px 0 2px; }
.employee-dashboard .progress-ring { --ring-size: clamp(116px, 10.5vw, 140px); display: grid; width: var(--ring-size); height: var(--ring-size); flex: 0 0 var(--ring-size); place-items: center; border-radius: 50%; background: conic-gradient(var(--accent) var(--progress), #e6e9ee 0); transform: rotate(-90deg); }
.employee-dashboard .progress-ring::before { grid-area: 1 / 1; width: calc(var(--ring-size) - 28px); height: calc(var(--ring-size) - 28px); border-radius: 50%; background: #fff; content: ''; }
.employee-dashboard .progress-ring span { z-index: 1; grid-area: 1 / 1; color: #333a44; font-size: clamp(19px, 1.8vw, 23px); font-weight: 700; transform: rotate(90deg); }
.employee-dashboard .metric-time { font-size: clamp(30px, 2.7vw, 36px); font-weight: 720; letter-spacing: -.7px; }
.employee-dashboard .progress-summary { display: grid; align-content: center; gap: 6px; }
.employee-dashboard .daily-target { margin: 0; color: #647184; font-size: 15px; font-weight: 550; }
.employee-dashboard .daily-target strong { color: var(--app-accent-strong); font-size: 16px; font-weight: 700; }
.employee-dashboard .progress-content p { margin: 0; }
.employee-dashboard .weekly-card, .employee-dashboard .recent-card { min-height: 260px; padding: 22px 24px; }
.employee-dashboard .section-heading { align-items: flex-start; }
.employee-dashboard .section-heading h2 { font-size: 16px; }
.employee-dashboard .subtle-label { color: #9aa0a9; font-size: 12px; }
.employee-dashboard .weekly-total { display: block; margin-top: 10px; font-size: 25px; font-weight: 720; letter-spacing: -.5px; }
.employee-dashboard .schedule-copy .card-kicker { margin: 0; }
.employee-dashboard .success-notice { color: #145f9f; background: #e8f3ff; }
  .employee-dashboard .page-heading { align-items: center; margin-bottom: 20px; }
  .employee-dashboard .page-heading h1 { font-size: 27px; }
  .employee-dashboard .eyebrow { font-size: 11px; }
  .employee-dashboard .date-line { font-size: 13px; }
  .employee-dashboard .top-card-grid, .employee-dashboard .middle-card-grid { grid-template-columns: 1fr; gap: 12px; }
  .employee-dashboard .middle-card-grid { margin-top: 12px; }
  .employee-dashboard .card { border-radius: 19px; box-shadow: 0 5px 16px rgb(27 41 61 / 5%); }
  .employee-dashboard .current-card { min-height: auto; padding: 19px; }
  .employee-dashboard .today-card { min-height: 170px; padding: 19px; }
  .employee-dashboard .card h2 { font-size: 15px; }
  .employee-dashboard .icon-tile { width: 40px; height: 40px; flex-basis: 40px; border-radius: 12px; }
  .employee-dashboard .current-time-row { align-items: center; margin-top: 24px; }
  .employee-dashboard .large-time { font-size: 34px; }
  .employee-dashboard .clock-button { min-width: 132px; min-height: 48px; padding: 0 15px; }
  .employee-dashboard .progress-content { gap: 18px; margin: 18px 0 0; }
  .employee-dashboard .weekly-card, .employee-dashboard .recent-card { min-height: auto; padding: 19px; }
  .employee-dashboard .current-card, .employee-dashboard .today-card, .employee-dashboard .weekly-card, .employee-dashboard .recent-card { padding: 16px; }
  .employee-dashboard .card-title-group { gap: 9px; }
  .employee-dashboard .current-time-row { align-items: flex-start; flex-direction: column; }
  .employee-dashboard .clock-actions { width: 100%; }
  .employee-dashboard .clock-actions .clock-button { min-width: 0; flex: 1; }
  .employee-dashboard .clock-actions .clock-button { width: auto; }
  .employee-dashboard .page-heading { margin-bottom: 17px; }
  .employee-dashboard .page-heading h1 { font-size: 29px; letter-spacing: -.8px; }
  .employee-dashboard .date-line { margin-top: 5px; font-size: 12px; }
  .employee-dashboard .current-time-row { align-items: flex-start; flex-direction: column; gap: 14px; }
  .employee-dashboard .clock-actions { width: 100%; }
  .employee-dashboard .clock-actions .clock-button { min-width: 0; min-height: 52px; flex: 1 1 0; padding: 0 10px; border-radius: 14px; font-size: 14px; }
  .employee-dashboard .current-card, .employee-dashboard .today-card, .employee-dashboard .weekly-card, .employee-dashboard .recent-card, .employee-dashboard .times-panel { border-radius: 21px; }
  .employee-dashboard .progress-ring { --ring-size: 120px; }
  .employee-dashboard .metric-time { font-size: 32px; }
.employee-dashboard .page-heading { margin-bottom: 30px; }
.employee-dashboard .page-heading h1 { font-size: clamp(30px, 3.2vw, 40px); }
.employee-dashboard .date-line { font-size: 15px; }
.employee-dashboard .card { border-radius: 22px; }
.employee-dashboard .current-card, .employee-dashboard .today-card { min-height: 250px; padding: 28px; }
.employee-dashboard .card h2 { font-size: 19px; }
.employee-dashboard .card-kicker { font-size: 13px; }
.employee-dashboard .large-time { font-size: clamp(36px, 3.4vw, 46px); }
.employee-dashboard .clock-button { min-width: 164px; min-height: 56px; padding-inline: 22px; font-size: 16px; }
.employee-dashboard .metric-time { font-size: 32px; }
.employee-dashboard .weekly-card, .employee-dashboard .recent-card { min-height: 290px; padding: 27px 29px; }
  .employee-dashboard .page-heading h1 { font-size: 32px; }
  .employee-dashboard .current-card, .employee-dashboard .today-card { min-height: 0; padding: 22px; }
  .employee-dashboard .weekly-card, .employee-dashboard .recent-card { min-height: 0; padding: 22px; }
  .employee-dashboard .clock-button { min-height: 54px; }
  .employee-dashboard .home-heading { padding-top: 24px; }
  .employee-dashboard .page-heading h1 { font-size: 30px; }
  .employee-dashboard .card h2 { font-size: 17px; }
  .employee-dashboard .large-time { font-size: 36px; }
  .employee-dashboard .clock-button { min-height: 54px; font-size: 15px; }
</style>
