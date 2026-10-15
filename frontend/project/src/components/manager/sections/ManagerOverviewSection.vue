<template>
        <section id="dashboard" class="dashboard-section">
          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">TEAM OVERVIEW</p><h1 class="dashboard-title">Statistics</h1><p class="page-subtitle dashboard-description">Attendance and working times for your team.</p></div></div>

          <div v-if="loadError" class="load-error" role="alert">{{ loadError }} <button @click="$emit('retry')">Try again</button></div>

          <article class="insight-card live-card live-card-top dashboard-surface"><h2>Live team status</h2><p class="live-count"><strong>{{ clockedInCount }}</strong><span>of {{ activeTeamCount }} active members working</span></p><div class="live-progress" role="progressbar" :aria-valuenow="clockedInCount" :aria-valuemin="0" :aria-valuemax="activeTeamCount || 1"><span :style="{ width: `${clockedInPercent}%` }"></span></div><div class="live-legend"><span><i class="dot-working"></i>Working <strong>{{ clockedInCount }}</strong></span><span><i class="dot-break"></i>Break <strong>{{ onBreakCount }}</strong></span><span><i class="dot-off"></i>Off <strong>{{ offClockCount }}</strong></span></div></article>

          <section class="summary-grid" aria-label="Team summary">
            <article class="summary-card dashboard-surface"><span class="summary-icon icon-blue"><svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M16 5.5a3.2 3.2 0 0 1 0 6.2M17 14a5 5 0 0 1 3.5 4.8"/></svg></span><strong>{{ team.length }}</strong><span>Team members</span></article>
            <article class="summary-card dashboard-surface"><span class="summary-icon icon-green"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><strong>{{ clockedInCount }}</strong><span>Clocked in now</span></article>
            <article class="summary-card dashboard-surface"><span class="summary-icon icon-amber"><svg viewBox="0 0 24 24"><path d="M9 5v14M15 5v14"/></svg></span><strong>{{ onBreakCount }}</strong><span>On break</span></article>
            <article class="summary-card dashboard-surface"><span class="summary-icon icon-amber"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><strong>{{ formatMinutes(todayTeamMinutes) }}</strong><span>Team hours today</span></article>
          </section>

          <section class="insights-grid" aria-label="Working time overview">
            <article class="insight-card hours-card dashboard-surface"><div class="insight-heading"><div><h2>Team working hours</h2><p>This week</p></div><strong>{{ formatMinutes(weekTeamMinutes) }}</strong></div>
              <WeeklyHoursChart variant="manager" :days="weekBars" :label="`Team hours this week: ${formatMinutes(weekTeamMinutes)}`" />
            </article>
          </section>

        </section>
</template>

<script>
import WeeklyHoursChart from '../../dashboard/WeeklyHoursChart.vue'
import { formatMinutes } from '../../../utils/time'
export default {
  name: 'ManagerOverviewSection',
  components: { WeeklyHoursChart },
  props: {
    loadError: { type: String, default: '' },
    clockedInCount: { type: Number, required: true },
    activeTeamCount: { type: Number, required: true },
    clockedInPercent: { type: Number, required: true },
    onBreakCount: { type: Number, required: true },
    offClockCount: { type: Number, required: true },
    team: { type: Array, required: true },
    todayTeamMinutes: { type: Number, required: true },
    weekTeamMinutes: { type: Number, required: true },
    weekBars: { type: Array, required: true }
  },
  methods: { formatMinutes }
}
</script>

<style>
.manager-dashboard .manager-profile-section .page-heading { margin-bottom: 20px; }
.manager-dashboard .manager-profile-section .page-heading h1 { font-size: 28px; }
.manager-dashboard .page-heading { margin-bottom: 17px; }
.manager-dashboard .eyebrow { margin: 0 0 5px; color: #8290a1; font-size: 8px; font-weight: 750; letter-spacing: 1px; }
.manager-dashboard .page-heading h1 { margin: 0; color: #1f2937; font-size: 23px; font-weight: 740; letter-spacing: -.55px; }
.manager-dashboard .page-subtitle { margin: 5px 0 0; color: #8994a3; font-size: 10px; }
.manager-dashboard .load-error { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 14px; padding: 10px 12px; border: 1px solid #f0c9c9; border-radius: 7px; color: #a33636; background: #fff4f4; font-size: 10px; }
.manager-dashboard .load-error button { border: 0; color: #a33636; background: none; font: inherit; font-weight: 700; cursor: pointer; }
.manager-dashboard .summary-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 11px; margin-bottom: 12px; }
.manager-dashboard .summary-card { display: grid; min-height: 116px; align-content: start; justify-items: start; padding: 14px; border: 1px solid #eceef2; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); }
.manager-dashboard .summary-icon { display: grid; width: 29px; height: 29px; place-items: center; margin-bottom: 10px; border-radius: 8px; }
.manager-dashboard .summary-icon svg { width: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.manager-dashboard .icon-blue { color: #1683f8; background: #eaf3ff; }
.manager-dashboard .icon-green { color: #25bd5a; background: #eaf9ee; }
.manager-dashboard .icon-amber { color: #f29a20; background: #fff5e7; }
.manager-dashboard .summary-card > strong { color: #202936; font-size: 21px; font-weight: 730; letter-spacing: -.45px; }
.manager-dashboard .summary-card > span:last-child { margin-top: 3px; color: #929baa; font-size: 9px; }
.manager-dashboard .insights-grid { display: grid; grid-template-columns: minmax(0, 1.55fr) minmax(245px, 1fr); gap: 12px; margin-bottom: 13px; }
.manager-dashboard .insight-card { min-height: 154px; padding: 16px 18px; border: 1px solid #eceef2; border-radius: 11px; background: white; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); }
.manager-dashboard .insight-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.manager-dashboard .insight-heading h2, .manager-dashboard .live-card h2 { margin: 0; color: #303a49; font-size: 11px; font-weight: 700; }
.manager-dashboard .insight-heading p { margin: 4px 0 0; color: #929baa; font-size: 9px; }
.manager-dashboard .insight-heading > strong { color: #202936; font-size: 18px; font-weight: 730; }
.manager-dashboard .live-card { display: flex; flex-direction: column; justify-content: center; }
.manager-dashboard .live-count { display: flex; align-items: baseline; gap: 7px; margin: 13px 0 9px; }
.manager-dashboard .live-count strong { color: #202936; font-size: 24px; font-weight: 730; }
.manager-dashboard .live-count span { color: #929baa; font-size: 9px; }
.manager-dashboard .live-progress { height: 7px; overflow: hidden; border-radius: 9px; background: #edf0f4; }
.manager-dashboard .live-progress span { display: block; height: 100%; border-radius: inherit; background: #31c765; transition: width .2s ease; }
.manager-dashboard .live-legend { display: flex; justify-content: space-between; gap: 10px; margin-top: 12px; color: #7f8998; font-size: 8px; }
.manager-dashboard .live-legend span { display: flex; align-items: center; gap: 5px; }
.manager-dashboard .live-legend strong { color: #495565; }
.manager-dashboard .live-legend i { width: 7px; height: 7px; border-radius: 50%; }
.manager-dashboard .dot-working { background: #31c765; }
.manager-dashboard .dot-break { background: #f2a52b; }
.manager-dashboard .dot-off { background: #c4cad3; }
.manager-dashboard .team-directory-section > .page-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 18px; }
.manager-dashboard .eyebrow { font-size: 10px; }
.manager-dashboard .page-heading h1 { color: var(--app-text); font-size: 30px; }
.manager-dashboard .page-subtitle { color: var(--app-muted); font-size: 14px; }
.manager-dashboard .summary-card, .manager-dashboard .insight-card, .manager-dashboard .team-panel { border-color: var(--app-border); background: var(--app-surface); }
.manager-dashboard .summary-card > strong { color: var(--app-text); font-size: 26px; }
.manager-dashboard .summary-card > span:last-child { color: var(--app-muted); font-size: 12px; }
.manager-dashboard .insight-heading h2, .manager-dashboard .live-card h2, .manager-dashboard .team-panel-heading h2 { color: var(--app-text); font-size: 15px; }
.manager-dashboard .insight-heading p, .manager-dashboard .team-panel-heading p { color: var(--app-muted); font-size: 12px; }
.manager-dashboard .insight-heading > strong { color: var(--app-text); font-size: 21px; }
.manager-dashboard .live-count strong { color: var(--app-text); }
.manager-dashboard .live-count span, .manager-dashboard .live-legend { font-size: 11px; } .manager-dashboard .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }.manager-dashboard .insights-grid { grid-template-columns: minmax(0, 1.3fr) minmax(210px, 1fr); }
  .manager-dashboard .page-heading { margin-bottom: 15px; }
  .manager-dashboard .page-heading h1 { font-size: 27px; }
  .manager-dashboard .page-subtitle { font-size: 12px; }
  .manager-dashboard .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; margin-bottom: 12px; }
  .manager-dashboard .summary-card { min-height: 110px; padding: 13px; border-radius: 16px; }
  .manager-dashboard .summary-icon { width: 34px; height: 34px; margin-bottom: 8px; border-radius: 10px; }
  .manager-dashboard .summary-icon svg { width: 18px; }
  .manager-dashboard .summary-card > strong { font-size: 22px; }
  .manager-dashboard .summary-card > span:last-child { font-size: 11px; }
  .manager-dashboard .insights-grid { grid-template-columns: 1fr; }
  .manager-dashboard .insight-card { min-height: 140px; padding: 17px; border-radius: 17px; }
  .manager-dashboard .team-directory-section > .page-heading { align-items: stretch; flex-direction: column; }
  .manager-dashboard .live-legend { flex-wrap: wrap; justify-content: flex-start; gap: 8px 14px; }
  .manager-dashboard .summary-card { min-height: 102px; padding: 11px; }
  .manager-dashboard .summary-card > span:last-child { font-size: 10px; }
.manager-dashboard .page-heading h1 { letter-spacing: -.7px; }
.manager-dashboard .summary-card, .manager-dashboard .insight-card, .manager-dashboard .team-panel { border-radius: var(--app-radius-panel); box-shadow: var(--app-shadow-panel); }
.manager-dashboard .summary-card { min-height: 132px; padding: 17px; }
.manager-dashboard .summary-icon { width: 36px; height: 36px; border-radius: 11px; }
.manager-dashboard .summary-card > strong { font-size: 25px; }
.manager-dashboard .summary-card > span:last-child { font-size: 12px; }
.manager-dashboard .insight-card { min-height: 190px; padding: 20px; }
.manager-dashboard .insight-heading h2, .manager-dashboard .live-card h2, .manager-dashboard .team-panel-heading h2 { font-size: 16px; }
.manager-dashboard .insight-heading p, .manager-dashboard .team-panel-heading p { font-size: 12px; }
.manager-dashboard .insight-heading > strong { font-size: 24px; }
  .manager-dashboard .summary-card { min-height: 116px; padding: 14px; }
  .manager-dashboard .summary-card > strong { font-size: 23px; }
  .manager-dashboard .summary-card > span:last-child { font-size: 11px; }
  .manager-dashboard .insight-card { min-height: 155px; padding: 17px; }
.manager-dashboard .page-heading { margin-bottom: 30px; }
.manager-dashboard .page-heading h1 { font-size: 36px; }
.manager-dashboard .page-subtitle { font-size: 15px; }
.manager-dashboard .eyebrow { font-size: 12px; }
.manager-dashboard .summary-grid { gap: 16px; }
.manager-dashboard .summary-card { min-height: 148px; padding: 20px; }
.manager-dashboard .summary-icon { width: 42px; height: 42px; margin-bottom: 11px; }
.manager-dashboard .summary-icon svg { width: 22px; }
.manager-dashboard .summary-card > strong { font-size: 29px; }
.manager-dashboard .summary-card > span:last-child { font-size: 14px; }
.manager-dashboard .insights-grid { gap: 16px; }
.manager-dashboard .insight-card { min-height: 215px; padding: 24px; }
.manager-dashboard .insight-heading h2, .manager-dashboard .live-card h2 { font-size: 18px; }
.manager-dashboard .insight-heading p { font-size: 14px; }
.manager-dashboard .insight-heading > strong { font-size: 27px; }
.manager-dashboard .live-count strong { font-size: 29px; }
.manager-dashboard .live-count span, .manager-dashboard .live-legend { font-size: 13px; }
  .manager-dashboard .page-heading h1 { font-size: 30px; }
  .manager-dashboard .summary-card { min-height: 124px; padding: 15px; }
  .manager-dashboard .summary-card > strong { font-size: 25px; }
  .manager-dashboard .summary-card > span:last-child { font-size: 12px; }
  .manager-dashboard .insight-card { min-height: 165px; padding: 19px; }
</style>
