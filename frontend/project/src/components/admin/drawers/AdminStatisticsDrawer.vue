<template>
    <div v-if="statsUser" class="drawer-backdrop" @click.self="close" @keydown.esc="close">
        <aside class="role-drawer" role="dialog" aria-modal="true" aria-labelledby="statistics-drawer-title">
          <header class="drawer-header"><div><p class="drawer-eyebrow">{{ isManagerStats ? 'TEAM STATISTICS' : 'MEMBER STATISTICS' }}</p><h2 id="statistics-drawer-title">{{ statsUser.name }}</h2><p>{{ isManagerStats ? 'Team performance' : statsUser.email }}</p></div><button class="drawer-close" aria-label="Close statistics" @click="close"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></header>
          <div class="drawer-body statistics-drawer-body">
            <div v-if="statsError" class="inline-notice error-notice" role="alert">{{ statsError }}</div>
            <div v-if="statsLoading" class="teams-empty">Loading statistics…</div>
            <div v-else-if="!statsError" class="statistics-content">
              <div v-if="isManagerStats" class="statistics-summary statistics-summary--team">
                <article class="statistics-metric"><span>Employees</span><strong>{{ statsTeamMembers.length }}</strong></article>
                <article class="statistics-metric"><span>Active employees</span><strong>{{ statsActiveTeamCount }}</strong></article>
                <article class="statistics-metric"><span>Team hours today</span><strong>{{ formatMinutes(statsTodayMinutes) }}</strong></article>
                <article class="statistics-metric"><span>Team hours this week</span><strong>{{ formatMinutes(statsWeekMinutes) }}</strong></article>
              </div>
              <div v-else class="statistics-summary">
                <article class="statistics-metric"><span>Today</span><strong>{{ formatMinutes(statsTodayMinutes) }}</strong></article>
                <article class="statistics-metric"><span>This week</span><strong>{{ formatMinutes(statsWeekMinutes) }}</strong></article>
                <article class="statistics-metric"><span>Current status</span><strong>{{ statsClock?.state === 'break' ? 'On break' : statsClock?.status ? 'Working' : 'Off the clock' }}</strong></article>
              </div>
              <article class="statistics-chart"><div><h3>{{ isManagerStats ? 'Team working hours this week' : 'Working hours this week' }}</h3><strong>{{ formatMinutes(statsWeekMinutes) }}</strong></div><WeeklyHoursChart variant="manager" :days="statsWeekBars" :label="`${isManagerStats ? 'Team' : 'Selected member'} hours this week: ${formatMinutes(statsWeekMinutes)}`" /></article>
            </div>
            <div v-if="statsUser.role === 'Employee'" class="drawer-team-controls">
              <p v-if="teamActionError" class="membership-error" role="alert">{{ teamActionError }}</p>
              <button v-if="statsUser.managerId" type="button" class="team-action drawer-team-action team-remove" :disabled="teamActionBusy" @click="updateTeamAssignment(statsUser, null)">{{ teamActionBusy ? 'Saving…' : 'Remove from team' }}</button>
              <div v-else class="drawer-team-add"><label for="stats-team-manager">Add to team</label><div><select id="stats-team-manager" :value="selectedStatsManagerId" @change="emitModel('selectedStatsManagerId', $event.target.value)"><option value="">Choose a team</option><option v-for="team in managerTeams" :key="team.manager.id" :value="team.manager.id">{{ team.manager.name }}</option></select><button type="button" class="team-action drawer-team-action" :disabled="teamActionBusy || !selectedStatsManagerId" @click="addStatsUserToTeam">{{ teamActionBusy ? 'Saving…' : 'Add to team' }}</button></div></div>
            </div>
            <EmailDraftForm
              :subject="messageSubject"
              :body="messageBody"
              :recipient="statsUser.email"
              id-prefix="admin-message"
              :error="messageError"
              :success="messageSuccess"
              @update:subject="emitModel('messageSubject', $event)"
              @update:body="emitModel('messageBody', $event)"
              @send="$emit('send-message')"
            />
          </div>
        </aside>
      </div>
</template>

<script>
import WeeklyHoursChart from '../../dashboard/WeeklyHoursChart.vue'
import EmailDraftForm from '../../shared/EmailDraftForm.vue'
import { formatMinutes } from '../../../utils/time'
export default {
  name: 'AdminStatisticsDrawer',
  components: { WeeklyHoursChart, EmailDraftForm },
  props: {
    statsUser: { type: Object, default: null },
    isManagerStats: { type: Boolean, required: true },
    statsTeamMembers: { type: Array, required: true },
    statsActiveTeamCount: { type: Number, required: true },
    statsTodayMinutes: { type: Number, required: true },
    statsWeekMinutes: { type: Number, required: true },
    statsWeekBars: { type: Array, required: true },
    statsClock: { type: Object, default: null },
    statsLoading: { type: Boolean, required: true },
    statsError: { type: String, default: '' },
    teamActionError: { type: String, default: '' },
    teamActionBusy: { type: Boolean, required: true },
    selectedStatsManagerId: { type: [String, Number], default: '' },
    managerTeams: { type: Array, required: true },
    messageSubject: { type: String, required: true },
    messageBody: { type: String, required: true },
    messageError: { type: String, default: '' },
    messageSuccess: { type: String, default: '' }
  },
  methods: {
    emitModel(name, value) { this.$emit(`update:${name}`, value) },
    formatMinutes,
    close() { this.$emit('close') },
    updateTeamAssignment(user, managerId) { this.$emit('update-team-assignment', user, managerId) },
    addStatsUserToTeam() { this.$emit('add-user-to-team') },
  }
}
</script>

<style>
.admin-dashboard .team-remove { padding: 6px 9px; border: 1px solid #f0dada; border-radius: 6px; color: #a54b4b; background: #fff; font: inherit; font-size: 9px; font-weight: 650; cursor: pointer; }
.admin-dashboard .team-remove { margin-left: auto; color: #a54b4b; border-color: #f0dada; }

.admin-dashboard .statistics-content { padding: 0; }
.admin-dashboard .drawer-team-controls { margin-top: 18px; padding-top: 16px; border-top: 1px solid var(--app-border); }
.admin-dashboard .drawer-team-add > label { display: block; margin-bottom: 7px; color: var(--app-muted); font-size: 12px; font-weight: 650; }
.admin-dashboard .drawer-team-add > div { display: flex; gap: 8px; }
.admin-dashboard .drawer-team-add select { min-width: 0; flex: 1; padding: 0 10px; border: 1px solid var(--app-border); border-radius: 7px; color: var(--app-text); background: var(--app-surface); font: inherit; font-size: 12px; }
.admin-dashboard .drawer-team-action { min-height: 38px; margin-top: 0; font-size: 12px; }
.admin-dashboard .drawer-team-add .drawer-team-action { flex: 0 0 auto; }
.admin-dashboard .drawer-team-controls > .drawer-team-action { width: 100%; }
.admin-dashboard .membership-error { margin: 0 0 10px; color: #a33636; font-size: 12px; }
.admin-dashboard .statistics-summary { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.admin-dashboard .statistics-summary--team { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.admin-dashboard .statistics-metric { display: grid; min-width: 0; gap: 8px; padding: 17px; border: 1px solid var(--app-border); border-radius: 10px; background: var(--app-background); }
.admin-dashboard .statistics-metric span { color: var(--app-muted); font-size: 13px; }
.admin-dashboard .statistics-metric strong { overflow-wrap: anywhere; color: var(--app-text); font-size: 22px; }
.admin-dashboard .statistics-chart { margin-top: 14px; padding: 18px; border: 1px solid var(--app-border); border-radius: 10px; background: var(--app-surface); }
.admin-dashboard .statistics-chart > div { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.admin-dashboard .statistics-chart h3 { margin: 0; color: var(--app-text); font-size: 15px; }
.admin-dashboard .statistics-chart > div > strong { color: var(--app-text); font-size: 16px; }
  .admin-dashboard .statistics-summary { grid-template-columns: 1fr; gap: 8px; }
  .admin-dashboard .statistics-metric { grid-template-columns: 1fr auto; align-items: center; padding: 13px; }
  .admin-dashboard .statistics-chart { padding: 14px; }
</style>
