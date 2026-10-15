<template>
        <section class="team-directory-section">
          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">TEAM MANAGEMENT</p><h1 class="dashboard-title">My team</h1><p class="page-subtitle dashboard-description">Manage your assigned employees and unassigned staff.</p></div><label class="team-search"><svg viewBox="0 0 24 24"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 4.5 4.5"/></svg><input :value="searchQuery" @input="$emit('update:searchQuery', $event.target.value)" type="search" placeholder="Search employees…" aria-label="Search employees" /></label></div>
          <div v-if="loadError" class="load-error" role="alert">{{ loadError }} <button @click="$emit('retry')">Try again</button></div>
          <section class="team-panel dashboard-surface" aria-labelledby="my-team-heading">
            <header class="team-panel-heading"><div><h2 id="my-team-heading">Current team <span class="count-pill">{{ filteredTeam.length }}</span></h2><p>Employees assigned to you.</p></div></header>
            <div v-if="loading" class="team-empty">Loading your team…</div>
            <ul v-else-if="filteredTeam.length" class="team-directory-list"><li v-for="member in filteredTeam" :key="member.id"><button type="button" class="employee-cell" :aria-label="`View statistics for ${member.name}`" @click="$emit('open-statistics', member)"><InitialAvatar variant="employee-avatar" :tone="member.avatarTone" :initials="member.initials" /><span><strong>{{ member.name }}</strong><small>{{ member.email }}</small></span></button><span class="work-status" :class="member.status === 'Inactive' ? 'suspended' : member.clockState !== 'off' ? 'working' : 'off-clock'"><i></i>{{ member.status === 'Inactive' ? 'Suspended' : member.clockState !== 'off' ? 'Working' : 'Off the clock' }}</span></li></ul>
            <div v-else class="team-empty">{{ team.length ? 'No team members match your search.' : 'No employees are assigned to your team yet.' }}</div>
          </section>
          <section class="team-panel unassigned-panel dashboard-surface" aria-labelledby="unassigned-heading">
            <header class="team-panel-heading"><div><h2 id="unassigned-heading">Unassigned Employees <span class="count-pill">{{ filteredUnassigned.length }}</span></h2><p>Employees who are not assigned to a team.</p></div></header>
            <ul v-if="filteredUnassigned.length" class="team-directory-list"><li v-for="employee in filteredUnassigned" :key="employee.id"><button type="button" class="employee-cell" :aria-label="`View statistics for ${employee.name}`" @click="$emit('open-statistics', employee)"><InitialAvatar variant="employee-avatar" :tone="employee.avatarTone" :initials="employee.initials" /><span><strong>{{ employee.name }}</strong><small>{{ employee.email }}</small></span></button><span class="work-status off-clock"><i></i>{{ employee.status }}</span></li></ul>
            <div v-else class="team-empty">{{ unassignedEmployees.length ? 'No unassigned employees match your search.' : 'There are no unassigned employees.' }}</div>
          </section>
        </section>
</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'ManagerTeamSection',
  components: { InitialAvatar },
  props: {
    loadError: { type: String, default: '' },
    searchQuery: { type: String, required: true },
    filteredTeam: { type: Array, required: true },
    filteredUnassigned: { type: Array, required: true },
    team: { type: Array, required: true },
    unassignedEmployees: { type: Array, required: true },
    loading: { type: Boolean, required: true }
  },
}
</script>

<style>
.manager-dashboard .team-panel { overflow: hidden; border: 1px solid #eceef2; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); scroll-margin-top: 73px; }
.manager-dashboard .team-panel-heading { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 14px 16px; border-bottom: 1px solid #eceef2; }
.manager-dashboard .team-panel-heading h2 { display: flex; align-items: center; gap: 7px; margin: 0; color: #303a49; font-size: 11px; font-weight: 700; }
.manager-dashboard .count-pill { padding: 3px 6px; border-radius: 999px; color: #657184; background: #f0f2f5; font-size: 8px; }
.manager-dashboard .team-panel-heading p { margin: 4px 0 0; color: #929baa; font-size: 9px; }
.manager-dashboard .team-directory-section { display: grid; gap: 16px; }
.manager-dashboard .team-directory-section .team-search { width: min(320px, 45%); }
.manager-dashboard .team-directory-list { margin: 0; padding: 0 20px; list-style: none; }
.manager-dashboard .team-directory-list li { display: flex; min-height: 72px; align-items: center; gap: 14px; border-bottom: 1px solid var(--app-border); }
.manager-dashboard .team-directory-list li:last-child { border-bottom: 0; }
.manager-dashboard .team-directory-list .employee-cell { flex: 1; min-width: 0; }
.manager-dashboard .unassigned-panel { margin-top: 0; }
.manager-dashboard .team-search { display: flex; width: min(225px, 45%); min-height: 31px; align-items: center; gap: 7px; padding: 0 9px; border: 1px solid #e5e8ed; border-radius: 6px; background: #fff; }
.manager-dashboard .team-search:focus-within { border-color: #82b8f3; box-shadow: 0 0 0 3px rgb(22 131 248 / 9%); }
.manager-dashboard .team-search svg { width: 13px; fill: none; stroke: #929baa; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.manager-dashboard .team-search input { width: 100%; min-width: 0; border: 0; outline: 0; color: #354153; background: transparent; font: inherit; font-size: 9px; }
.manager-dashboard .team-search input::placeholder { color: #a1a9b5; }
.manager-dashboard .employee-cell { display: flex; width: 100%; align-items: center; gap: 9px; padding: 0; border: 0; color: inherit; background: transparent; font: inherit; text-align: left; cursor: pointer; }
.manager-dashboard .employee-cell:focus-visible { border-radius: 8px; outline: 2px solid var(--app-accent); outline-offset: 3px; }
.manager-dashboard .employee-cell:hover strong { color: var(--app-accent-strong); }
.manager-dashboard .employee-cell > span:last-child { display: grid; gap: 3px; }
.manager-dashboard .employee-cell strong { color: #354153; font-size: 9px; font-weight: 650; }
.manager-dashboard .employee-cell small { color: #929baa; font-size: 8px; }
.manager-dashboard .work-status { display: inline-flex; align-items: center; gap: 5px; color: #788393; font-size: 8px; }
.manager-dashboard .work-status i { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.manager-dashboard .work-status.working { color: #178b50; }.manager-dashboard .work-status.off-clock { color: #8b95a3; }.manager-dashboard .work-status.suspended { color: #b34848; }
.manager-dashboard .team-empty { padding: 27px 15px; color: #8994a3; font-size: 10px; text-align: center; }
.manager-dashboard .team-panel-heading { border-color: var(--app-border); }
.manager-dashboard .employee-cell strong { font-size: 12px; }
.manager-dashboard .employee-cell small { font-size: 10px; }
.manager-dashboard .work-status { font-size: 10px; }
.manager-dashboard .team-empty { color: var(--app-muted); font-size: 12px; }
.manager-dashboard .team-search { border-color: var(--app-border); background: var(--app-surface); }
.manager-dashboard .team-search input { color: var(--app-text); font-size: 12px; }
.manager-dashboard .team-search:focus-within { border-color: var(--app-accent); box-shadow: 0 0 0 3px rgb(22 132 248 / 12%); }
  .manager-dashboard .team-panel { border-radius: 17px; }
  .manager-dashboard .team-panel-heading { padding: 16px; }
  .manager-dashboard .team-panel-heading h2 { font-size: 15px; }
  .manager-dashboard .team-panel-heading p { font-size: 11px; line-height: 1.45; }
  .manager-dashboard .team-panel-heading { align-items: flex-start; flex-direction: column; }
  .manager-dashboard .team-search { width: 100%; min-height: 42px; padding: 0 12px; border-radius: 11px; }
  .manager-dashboard .team-directory-section .team-search { width: 100%; }
  .manager-dashboard .team-directory-list { padding: 0 14px; }
  .manager-dashboard .team-directory-list li { gap: 8px; }
  .manager-dashboard .team-search svg { width: 17px; }
  .manager-dashboard .employee-cell { min-width: 0; }
  .manager-dashboard .employee-cell strong, .manager-dashboard .employee-cell small { overflow-wrap: anywhere; }
.manager-dashboard .team-panel-heading { padding: 18px 20px; }
.manager-dashboard .employee-cell { gap: 11px; }
.manager-dashboard .employee-cell strong { font-size: 13px; }
.manager-dashboard .employee-cell small { font-size: 11px; }
.manager-dashboard .work-status { font-size: 11px; }
  .manager-dashboard .team-panel-heading { padding: 16px; }
.manager-dashboard .team-panel-heading { padding: 21px 23px; }
.manager-dashboard .team-panel-heading h2 { font-size: 18px; }
.manager-dashboard .team-panel-heading p { font-size: 14px; }
.manager-dashboard .team-search { min-height: 42px; width: min(280px, 45%); }
.manager-dashboard .team-search input { font-size: 14px; }
.manager-dashboard .employee-cell { gap: 13px; }
.manager-dashboard .employee-cell strong { font-size: 15px; }
.manager-dashboard .employee-cell small { font-size: 12px; }
.manager-dashboard .work-status, .manager-dashboard .break-indicator { font-size: 12px; }
  .manager-dashboard .team-panel-heading { padding: 17px; }
  .manager-dashboard .team-search { width: 100%; min-height: 46px; }
  .manager-dashboard .employee-cell strong { font-size: 14px; }
  .manager-dashboard .employee-cell small { font-size: 12px; }
</style>
