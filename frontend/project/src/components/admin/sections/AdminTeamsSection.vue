<template>
        <section id="teams" class="teams-section" aria-label="Manager teams">
          <div v-if="loadingUsers" class="teams-empty">Loading teams…</div>
          <div v-else-if="managerTeams.length === 0" class="teams-empty">No managers are registered yet.</div>
          <div v-else class="teams-grid">
            <article v-for="team in managerTeams" :key="team.manager.id" class="team-card dashboard-surface">
              <header class="team-manager"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${team.manager.name}`" @click="openStatistics(team.manager)"><InitialAvatar tone="tone-lilac" :initials="team.manager.initials" /><span class="user-identity"><strong>{{ team.manager.name }}</strong><small>{{ team.manager.email }}</small></span></button><span class="role-badge role-manager">Manager</span></header>
              <div class="team-members-heading"><span>TEAM MEMBERS</span><span class="count-pill">{{ team.employees.length }}</span></div>
              <ul v-if="team.employees.length" class="team-members">
                <li v-for="employee in team.employees" :key="employee.id"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${employee.name}`" @click="openStatistics(employee)"><InitialAvatar :tone="employee.avatarTone" :initials="employee.initials" /><span class="user-identity"><strong>{{ employee.name }}</strong><small>{{ employee.email }}</small></span></button><span class="status-badge" :class="employee.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ employee.status }}</span></li>
              </ul>
              <p v-else class="team-empty-members">No employees assigned yet.</p>
            </article>
          </div>
          <article v-if="unassignedEmployees.length" class="unassigned-card dashboard-surface"><h3>Unassigned employees <span class="count-pill">{{ unassignedEmployees.length }}</span></h3><ul class="team-members"><li v-for="employee in unassignedEmployees" :key="employee.id"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${employee.name}`" @click="openStatistics(employee)"><InitialAvatar :tone="employee.avatarTone" :initials="employee.initials" /><span class="user-identity"><strong>{{ employee.name }}</strong><small>{{ employee.email }}</small></span></button><span class="status-badge" :class="employee.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ employee.status }}</span></li></ul></article>
        </section>
</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'AdminTeamsSection',
  components: { InitialAvatar },
  props: {
    loadingUsers: { type: Boolean, required: true },
    managerTeams: { type: Array, required: true },
    unassignedEmployees: { type: Array, required: true }
  },
  methods: { openStatistics(user) { this.$emit('open-statistics', user) } }
}
</script>

<style>
.admin-dashboard .teams-section { margin: 0 0 20px; }
.admin-dashboard .teams-grid { display: grid; grid-template-columns: 1fr; gap: 14px; }
.admin-dashboard .team-card, .admin-dashboard .unassigned-card { min-width: 0; padding: 16px; border: 1px solid #e6eaf0; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.admin-dashboard .team-manager { display: flex; align-items: center; gap: 10px; padding-bottom: 14px; border-bottom: 1px solid #eef0f4; }
.admin-dashboard .team-manager .role-badge { margin-left: auto; }
.admin-dashboard .team-members-heading { display: flex; align-items: center; gap: 8px; margin: 14px 0 3px; color: #8994a3; font-size: 8px; font-weight: 750; letter-spacing: .8px; }
.admin-dashboard .team-members { margin: 0; padding: 0; list-style: none; }
.admin-dashboard .team-members li { display: flex; min-width: 0; align-items: center; gap: 9px; padding: 10px 0; border-bottom: 1px solid #f0f2f5; }
.admin-dashboard .team-members li:last-child { border-bottom: 0; }
.admin-dashboard .team-members .user-avatar { width: 29px; height: 29px; flex-basis: 29px; }
.admin-dashboard .team-members .user-identity { min-width: 0; }
.admin-dashboard .team-members .user-identity strong, .admin-dashboard .team-members .user-identity small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.admin-dashboard .team-members .status-badge { margin-left: auto; }
.admin-dashboard .team-empty-members, .admin-dashboard .teams-empty { margin: 0; padding: 18px 0; color: #8994a3; font-size: 11px; }
.admin-dashboard .teams-empty { padding: 25px; border: 1px dashed #dfe4eb; border-radius: 10px; background: #fff; text-align: center; }
.admin-dashboard .unassigned-card { margin-top: 14px; }
.admin-dashboard .unassigned-card h3 { display: flex; align-items: center; gap: 8px; margin: 0; color: #354052; font-size: 12px; }
.admin-dashboard .count-pill { padding: 3px 7px; border-radius: 999px; color: #626f80; background: #f0f2f5; font-size: 9px; font-weight: 650; }
.admin-dashboard .user-stats-trigger { display: flex; min-width: 0; align-items: center; gap: 10px; padding: 0; border: 0; color: inherit; background: transparent; font: inherit; text-align: left; cursor: pointer; }
.admin-dashboard .user-stats-trigger:focus-visible { border-radius: 8px; outline: 2px solid var(--app-accent); outline-offset: 3px; }
.admin-dashboard .user-stats-trigger:hover .user-identity strong { color: var(--app-accent-strong); }
.admin-dashboard .team-stats-trigger { flex: 1; }
.admin-dashboard .user-identity { display: grid; gap: 4px; }
.admin-dashboard .user-identity strong { color: #354153; font-size: 10px; font-weight: 650; }
.admin-dashboard .user-identity small { color: #8b96a5; font-size: 9px; }
.admin-dashboard .role-badge { display: inline-flex; min-height: 23px; align-items: center; gap: 5px; padding: 0 8px; border: 1px solid transparent; border-radius: 999px; font-size: 9px; font-weight: 650; }
.admin-dashboard .role-badge svg { width: 12px; height: 12px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.admin-dashboard .role-manager { border-color: #d7e9ff; color: #3671b6; background: #eff7ff; }
.admin-dashboard .status-badge { display: inline-flex; align-items: center; gap: 6px; color: #647181; font-size: 9px; }
.admin-dashboard .status-badge i { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.admin-dashboard .drawer-user-summary > .role-badge { margin-left: auto; white-space: nowrap; }
.admin-dashboard .users-panel, .admin-dashboard .team-card, .admin-dashboard .unassigned-card { border-color: var(--app-border); border-radius: 12px; }
.admin-dashboard .team-manager .user-identity strong, .admin-dashboard .user-identity strong { font-size: 12px; }
.admin-dashboard .team-manager .user-identity small, .admin-dashboard .user-identity small { font-size: 10px; }
.admin-dashboard .team-members-heading { font-size: 9px; }
.admin-dashboard .team-members li { padding: 12px 0; }
.admin-dashboard .team-members .user-avatar { width: 34px; height: 34px; flex-basis: 34px; font-size: 10px; }
.admin-dashboard .team-members .status-badge, .admin-dashboard .status-badge { font-size: 11px; }
.admin-dashboard .role-badge { min-height: 25px; font-size: 10px; }
  .admin-dashboard .users-table td:nth-child(2) .role-badge { min-height: 22px; padding: 0 7px; font-size: 10px; }
.admin-dashboard .teams-section { margin-top: 0; }
.admin-dashboard .team-card, .admin-dashboard .unassigned-card, .admin-dashboard .users-panel { border-radius: 17px; box-shadow: var(--app-shadow-panel); }
.admin-dashboard .team-card, .admin-dashboard .unassigned-card { padding: 19px; }
.admin-dashboard .team-members-heading { font-size: 10px; }
.admin-dashboard .team-members li { padding: 12px 0; }
.admin-dashboard .team-members .user-avatar { width: 34px; height: 34px; flex-basis: 34px; }
.admin-dashboard .team-members .user-identity strong { font-size: 12px; }
.admin-dashboard .team-members .user-identity small { font-size: 10px; }
.admin-dashboard .user-identity strong { font-size: 12px; }
.admin-dashboard .user-identity small { font-size: 10px; }
.admin-dashboard .role-badge { min-height: 27px; padding-inline: 10px; font-size: 11px; }
.admin-dashboard .status-badge { font-size: 11px; }
.admin-dashboard .user-identity strong { color: var(--app-text); font-size: 12px; }
.admin-dashboard .user-identity small { color: var(--app-muted); font-size: 10px; }
.admin-dashboard .role-badge { min-height: 25px; font-size: 10px; }
.admin-dashboard .status-badge { font-size: 11px; }
  .admin-dashboard .teams-grid { grid-template-columns: 1fr; }
  .admin-dashboard .team-manager { gap: 9px; }
  .admin-dashboard .team-manager .user-identity strong { font-size: 12px; }
  .admin-dashboard .team-manager .user-identity small { overflow-wrap: anywhere; white-space: normal; }
.admin-dashboard .teams-section { font-size: 15px; }
.admin-dashboard .team-card, .admin-dashboard .unassigned-card { padding: 24px; }
.admin-dashboard .team-manager .user-avatar { width: 44px; height: 44px; flex-basis: 44px; font-size: 12px; }
.admin-dashboard .team-manager .user-identity strong, .admin-dashboard .team-members .user-identity strong { font-size: 15px; }
.admin-dashboard .team-manager .user-identity small, .admin-dashboard .team-members .user-identity small { font-size: 12px; }
.admin-dashboard .role-badge { min-height: 30px; padding-inline: 12px; font-size: 12px; }
.admin-dashboard .team-members-heading { margin-top: 17px; font-size: 12px; }
.admin-dashboard .team-members li { gap: 12px; padding: 14px 0; }
.admin-dashboard .team-members .user-avatar { width: 40px; height: 40px; flex-basis: 40px; font-size: 11px; }
.admin-dashboard .status-badge { min-height: 26px; padding: 4px 10px; font-size: 12px; }
.admin-dashboard .team-empty-members, .admin-dashboard .teams-empty { font-size: 14px; }
.admin-dashboard .unassigned-card h3 { font-size: 16px; }
.admin-dashboard .user-identity strong { font-size: 14px; }
.admin-dashboard .user-identity small { font-size: 12px; }
.admin-dashboard .role-badge { min-height: 25px; font-size: 11px; }
.admin-dashboard .status-badge { font-size: 12px; }
  .admin-dashboard .team-card, .admin-dashboard .unassigned-card { padding: 19px; }
  .admin-dashboard .team-card, .admin-dashboard .unassigned-card { padding: 16px; }
  .admin-dashboard .team-manager .user-identity strong { font-size: 14px; }
  .admin-dashboard .team-members .user-identity strong { font-size: 13px; }
  .admin-dashboard .team-members .user-identity small { font-size: 11px; }
</style>
