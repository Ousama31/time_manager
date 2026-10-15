<template>


          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">Time records</p><h1 class="dashboard-title">My Times</h1><p class="date-line dashboard-description">Review your recorded work sessions.</p></div><button class="refresh-button" aria-label="Refresh time records" :disabled="loading" @click="$emit('refresh')"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 7v5h-5M4 17v-5h5"/><path d="M5.5 9A7 7 0 0 1 17.4 6L20 8M4 16l2.6 2A7 7 0 0 0 18.5 15"/></svg><span>Refresh</span></button></div>
          <article class="card times-panel dashboard-surface"><div class="section-heading"><div><p class="card-kicker">Recorded activity</p><h2>Work and break entries</h2></div><span class="subtle-label">{{ workingTimes.length }} {{ workingTimes.length === 1 ? 'entry' : 'entries' }}</span></div>
            <div v-if="workingTimes.length" class="times-table"><div class="times-table-head"><span>Type</span><span>Date</span><span>Started</span><span>Ended</span><span>Duration</span></div><div v-for="entry in sortedWorkingTimes" :key="entry.id" class="times-table-row"><span>{{ entry.kind === 'break' ? 'Break' : 'Work' }}</span><span>{{ formatDate(entry.start) }}</span><span>{{ formatTime(entry.start) }}</span><span>{{ formatTime(entry.end) }}</span><strong>{{ durationLabel(entry.start, entry.end) }}</strong></div></div>
            <div v-else class="empty-state">Your completed work and break entries will appear here.</div>
          </article>

</template>

<script>
import { formatDate, formatTime, durationSeconds, formatDuration } from '../../../utils/time'
export default {
  name: 'EmployeeTimesSection',

  props: {
    loading: { type: Boolean, required: true },
    workingTimes: { type: Array, required: true },
    sortedWorkingTimes: { type: Array, required: true }
  },
  methods: {
    formatDate,
    formatTime,
    durationLabel(start, end) { return formatDuration(durationSeconds(start, end)) }
  }
}
</script>

<style>
.employee-dashboard .refresh-button { display: flex; min-height: 40px; align-items: center; gap: 8px; padding: 0 13px; border: 1px solid #dfe3e9; border-radius: 10px; color: #4d5968; background: #fff; font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; }
.employee-dashboard .refresh-button:disabled { opacity: .6; }
.employee-dashboard .refresh-button svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.employee-dashboard .empty-state { display: grid; min-height: 180px; place-items: center; color: #9299a3; text-align: center; font-size: 14px; }
.employee-dashboard .times-panel { padding: 24px; }
.employee-dashboard .times-table { margin-top: 18px; }
.employee-dashboard .times-table-head, .employee-dashboard .times-table-row { display: grid; grid-template-columns: .8fr 1fr 1fr 1fr .8fr; align-items: center; gap: 12px; min-height: 48px; border-bottom: 1px solid #eef0f4; font-size: 13px; }
.employee-dashboard .times-table-head { min-height: 36px; color: #9299a3; font-size: 11px; font-weight: 650; text-transform: uppercase; }
.employee-dashboard .times-table-row strong { font-weight: 650; }
  .employee-dashboard .refresh-button { width: 40px; min-width: 40px; justify-content: center; padding: 0; }
  .employee-dashboard .refresh-button span { display: none; }
  .employee-dashboard .times-panel { padding: 19px; }
  .employee-dashboard .times-table-head { display: none; }
  .employee-dashboard .times-table-row { grid-template-columns: 1fr auto; gap: 4px 12px; padding: 10px 0; }
  .employee-dashboard .times-table-row span:first-child { grid-column: 1 / -1; color: #7d8691; font-size: 11px; }
  .employee-dashboard .times-table-row span:nth-child(2)::before { content: 'Date '; color: #9aa0a9; }
  .employee-dashboard .times-table-row span:nth-child(3)::before { content: 'Started '; color: #9aa0a9; }
  .employee-dashboard .times-table-row span:nth-child(4)::before { content: 'Ended '; color: #9aa0a9; }
  .employee-dashboard .times-table-row strong { grid-column: 2; grid-row: 2 / 4; }
  .employee-dashboard .times-table-row { grid-template-columns: minmax(0, 1fr) auto; }
  .employee-dashboard .times-table-row strong { white-space: nowrap; }
.employee-dashboard .times-panel { padding: 28px; }
.employee-dashboard .times-table-head, .employee-dashboard .times-table-row { min-height: 56px; font-size: 15px; }
.employee-dashboard .times-table-head { font-size: 13px; }
  .employee-dashboard .times-panel { padding: 18px; }
</style>
