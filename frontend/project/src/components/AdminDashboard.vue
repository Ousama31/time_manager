<template>
  <AppShell :navigation="navigation" :active-tab="activeSection" @navigate="navigateSection" @logout="disconnect">
      <div id="users" class="admin-content">
        <div v-if="activeSection !== 'profile'" class="page-intro">
          <div>
            <p class="admin-eyebrow">PEOPLE &amp; ACCESS</p>
            <h1>{{ activeSection === 'teams' ? 'Teams' : 'User Management' }}</h1>
            <p v-if="activeSection === 'teams'" class="intro-copy">Managers and their assigned employees.</p>
            <p v-else class="intro-copy">Manage your team, roles, and access in one place.</p>
          </div>
        </div>

        <div v-if="activeSection !== 'profile' && usersError" class="inline-notice error-notice" role="alert">{{ usersError }}</div>

        <section v-if="activeSection === 'teams'" id="teams" class="teams-section" aria-label="Manager teams">
          <div v-if="loadingUsers" class="teams-empty">Loading teams…</div>
          <div v-else-if="managerTeams.length === 0" class="teams-empty">No managers are registered yet.</div>
          <div v-else class="teams-grid">
            <article v-for="team in managerTeams" :key="team.manager.id" class="team-card">
              <header class="team-manager"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${team.manager.name}`" @click="openStatistics(team.manager)"><InitialAvatar tone="tone-lilac" :initials="team.manager.initials" /><span class="user-identity"><strong>{{ team.manager.name }}</strong><small>{{ team.manager.email }}</small></span></button><span class="role-badge role-manager">Manager</span></header>
              <div class="team-members-heading"><span>TEAM MEMBERS</span><span class="count-pill">{{ team.employees.length }}</span></div>
              <ul v-if="team.employees.length" class="team-members">
                <li v-for="employee in team.employees" :key="employee.id"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${employee.name}`" @click="openStatistics(employee)"><InitialAvatar :tone="employee.avatarTone" :initials="employee.initials" /><span class="user-identity"><strong>{{ employee.name }}</strong><small>{{ employee.email }}</small></span></button><span class="status-badge" :class="employee.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ employee.status }}</span></li>
              </ul>
              <p v-else class="team-empty-members">No employees assigned yet.</p>
            </article>
          </div>
          <article v-if="unassignedEmployees.length" class="unassigned-card"><h3>Unassigned employees <span class="count-pill">{{ unassignedEmployees.length }}</span></h3><ul class="team-members"><li v-for="employee in unassignedEmployees" :key="employee.id"><button type="button" class="user-stats-trigger team-stats-trigger" :aria-label="`View statistics for ${employee.name}`" @click="openStatistics(employee)"><InitialAvatar :tone="employee.avatarTone" :initials="employee.initials" /><span class="user-identity"><strong>{{ employee.name }}</strong><small>{{ employee.email }}</small></span></button><span class="status-badge" :class="employee.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ employee.status }}</span></li></ul></article>
        </section>

        <section v-if="activeSection === 'users'" class="users-panel" aria-labelledby="users-heading">
          <div class="panel-heading">
            <div><h2 id="users-heading">All users <span class="count-pill">{{ filteredUsers.length }}</span></h2><p>View and manage your workspace members.</p></div>
          </div>
          <div class="table-toolbar">
            <label class="search-box"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 4.5 4.5"/></svg><input v-model="searchQuery" type="search" placeholder="Search by name or email…" aria-label="Search users" /></label>
            <label class="filter-select"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M7 12h10m-7 6h4"/></svg><select v-model="statusFilter" aria-label="Filter by status"><option value="All">All statuses</option><option value="Active">Active</option><option value="Inactive">Inactive</option></select><svg class="select-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg></label>
            <button class="filter-role" :class="{ selected: roleFilter !== 'All' }" @click="roleFilter = roleFilter === 'All' ? 'Manager' : roleFilter === 'Manager' ? 'Employee' : 'All'"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M7 12h10m-7 6h4"/></svg><span>{{ roleFilter === 'All' ? 'All roles' : roleFilter }}</span><svg class="select-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg></button>
          </div>

          <div class="table-scroll">
            <table class="users-table">
              <thead><tr><th scope="col" class="user-column">USER <button aria-label="Sort users">↕</button></th><th scope="col">ROLE</th><th scope="col">STATUS</th><th scope="col">JOINED DATE <button aria-label="Sort by joined date">↕</button></th><th scope="col" class="actions-heading">ACTION</th></tr></thead>
              <tbody>
                <tr v-for="user in filteredUsers" :key="user.email">
                  <td class="user-cell"><button type="button" class="user-stats-trigger" :aria-label="`View statistics for ${user.name}`" @click="openStatistics(user)"><InitialAvatar :tone="user.avatarTone" :initials="user.initials" /><span class="user-identity"><strong>{{ user.name }}</strong><small>{{ user.email }}</small></span></button></td>
                  <td data-label="Role"><span class="role-badge" :class="roleClass(user.role)"><svg v-if="user.role === 'Admin'" viewBox="0 0 24 24" aria-hidden="true"><path d="m5 18 1.2-8 4.1 3.4L12 6l1.7 7.4 4.1-3.4L19 18H5ZM5 21h14"/></svg><svg v-else-if="user.role === 'Manager'" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg><svg v-else viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/></svg>{{ user.role }}</span></td>
                  <td data-label="Status"><span class="status-badge" :class="user.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ user.status }}</span></td>
                  <td class="joined-cell" data-label="Joined">{{ user.joined }}</td>
                  <td class="action-cell" data-label="Actions"><div class="action-buttons"><button class="manage-button" :disabled="user.actionBusy" @click="openRoleEditor(user)">Edit role</button><button class="user-action-button" :class="user.status === 'Active' ? 'suspend-button' : 'activate-button'" :disabled="user.actionBusy || isCurrentUser(user)" :title="isCurrentUser(user) ? 'You cannot change your own administrator account status' : user.status === 'Active' ? 'Suspend this account' : 'Activate this account'" @click="toggleUserStatus(user)">{{ user.actionBusy ? 'Saving…' : user.status === 'Active' ? 'Suspend' : 'Activate' }}</button><button class="user-action-button delete-button" :disabled="user.actionBusy || isCurrentUser(user)" :title="isCurrentUser(user) ? 'You cannot delete your own administrator account' : 'Delete this account'" @click="deleteUser(user)">{{ user.actionBusy ? 'Saving…' : 'Delete' }}</button></div></td>
                </tr>
                <tr v-if="loadingUsers"><td colspan="5" class="empty-row">Loading users…</td></tr>
                <tr v-else-if="filteredUsers.length === 0"><td colspan="5" class="empty-row">{{ searchQuery || statusFilter !== 'All' || roleFilter !== 'All' ? 'No users match your filters.' : 'No users to display yet.' }}</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <section v-if="activeSection === 'profile'" class="admin-profile-section" aria-labelledby="profile-heading">
          <div class="profile-page-heading"><p class="admin-eyebrow">ACCOUNT DETAILS</p><h2 id="profile-heading">Profile</h2><p>Your Time Manager account information.</p></div>
          <article class="card profile-card"><span class="profile-avatar">{{ initials }}</span><div><h3>{{ displayName }}</h3><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role">Administrator</span></div></article>
          <button class="profile-logout" type="button" @click="disconnect">Log out</button>
        </section>
      </div>
    <Transition name="drawer-fade">
      <div v-if="editingUser" class="drawer-backdrop" @click.self="closeRoleEditor" @keydown.esc="closeRoleEditor">
        <aside class="role-drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">
          <header class="drawer-header"><div><p class="drawer-eyebrow">TEAM ACCESS</p><h2 id="drawer-title">Edit user role</h2><p>Update this member’s workspace permissions.</p></div><button class="drawer-close" aria-label="Close role editor" @click="closeRoleEditor"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></header>
          <div class="drawer-body">
            <section class="drawer-user-summary"><InitialAvatar variant="drawer-avatar" :tone="editingUser.avatarTone" :initials="editingUser.initials" /><span><strong>{{ editingUser.name }}</strong><small>{{ editingUser.email }}</small></span><span class="role-badge" :class="roleClass(editingUser.role)">{{ editingUser.role }}</span></section>
            <fieldset class="role-fieldset"><legend>Choose a role</legend><p class="field-hint">Roles determine what this person can see and manage.</p>
              <label v-for="role in roleOptions" :key="role.name" class="role-option" :class="{ 'role-option-selected': selectedRole === role.name }"><input v-model="selectedRole" type="radio" :value="role.name" /><span class="role-option-icon" :class="role.iconTone"><svg v-if="role.name === 'Admin'" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg><svg v-else-if="role.name === 'Manager'" viewBox="0 0 24 24" aria-hidden="true"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M16 5.5a3.2 3.2 0 0 1 0 6.2M17 14a5 5 0 0 1 3.5 4.8"/></svg><svg v-else viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/></svg></span><span class="role-option-copy"><strong>{{ role.name }}</strong><small>{{ role.description }}</small></span><span class="custom-radio"></span></label>
            </fieldset>
            <div class="privilege-note" :class="{ 'privilege-note-admin': selectedRole === 'Admin', 'privilege-note-manager': selectedRole === 'Manager' }"><span class="privilege-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg></span><span><strong>{{ selectedRole === 'Admin' ? 'Full workspace access' : selectedRole === 'Manager' ? 'Team management access' : 'Standard member access' }}</strong><small>{{ selectedRole === 'Admin' ? 'Admins can manage roles, teams, schedules, and workspace settings.' : selectedRole === 'Manager' ? 'Managers can manage their team and view team time records.' : 'Members can track their own time and update their profile.' }}</small></span></div>
            <label class="confirm-toggle"><input v-model="confirmRoleChange" type="checkbox" /><span class="toggle-track"><i></i></span><span>I understand this role changes the user’s access.</span></label>
          </div>
          <footer class="drawer-footer"><button class="cancel-button" @click="closeRoleEditor">Cancel</button><button class="save-role-button" :disabled="!confirmRoleChange || savingRole" @click="saveRoleChange"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12 4.2 4.2L19 6.5"/></svg>{{ savingRole ? 'Saving…' : 'Save role changes' }}</button></footer>
        </aside>
      </div>
    </Transition>
    <Transition name="drawer-fade">
      <div v-if="statsUser" class="drawer-backdrop" @click.self="closeStatistics" @keydown.esc="closeStatistics">
        <aside class="role-drawer" role="dialog" aria-modal="true" aria-labelledby="statistics-drawer-title">
          <header class="drawer-header"><div><p class="drawer-eyebrow">{{ isManagerStats ? 'TEAM STATISTICS' : 'MEMBER STATISTICS' }}</p><h2 id="statistics-drawer-title">{{ statsUser.name }}</h2><p>{{ isManagerStats ? 'Team performance' : statsUser.email }}</p></div><button class="drawer-close" aria-label="Close statistics" @click="closeStatistics"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></header>
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
              <div v-else class="drawer-team-add"><label for="stats-team-manager">Add to team</label><div><select id="stats-team-manager" v-model="selectedStatsManagerId"><option value="">Choose a team</option><option v-for="team in managerTeams" :key="team.manager.id" :value="team.manager.id">{{ team.manager.name }}</option></select><button type="button" class="team-action drawer-team-action" :disabled="teamActionBusy || !selectedStatsManagerId" @click="addStatsUserToTeam">{{ teamActionBusy ? 'Saving…' : 'Add to team' }}</button></div></div>
            </div>
            <form class="message-compose" @submit.prevent="sendStatsMessage">
              <h3>Send an email</h3>
              <p>To {{ statsUser.email }}. Your email app chooses the sender account.</p>
              <label for="admin-message-subject">Subject <span>Optional</span></label>
              <input id="admin-message-subject" v-model.trim="messageSubject" type="text" maxlength="160" placeholder="A short subject" />
              <label for="admin-message-body">Message</label>
              <textarea id="admin-message-body" v-model="messageBody" required maxlength="5000" rows="4" placeholder="Write your message…"></textarea>
              <p v-if="messageError" class="message-error" role="alert">{{ messageError }}</p>
              <p v-if="messageSuccess" class="message-success" role="status">{{ messageSuccess }}</p>
              <button class="team-action message-submit" type="submit" :disabled="!messageBody.trim()">Open email draft</button>
            </form>
          </div>
        </aside>
      </div>
    </Transition>
  </AppShell>
</template>

<script>
import api from '../api'
import { getAvatarTone, getDisplayName, getInitials } from '../utils/identity'
import InitialAvatar from './InitialAvatar.vue'
import AppShell from './AppShell.vue'
import WeeklyHoursChart from './WeeklyHoursChart.vue'
import { createEmailDraftUrl } from '../utils/emailDraft'

function startOfLocalDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function startOfLocalWeek(date) {
  const start = startOfLocalDay(date)
  start.setDate(start.getDate() - (start.getDay() + 6) % 7)
  return start
}

function overlappingMinutes(startValue, endValue, rangeStart, rangeEnd) {
  const start = Math.max(new Date(startValue).getTime(), rangeStart.getTime())
  const end = Math.min(new Date(endValue).getTime(), rangeEnd.getTime())
  return Number.isFinite(start) && Number.isFinite(end) && end > start ? Math.floor((end - start) / 60000) : 0
}

function sumMinutes(records, rangeStart, rangeEnd, activeClock, now) {
  const recorded = records.reduce((total, record) => {
    if (record.kind === 'break' || !record.start || !record.end) return total
    return total + overlappingMinutes(record.start, record.end, rangeStart, rangeEnd)
  }, 0)
  return activeClock?.status && activeClock.time
    ? recorded + overlappingMinutes(activeClock.time, now, rangeStart, rangeEnd)
    : recorded
}

export default {
  name: 'AdminDashboard',
  components: { AppShell, InitialAvatar, WeeklyHoursChart },
  data() {
    return {
      userId: sessionStorage.getItem('userId'),
      profile: {},
      users: [],
      loadingUsers: true,
      usersError: '',
      selectedStatsUserId: '',
      statsRecords: [],
      statsClock: null,
      statsTeamMembers: [],
      statsLoading: false,
      statsError: '',
      statsRequestId: 0,
      now: new Date(),
      savingRole: false,
      teamActionBusy: false,
      selectedStatsManagerId: '',
      teamActionError: '',
      messageSubject: '',
      messageBody: '',
      messageError: '',
      messageSuccess: '',
      searchQuery: '',
      statusFilter: 'All',
      roleFilter: 'All',
      activeSection: 'teams',
      editingUser: null,
      statsUser: null,
      selectedRole: 'Employee',
      confirmRoleChange: false,
      roleOptions: [
        { name: 'Employee', description: 'Tracks personal time and manages own profile.', iconTone: 'option-member' },
        { name: 'Manager', description: 'Manages a team and reviews team activity.', iconTone: 'option-manager' },
        { name: 'Admin', description: 'Controls workspace settings and access.', iconTone: 'option-admin' }
      ]
    }
  },
  computed: {
    navigation() {
      return [
        { key: 'teams', label: 'Teams', icon: 'teams' },
        { key: 'users', label: 'User management', icon: 'users' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    displayName() {
      return getDisplayName(this.profile, 'Admin User')
    },
    initials() {
      return getInitials(this.displayName, 'AD')
    },
    filteredUsers() {
      const query = this.searchQuery.trim().toLowerCase()
      const roleOrder = { Admin: 0, Manager: 1, Employee: 2 }
      return this.users.filter((user) => {
        const matchesQuery = !query || `${user.name} ${user.email}`.toLowerCase().includes(query)
        const matchesStatus = this.statusFilter === 'All' || user.status === this.statusFilter
        const matchesRole = this.roleFilter === 'All' || user.role === this.roleFilter
        return matchesQuery && matchesStatus && matchesRole
      }).sort((first, second) => {
        const roleDifference = (roleOrder[first.role] ?? 3) - (roleOrder[second.role] ?? 3)
        return roleDifference || first.name.localeCompare(second.name)
      })
    },
    managerTeams() {
      return this.users
        .filter((user) => user.role === 'Manager')
        .sort((first, second) => first.name.localeCompare(second.name))
        .map((manager) => ({
          manager,
          employees: this.users.filter((user) => user.role === 'Employee' && String(user.managerId) === String(manager.id))
        }))
    },
    unassignedEmployees() {
      return this.users.filter((user) => user.role === 'Employee' && !user.managerId)
    },
    isManagerStats() {
      return this.statsUser?.role === 'Manager'
    },
    statsActiveTeamCount() {
      return this.statsTeamMembers.filter((member) => member.status === 'Active').length
    },
    statsTodayMinutes() {
      if (this.isManagerStats) {
        const dayStart = startOfLocalDay(this.now)
        return this.statsTeamMembers.reduce((total, member) => total + sumMinutes(member.records, dayStart, this.now, member.clock, this.now), 0)
      }
      return sumMinutes(this.statsRecords, startOfLocalDay(this.now), this.now, this.statsClock, this.now)
    },
    statsWeekMinutes() {
      if (this.isManagerStats) {
        const weekStart = startOfLocalWeek(this.now)
        return this.statsTeamMembers.reduce((total, member) => total + sumMinutes(member.records, weekStart, this.now, member.clock, this.now), 0)
      }
      return sumMinutes(this.statsRecords, startOfLocalWeek(this.now), this.now, this.statsClock, this.now)
    },
    statsWeekBars() {
      const monday = startOfLocalWeek(this.now)
      const days = Array.from({ length: 7 }, (_, index) => {
        const dayStart = new Date(monday)
        dayStart.setDate(monday.getDate() + index)
        const dayEnd = new Date(dayStart)
        dayEnd.setDate(dayStart.getDate() + 1)
        const end = dayEnd > this.now ? this.now : dayEnd
        const sources = this.isManagerStats ? this.statsTeamMembers : [{ records: this.statsRecords, clock: this.statsClock }]
        const minutes = sources.reduce((total, member) => total + sumMinutes(member.records, dayStart, end, member.clock, this.now), 0)
        return { key: index, label: new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(dayStart), minutes }
      })
      const max = Math.max(...days.map((day) => day.minutes), 1)
      return days.map((day) => ({ ...day, height: day.minutes ? Math.max(8, Math.round(day.minutes / max * 100)) : 0 }))
    }
  },
  mounted() {
    this.loadProfile()
    this.loadUsers()
  },
  methods: {
    navigateSection(section) {
      this.activeSection = section
    },
    async loadProfile() {
      if (!this.userId) return
      try {
        const response = await api.get(`/users/${this.userId}`)
        this.profile = response.data.data || {}
      } catch (error) {
        console.error('Could not load profile:', error)
      }
    },
    async loadUsers() {
      this.loadingUsers = true
      this.usersError = ''
      try {
        const response = await api.get('/users')
        this.users = (response.data.data || []).map((user, index) => {
          const name = getDisplayName(user, 'Unnamed user')
          const initials = getInitials(name, 'U')
          return {
            ...user,
            managerId: user.manager_id,
            name,
            initials,
            role: { admin: 'Admin', manager: 'Manager', employee: 'Employee' }[user.role] || 'Employee',
            status: user.status === 'inactive' ? 'Inactive' : 'Active',
            joined: user.joined_at ? new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: '2-digit', timeZone: 'UTC' }).format(new Date(user.joined_at)) : '—',
            avatarTone: getAvatarTone(index)
          }
        })
      } catch (error) {
        this.usersError = error.response?.status === 403
          ? 'Admin access is required to view workspace users.'
          : 'Could not load users. Please try again.'
      } finally {
        this.loadingUsers = false
      }
    },
    async loadStatistics() {
      const userId = this.selectedStatsUserId
      const requestId = ++this.statsRequestId
      if (!userId) {
        this.statsRecords = []
        this.statsClock = null
        this.statsError = ''
        this.statsLoading = false
        return
      }
      this.statsLoading = true
      this.statsError = ''
      try {
        if (this.statsUser?.role === 'Manager') {
          const employees = this.users.filter((user) => user.role === 'Employee' && String(user.managerId) === String(userId))
          const members = await Promise.all(employees.map(async (employee) => {
            const [recordsResponse, clockResponse] = await Promise.all([
              api.get(`/workingtime/${employee.id}`),
              api.get(`/clocks/${employee.id}`)
            ])
            return { ...employee, records: recordsResponse.data.data || [], clock: clockResponse.data.data }
          }))
          if (requestId !== this.statsRequestId) return
          this.statsTeamMembers = members
          this.statsRecords = []
          this.statsClock = null
        } else {
          const [recordsResponse, clockResponse] = await Promise.all([
            api.get(`/workingtime/${userId}`),
            api.get(`/clocks/${userId}`)
          ])
          if (requestId !== this.statsRequestId) return
          this.statsRecords = recordsResponse.data.data || []
          this.statsClock = clockResponse.data.data
          this.statsTeamMembers = []
        }
        this.now = new Date()
      } catch (error) {
        if (requestId !== this.statsRequestId) return
        this.statsError = error.response?.data?.error || 'Could not load this member’s statistics. Please try again.'
      } finally {
        if (requestId === this.statsRequestId) this.statsLoading = false
      }
    },
    openStatistics(user) {
      this.statsUser = user
      this.selectedStatsUserId = String(user.id)
      this.selectedStatsManagerId = ''
      this.teamActionError = ''
      this.messageSubject = ''
      this.messageBody = ''
      this.messageError = ''
      this.messageSuccess = ''
      this.statsTeamMembers = []
      this.loadStatistics()
    },
    closeStatistics() {
      this.statsUser = null
      this.selectedStatsManagerId = ''
      this.teamActionError = ''
      this.messageError = ''
      this.messageSuccess = ''
      this.statsRequestId += 1
      this.statsLoading = false
    },
    sendStatsMessage() {
      if (!this.statsUser || !this.messageBody.trim()) return
      this.messageError = ''
      this.messageSuccess = ''
      try {
        window.location.href = createEmailDraftUrl(this.statsUser.email, this.messageSubject, this.messageBody)
        this.messageSuccess = 'Your email draft should open in your email app. Send it there to deliver your message.'
      } catch (error) {
        this.messageError = 'Could not open an email draft. Please check the recipient address and your email app.'
      }
    },
    formatMinutes(minutes) {
      const safeMinutes = Math.max(0, Math.floor(minutes || 0))
      return `${Math.floor(safeMinutes / 60)}h ${String(safeMinutes % 60).padStart(2, '0')}m`
    },
    roleClass(role) {
      return { Admin: 'role-admin', Manager: 'role-manager', Employee: 'role-member' }[role] || 'role-member'
    },
    isCurrentUser(user) {
      return String(user.id) === String(this.userId)
    },
    openRoleEditor(user) {
      this.editingUser = user
      this.selectedRole = user.role
      this.confirmRoleChange = false
    },
    closeRoleEditor() {
      this.editingUser = null
      this.confirmRoleChange = false
    },
    async saveRoleChange() {
      if (!this.editingUser || !this.confirmRoleChange || this.savingRole) return
      this.savingRole = true
      this.usersError = ''
      try {
        const role = { Admin: 'admin', Manager: 'manager', Employee: 'employee' }[this.selectedRole]
        await api.patch(`/users/${this.editingUser.id}`, { user: { role } })
        this.editingUser.role = this.selectedRole
        this.closeRoleEditor()
      } catch (error) {
        this.usersError = error.response?.status === 403
          ? 'Admin access is required to change a user role.'
          : 'Could not save this role change. Please try again.'
      } finally {
        this.savingRole = false
      }
    },
    async addStatsUserToTeam() {
      if (!this.statsUser || !this.selectedStatsManagerId) return
      await this.updateTeamAssignment(this.statsUser, this.selectedStatsManagerId)
    },
    async updateTeamAssignment(employee, managerId) {
      if (this.teamActionBusy) return
      this.teamActionBusy = true
      this.teamActionError = ''
      try {
        await api.patch(`/users/${employee.id}`, { user: { manager_id: managerId } })
        employee.managerId = managerId
        employee.manager_id = managerId
        if (this.statsUser && String(this.statsUser.id) === String(employee.id)) {
          this.statsUser.managerId = managerId
          this.statsUser.manager_id = managerId
        }
        this.selectedStatsManagerId = ''
      } catch (error) {
        this.teamActionError = error.response?.data?.error || 'Could not update this team assignment. Please try again.'
      } finally {
        this.teamActionBusy = false
      }
    },
    async toggleUserStatus(user) {
      if (user.actionBusy || this.isCurrentUser(user)) return
      const nextStatus = user.status === 'Active' ? 'Inactive' : 'Active'
      user.actionBusy = true
      this.usersError = ''
      try {
        await api.patch(`/users/${user.id}`, { user: { status: nextStatus.toLowerCase() } })
        user.status = nextStatus
      } catch (error) {
        this.usersError = error.response?.data?.error || 'Could not update this account status. Please try again.'
      } finally {
        user.actionBusy = false
      }
    },
    async deleteUser(user) {
      if (user.actionBusy || this.isCurrentUser(user)) return
      const confirmed = window.confirm(`Delete ${user.name} (${user.email}) and their clock and work-time records permanently? This cannot be undone.`)
      if (!confirmed) return

      user.actionBusy = true
      this.usersError = ''
      try {
        await api.delete(`/users/${user.id}`)
        this.users = this.users.filter((currentUser) => currentUser.id !== user.id)
      } catch (error) {
        this.usersError = error.response?.data?.error || 'Could not delete this user. Please try again.'
      } finally {
        user.actionBusy = false
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
    }
  }
}
</script>

<style scoped>
.admin-content {
  --admin-ink: var(--app-text);
  --admin-muted: var(--app-muted);
  --admin-faint: #929dad;
  --admin-line: var(--app-border);
  --admin-surface: var(--app-surface);
  --admin-canvas: var(--app-background);
  --admin-primary: var(--app-accent);
  color: var(--admin-ink);
  font-family: inherit;
  font-size: 14px;
}
.stats-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 13px; margin: 0 0 18px; }
.stat-card { min-width: 0; padding: 16px 18px; border: 1px solid var(--app-border); border-radius: 12px; background: var(--app-surface); box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.stat-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.stat-icon { display: grid; width: 32px; height: 32px; place-items: center; border-radius: 9px; }
.stat-icon svg { width: 18px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.stat-icon-violet { color: #6657d9; background: #efedff; }
.stat-icon-green { color: #17976f; background: #e8f8f1; }
.stat-icon-blue { color: #3b78d4; background: #e9f2ff; }
.stat-icon-amber { color: #b98227; background: #fff5df; }
.stat-card > strong { display: block; color: var(--app-text); font-size: 25px; font-weight: 730; letter-spacing: -.5px; }
.stat-label { display: block; margin-top: 3px; color: var(--app-muted); font-size: 12px; }
.admin-profile-section { max-width: 720px; }
.profile-page-heading { margin-bottom: 20px; }
.profile-page-heading h2 { margin: 0; color: var(--app-text); font-size: 28px; letter-spacing: -.6px; }
.profile-page-heading > p:last-child { margin: 6px 0 0; color: var(--app-muted); font-size: 14px; }
.profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: var(--app-surface); box-shadow: var(--app-shadow-profile); }
.profile-avatar { display: grid; width: 62px; height: 62px; flex: 0 0 62px; place-items: center; border-radius: 50%; color: #fff; background: var(--app-accent); font-size: 19px; font-weight: 700; }
.profile-card h3 { margin: 0 0 6px; color: var(--app-text); font-size: 18px; }
.profile-card p { margin: 0; color: var(--app-muted); font-size: 14px; }
.profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid var(--app-border); border-radius: 11px; color: #48515c; background: var(--app-surface); font: inherit; font-weight: 600; cursor: pointer; transition: background .16s ease, border-color .16s ease; }
.profile-logout:hover, .profile-logout:focus-visible { border-color: #d2d8e2; background: #f7f9fc; outline: none; }
.admin-content { width: 100%; margin: 0; padding: 0; }
.page-intro { display: flex; align-items: flex-end; justify-content: space-between; gap: 20px; margin-bottom: 25px; }
.admin-eyebrow { margin: 0 0 8px; color: #818da0; font-size: 9px; font-weight: 750; letter-spacing: 1.2px; }
.page-intro h1 { margin: 0; color: #192432; font-size: clamp(24px, 2.2vw, 30px); font-weight: 740; letter-spacing: -.9px; }
.intro-copy { margin: 7px 0 0; color: #7b8797; font-size: 12px; }
.inline-notice { margin: -10px 0 18px; padding: 10px 13px; border: 1px solid #dfe4fb; border-radius: 8px; color: #4959bd; background: #f3f5ff; font-size: 11px; }
.stats-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 13px; margin-bottom: 19px; }
.stat-card { min-width: 0; padding: 14px 16px 15px; border: 1px solid #e8ecf2; border-radius: 10px; background: #fff; box-shadow: 0 2px 7px rgb(25 38 60 / 2%); }
.stat-top { display: flex; align-items: center; justify-content: space-between; gap: 7px; margin-bottom: 12px; }
.stat-icon { display: grid; width: 29px; height: 29px; place-items: center; border-radius: 8px; }
.stat-icon svg { width: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.stat-icon-violet { color: #6657d9; background: #efedff; }
.stat-icon-green { color: #17976f; background: #e8f8f1; }
.stat-icon-blue { color: #3b78d4; background: #e9f2ff; }
.stat-icon-amber { color: #b98227; background: #fff5df; }
.stat-change { color: #188460; font-size: 9px; font-weight: 650; }
.stat-change i { font-size: 11px; font-style: normal; }
.stat-period { overflow: hidden; color: #969faf; font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.stat-card > strong { display: block; color: #202b3a; font-size: 23px; font-weight: 730; letter-spacing: -.5px; }
.stat-label { display: block; margin-top: 3px; color: #7f8a9a; font-size: 10px; }
.teams-section { margin: 0 0 20px; }
.teams-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin: 3px 0 14px; }
.teams-heading h2 { margin: 0; color: #202b3a; font-size: 18px; font-weight: 720; letter-spacing: -.35px; }
.teams-heading p:last-child { margin: 5px 0 0; color: #7f8a9a; font-size: 11px; }
.teams-total { padding: 7px 10px; border: 1px solid #e8ecf2; border-radius: 8px; color: #697587; background: #fff; font-size: 10px; }
.teams-grid { display: grid; grid-template-columns: 1fr; gap: 14px; }
.team-card, .unassigned-card { min-width: 0; padding: 16px; border: 1px solid #e6eaf0; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.team-manager { display: flex; align-items: center; gap: 10px; padding-bottom: 14px; border-bottom: 1px solid #eef0f4; }
.team-manager .role-badge { margin-left: auto; }
.team-remove { padding: 6px 9px; border: 1px solid #f0dada; border-radius: 6px; color: #a54b4b; background: #fff; font: inherit; font-size: 9px; font-weight: 650; cursor: pointer; }
.team-remove { margin-left: auto; color: #a54b4b; border-color: #f0dada; }
.team-members-heading { display: flex; align-items: center; gap: 8px; margin: 14px 0 3px; color: #8994a3; font-size: 8px; font-weight: 750; letter-spacing: .8px; }
.team-members { margin: 0; padding: 0; list-style: none; }
.team-members li { display: flex; min-width: 0; align-items: center; gap: 9px; padding: 10px 0; border-bottom: 1px solid #f0f2f5; }
.team-members li:last-child { border-bottom: 0; }
.team-members .user-avatar { width: 29px; height: 29px; flex-basis: 29px; }
.team-members .user-identity { min-width: 0; }
.team-members .user-identity strong, .team-members .user-identity small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.team-members .status-badge { margin-left: auto; }
.team-empty-members, .teams-empty { margin: 0; padding: 18px 0; color: #8994a3; font-size: 11px; }
.teams-empty { padding: 25px; border: 1px dashed #dfe4eb; border-radius: 10px; background: #fff; text-align: center; }
.unassigned-card { margin-top: 14px; }
.unassigned-card h3 { display: flex; align-items: center; gap: 8px; margin: 0; color: #354052; font-size: 12px; }
.users-panel { overflow: hidden; border: 1px solid #e6eaf0; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.panel-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 19px 20px 15px; }
.panel-heading h2 { display: flex; align-items: center; gap: 8px; margin: 0; color: #273243; font-size: 14px; font-weight: 700; }
.panel-heading p { margin: 5px 0 0; color: #8a95a4; font-size: 10px; }
.count-pill { padding: 3px 7px; border-radius: 999px; color: #626f80; background: #f0f2f5; font-size: 9px; font-weight: 650; }
.table-toolbar { display: flex; align-items: center; gap: 8px; padding: 0 20px 13px; }
.search-box, .filter-select, .filter-role { display: flex; min-height: 33px; align-items: center; gap: 8px; border: 1px solid #e4e8ee; border-radius: 7px; color: #7b8798; background: #fff; }
.search-box { width: min(100%, 290px); padding: 0 9px; }
.search-box:focus-within { border-color: #8992e7; box-shadow: 0 0 0 3px rgb(70 87 216 / 9%); }
.search-box svg, .filter-select > svg:first-child, .filter-role > svg:first-child { width: 15px; flex: 0 0 15px; fill: none; stroke: #929cad; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.search-box input { width: 100%; min-width: 0; border: 0; outline: 0; color: #354153; background: transparent; font: inherit; font-size: 10px; }
.search-box input::placeholder { color: #a1a9b5; }
.filter-select, .filter-role { position: relative; min-width: 120px; padding: 0 9px; }
.filter-select select { width: 100%; appearance: none; border: 0; outline: 0; color: #566274; background: transparent; font: inherit; font-size: 10px; cursor: pointer; }
.select-chevron { width: 13px; flex: 0 0 13px; fill: none; stroke: #959eac; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; pointer-events: none; }
.filter-role { min-width: 103px; justify-content: space-between; font: inherit; font-size: 10px; cursor: pointer; transition: background .16s ease; }
.filter-role:hover, .filter-role.selected { background: #f8f9ff; }
.table-scroll { width: 100%; overflow-x: auto; }
.users-table { width: 100%; border-collapse: collapse; text-align: left; white-space: nowrap; }
.users-table thead { background: #fafbfc; }
.users-table th { height: 34px; padding: 0 13px; border-top: 1px solid #eef0f4; border-bottom: 1px solid #eef0f4; color: #8994a3; font-size: 8px; font-weight: 750; letter-spacing: .75px; }
.users-table th:first-child, .users-table td:first-child { padding-left: 20px; }
.users-table th button { margin-left: 4px; border: 0; color: #a9b0bd; background: none; font: inherit; cursor: pointer; }
.user-column { width: 39%; }
.users-table td { height: 58px; padding: 0 13px; border-bottom: 1px solid #eff1f5; color: #556172; font-size: 10px; }
.users-table tbody tr:last-child td { border-bottom: 0; }
.users-table tbody tr { transition: background .14s ease; }
.users-table tbody tr:hover { background: #fbfcfe; }
.user-cell { display: flex; align-items: center; gap: 10px; }
.user-stats-trigger { display: flex; min-width: 0; align-items: center; gap: 10px; padding: 0; border: 0; color: inherit; background: transparent; font: inherit; text-align: left; cursor: pointer; }
.user-stats-trigger:focus-visible { border-radius: 8px; outline: 2px solid var(--app-accent); outline-offset: 3px; }
.user-stats-trigger:hover .user-identity strong { color: var(--app-accent-strong); }
.team-stats-trigger { flex: 1; }
.user-avatar, .drawer-avatar { display: grid; width: 32px; height: 32px; flex: 0 0 32px; place-items: center; border: 1px solid rgb(35 49 70 / 5%); border-radius: 50%; font-size: 9px; font-weight: 700; }
.user-identity { display: grid; gap: 4px; }
.user-identity strong { color: #354153; font-size: 10px; font-weight: 650; }
.user-identity small { color: #8b96a5; font-size: 9px; }
.tone-lilac { color: #5d4db1; background: #efebff; }
.tone-peach { color: #a95236; background: #fff0e8; }
.tone-mint { color: #247458; background: #e7f7ef; }
.tone-sky { color: #3869a5; background: #e8f2ff; }
.tone-rose { color: #a94a70; background: #ffedf3; }
.tone-gold { color: #8a6827; background: #fff5d9; }
.tone-blue { color: #4260a9; background: #e8eeff; }
.role-badge { display: inline-flex; min-height: 23px; align-items: center; gap: 5px; padding: 0 8px; border: 1px solid transparent; border-radius: 999px; font-size: 9px; font-weight: 650; }
.role-badge svg { width: 12px; height: 12px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.role-admin { border-color: #e7e1ff; color: #6551c8; background: #f3f0ff; }
.role-manager { border-color: #d7e9ff; color: #3671b6; background: #eff7ff; }
.role-member { border-color: #e5e8ed; color: #657082; background: #f5f6f8; }
.status-badge { display: inline-flex; align-items: center; gap: 6px; color: #647181; font-size: 9px; }
.status-badge i { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.status-active { color: #18835f; }
.status-inactive { color: #9ba3af; }
.joined-cell { color: #697587 !important; }
.actions-heading { width: 235px; text-align: right; padding-right: 20px !important; }
.action-cell { padding-right: 20px !important; }
.action-buttons { display: flex; align-items: center; justify-content: flex-end; gap: 5px; }
.manage-button { min-height: 27px; padding: 0 9px; border: 1px solid #e1e5ec; border-radius: 6px; color: #4e5a6b; background: #fff; font: inherit; font-size: 9px; font-weight: 620; cursor: pointer; transition: color .15s ease, border .15s ease, background .15s ease; }
.manage-button:hover, .manage-button:focus-visible { border-color: #c9cef4; color: #4657d8; background: #f8f8ff; outline: none; }
.user-action-button { min-height: 27px; padding: 0 8px; border: 1px solid transparent; border-radius: 6px; font: inherit; font-size: 9px; font-weight: 680; cursor: pointer; transition: background .15s ease, border .15s ease, opacity .15s ease; }
.user-action-button:disabled, .manage-button:disabled { cursor: not-allowed; opacity: .52; }
.suspend-button { border-color: #f0d58a; color: #87600b; background: #fff7df; }
.suspend-button:hover:not(:disabled) { border-color: #e4c35b; background: #ffefbd; }
.activate-button { border-color: #bfe4d4; color: #16734f; background: #eaf8f1; }
.activate-button:hover:not(:disabled) { border-color: #91d1b5; background: #d9f2e6; }
.delete-button { border-color: #f3c9c8; color: #b42323; background: #fff1f0; }
.delete-button:hover:not(:disabled) { border-color: #e7aaa8; background: #ffe2df; }
.empty-row { height: 90px !important; color: #8994a3 !important; text-align: center; }
.drawer-backdrop { position: fixed; z-index: 20; inset: 0; display: flex; justify-content: flex-end; background: rgb(18 25 38 / 38%); backdrop-filter: blur(2px); }
.role-drawer { display: flex; width: min(100%, 465px); height: 100%; flex-direction: column; background: #fff; box-shadow: -14px 0 40px rgb(19 28 44 / 13%); }
.drawer-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 15px; padding: 25px 26px 19px; border-bottom: 1px solid #edf0f4; }
.drawer-eyebrow { margin: 0 0 7px; color: #7685d8; font-size: 9px; font-weight: 750; letter-spacing: 1.1px; }
.drawer-header h2 { margin: 0; color: #202b3a; font-size: 19px; font-weight: 720; letter-spacing: -.45px; }
.drawer-header > div > p:last-child { margin: 6px 0 0; color: #8590a0; font-size: 11px; }
.drawer-close { display: grid; width: 30px; height: 30px; place-items: center; border: 1px solid #e7eaf0; border-radius: 7px; color: #788495; background: white; cursor: pointer; }
.drawer-close:hover { color: #344054; background: #f6f7f9; }
.drawer-close svg { width: 15px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-width: 1.8; }
.drawer-body { flex: 1; overflow-y: auto; padding: 21px 26px; }
.drawer-user-summary { display: flex; align-items: center; gap: 10px; padding: 13px; border: 1px solid #e9edf3; border-radius: 9px; background: #fafbfc; }
.drawer-avatar { width: 38px; height: 38px; flex-basis: 38px; font-size: 10px; }
.drawer-user-summary > span:nth-child(2) { display: grid; min-width: 0; gap: 4px; }
.drawer-user-summary > span:nth-child(2) strong { overflow: hidden; color: #344054; font-size: 11px; text-overflow: ellipsis; white-space: nowrap; }
.drawer-user-summary > span:nth-child(2) small { overflow: hidden; color: #8993a3; font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.drawer-user-summary > .role-badge { margin-left: auto; white-space: nowrap; }
.role-fieldset { min-width: 0; margin: 25px 0 0; padding: 0; border: 0; }
.role-fieldset legend { margin: 0; color: #273243; font-size: 12px; font-weight: 700; }
.field-hint { margin: 5px 0 12px; color: #8994a3; font-size: 10px; }
.role-option { display: flex; min-height: 66px; align-items: center; gap: 10px; margin-top: 8px; padding: 10px 11px; border: 1px solid #e6eaf0; border-radius: 8px; cursor: pointer; transition: border .15s ease, background .15s ease, box-shadow .15s ease; }
.role-option:hover { border-color: #cdd2f6; background: #fbfbff; }
.role-option-selected { border-color: #777fe0; background: #f7f7ff; box-shadow: 0 0 0 2px rgb(70 87 216 / 8%); }
.role-option > input { position: absolute; width: 1px; height: 1px; opacity: 0; }
.role-option:focus-within { outline: 3px solid rgb(70 87 216 / 17%); outline-offset: 2px; }
.role-option-icon { display: grid; width: 33px; height: 33px; flex: 0 0 33px; place-items: center; border-radius: 8px; }
.role-option-icon svg { width: 17px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.65; }
.option-member { color: #677486; background: #f0f2f5; }
.option-manager { color: #3475bf; background: #eaf3ff; }
.option-admin { color: #6653c7; background: #efecff; }
.role-option-copy { display: grid; flex: 1; gap: 4px; }
.role-option-copy strong { color: #344054; font-size: 10px; font-weight: 680; }
.role-option-copy small { color: #8792a1; font-size: 9px; line-height: 1.45; }
.custom-radio { display: grid; width: 16px; height: 16px; flex: 0 0 16px; place-items: center; border: 1px solid #cdd3dd; border-radius: 50%; background: white; }
.role-option-selected .custom-radio { border: 5px solid #4657d8; }
.privilege-note { display: flex; gap: 10px; margin-top: 18px; padding: 12px; border: 1px solid #dce7f7; border-radius: 8px; color: #405b84; background: #f2f7ff; }
.privilege-note-admin { border-color: #e5defb; color: #6550ac; background: #f7f4ff; }
.privilege-note-manager { border-color: #dce9f7; color: #405b84; background: #f2f7ff; }
.privilege-icon { display: grid; width: 27px; height: 27px; flex: 0 0 27px; place-items: center; border-radius: 7px; background: rgb(255 255 255 / 75%); }
.privilege-icon svg { width: 15px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.privilege-note > span:last-child { display: grid; gap: 4px; }
.privilege-note strong { color: inherit; font-size: 10px; font-weight: 700; }
.privilege-note small { color: inherit; font-size: 9px; line-height: 1.5; opacity: .82; }
.confirm-toggle { display: flex; align-items: center; gap: 9px; margin-top: 17px; color: #667284; font-size: 9px; line-height: 1.4; cursor: pointer; }
.confirm-toggle input { position: absolute; width: 1px; height: 1px; opacity: 0; }
.confirm-toggle input:focus-visible + .toggle-track { outline: 3px solid rgb(70 87 216 / 22%); outline-offset: 2px; }
.toggle-track { position: relative; width: 30px; height: 17px; flex: 0 0 30px; border-radius: 99px; background: #cbd2dd; transition: background .18s ease; }
.toggle-track i { position: absolute; top: 3px; left: 3px; width: 11px; height: 11px; border-radius: 50%; background: white; box-shadow: 0 1px 2px rgb(0 0 0 / 15%); transition: transform .18s ease; }
.confirm-toggle input:checked + .toggle-track { background: #4657d8; }
.confirm-toggle input:checked + .toggle-track i { transform: translateX(13px); }
.drawer-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 14px 26px; border-top: 1px solid #edf0f4; background: #fff; }
.cancel-button, .save-role-button { display: inline-flex; min-height: 36px; align-items: center; justify-content: center; gap: 7px; padding: 0 12px; border-radius: 7px; font: inherit; font-size: 10px; font-weight: 650; cursor: pointer; transition: background .15s ease, border .15s ease, opacity .15s ease; }
.cancel-button { border: 1px solid #e2e6ed; color: #5d6878; background: white; }
.cancel-button:hover { background: #f8f9fb; }
.save-role-button { border: 1px solid #4657d8; color: white; background: #4657d8; }
.save-role-button:hover:not(:disabled) { background: #3949c1; }
.save-role-button:disabled { cursor: not-allowed; opacity: .48; }
.save-role-button svg { width: 14px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 2; }
.drawer-fade-enter-active, .drawer-fade-leave-active { transition: opacity .2s ease; }
.drawer-fade-enter-active .role-drawer, .drawer-fade-leave-active .role-drawer { transition: transform .24s cubic-bezier(.22,.75,.25,1); }
.drawer-fade-enter-from, .drawer-fade-leave-to { opacity: 0; }
.drawer-fade-enter-from .role-drawer, .drawer-fade-leave-to .role-drawer { transform: translateX(30px); }

/* Shared app theme: match the employee workspace palette and type scale. */
.admin-content { padding: 0; }
.admin-eyebrow { font-size: 10px; }
.page-intro h1 { color: var(--app-text); font-size: clamp(28px, 3vw, 34px); letter-spacing: -.8px; }
.intro-copy { color: var(--app-muted); font-size: 14px; }
.stat-card { border-color: var(--app-border); border-radius: 12px; padding: 17px 18px; }
.stat-card > strong { color: var(--app-text); font-size: 27px; }
.stat-label { color: var(--app-muted); font-size: 12px; }
.stat-period, .stat-change { font-size: 10px; }
.users-panel, .team-card, .unassigned-card { border-color: var(--app-border); border-radius: 12px; }
.panel-heading { padding: 20px 20px 16px; }
.panel-heading h2 { color: var(--app-text); font-size: 16px; }
.panel-heading p, .teams-heading p:last-child { color: var(--app-muted); font-size: 12px; }
.teams-heading h2 { font-size: 20px; }
.teams-total { font-size: 11px; }
.team-manager .user-identity strong, .user-identity strong { font-size: 12px; }
.team-manager .user-identity small, .user-identity small { font-size: 10px; }
.team-members-heading { font-size: 9px; }
.team-members li { padding: 12px 0; }
.team-members .user-avatar { width: 34px; height: 34px; flex-basis: 34px; font-size: 10px; }
.team-members .status-badge, .status-badge { font-size: 11px; }
.table-toolbar { padding-bottom: 15px; }
.search-box, .filter-select, .filter-role { min-height: 38px; border-color: var(--app-border); border-radius: 8px; }
.search-box input, .filter-select select, .filter-role { font-size: 12px; }
.search-box:focus-within { border-color: var(--app-accent); box-shadow: 0 0 0 3px rgb(22 132 248 / 12%); }
.filter-role:hover, .filter-role.selected { background: var(--app-accent-soft); }
.users-table thead { background: #f7f9f8; }
.users-table th { height: 40px; border-color: var(--app-border); font-size: 10px; }
.users-table td { height: 64px; font-size: 12px; }
.user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 10px; }
.role-badge { min-height: 25px; font-size: 10px; }
.manage-button, .user-action-button { min-height: 32px; font-size: 10px; }
.drawer-header h2 { font-size: 21px; }
.drawer-header > div > p:last-child { font-size: 13px; }
.drawer-user-summary > span:nth-child(2) strong { font-size: 13px; }
.drawer-user-summary > span:nth-child(2) small, .field-hint { font-size: 11px; }
.role-fieldset legend { font-size: 14px; }
.role-option-copy strong { font-size: 12px; }
.role-option-copy small, .privilege-note small { font-size: 11px; }
.privilege-note strong { font-size: 12px; }
.confirm-toggle { font-size: 11px; }
.cancel-button, .save-role-button { min-height: 39px; font-size: 12px; }

@media (max-width: 1050px) {
  .users-table th, .users-table td { padding-right: 9px; padding-left: 9px; }
  .users-table th:first-child, .users-table td:first-child { padding-left: 14px; }
  .actions-heading, .action-cell { padding-right: 14px !important; }
}
@media (max-width: 760px) {
  .stats-grid { gap: 10px; }
  .stat-card { padding: 13px 14px; }
  .stat-card > strong { font-size: 22px; }
  .stat-label { font-size: 11px; }
  .teams-heading { align-items: flex-start; flex-direction: column; }
  .table-toolbar { flex-wrap: wrap; padding-right: 13px; padding-left: 13px; }
  .search-box { flex: 1 1 100%; width: 100%; }
  .panel-heading { padding-right: 13px; padding-left: 13px; }
  .table-scroll { overflow: visible; padding: 0 10px 10px; }
  .users-table { display: block; width: 100%; min-width: 0; white-space: normal; }
  .users-table thead { display: none; }
  .users-table tbody { display: grid; gap: 8px; }
  .users-table tbody tr {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    row-gap: 3px;
    column-gap: 12px;
    padding: 10px 14px;
    border: 1px solid var(--app-border);
    border-radius: 11px;
    background: var(--app-surface);
    box-shadow: 0 1px 4px rgb(27 41 61 / 3%);
  }
  .users-table tbody tr:hover { background: var(--app-surface); }
  .users-table td {
    display: block !important;
    height: auto !important;
    min-height: 0 !important;
    padding: 0 !important;
    margin: 0 !important;
    border: 0 !important;
    font-size: 11px;
  }
  .users-table td:first-child { grid-column: 1; grid-row: 1; min-width: 0; align-self: center; }
  .users-table td:nth-child(3) { grid-column: 2; grid-row: 1; justify-self: end; align-self: center; }
  .users-table td:nth-child(3)::before { display: none; }
  .users-table .joined-cell { grid-column: 1; grid-row: 2; font-size: 11px; color: var(--app-muted); line-height: 1.2; margin: 2px 0 0 !important; }
  .users-table .joined-cell::before { content: 'Joined '; color: var(--app-muted); font-size: 11px; }
  .users-table td:nth-child(2) { grid-column: 1; grid-row: 3; justify-self: start; align-self: center; margin: 2px 0 0 !important; }
  .users-table td:nth-child(2)::before { display: none; }
  .users-table td:nth-child(2) .role-badge { min-height: 22px; padding: 0 7px; font-size: 10px; }
  .users-table .action-cell { grid-column: 2; grid-row: 2 / span 2; justify-self: end; align-self: center; padding: 0 !important; }
  .action-buttons { display: flex; align-items: center; gap: 5px; }
  .manage-button, .user-action-button { min-width: 0; min-height: 28px !important; padding: 0 8px !important; border-radius: 6px; font-size: 11px; }
  .users-table tbody tr:has(.empty-row) { display: block; }
  .users-table .empty-row { display: block; padding: 22px 8px !important; }
}
@media (max-width: 480px) {
  .stats-grid { gap: 9px; }
  .stat-card { padding: 12px; }
  .stat-icon { width: 29px; height: 29px; }
  .page-intro { align-items: flex-start; }
  .page-intro h1 { font-size: 25px; }
  .intro-copy { max-width: 300px; font-size: 13px; line-height: 1.5; }
  .filter-select, .filter-role { flex: 1; min-width: 0; }
  .panel-heading h2 { font-size: 13px; }
  .role-drawer { width: 100%; }
  .drawer-header { padding-right: 18px; padding-left: 18px; }
  .drawer-body { padding-right: 18px; padding-left: 18px; }
  .drawer-footer { padding-right: 18px; padding-left: 18px; }
  .teams-total { white-space: normal; }
}

/* Keep admin cards, controls, and tables aligned with the shared light workspace UI. */
.admin-content { color: var(--app-text); }
.page-intro h1 { letter-spacing: -.7px; }
.page-intro { margin-bottom: 22px; }
.stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; margin-bottom: 20px; }
.stat-card { min-height: 124px; padding: 17px 18px; border-radius: 17px; box-shadow: var(--app-shadow-panel); }
.stat-top { margin-bottom: 12px; }
.stat-icon { width: 36px; height: 36px; border-radius: 11px; }
.stat-icon svg { width: 19px; }
.stat-card > strong { font-size: 25px; }
.stat-label { font-size: 12px; }
.teams-section { margin-top: 0; }
.teams-heading h2 { font-size: 20px; }
.teams-heading p:last-child { font-size: 12px; }
.teams-total { border-radius: 10px; font-size: 11px; }
.team-card, .unassigned-card, .users-panel { border-radius: 17px; box-shadow: var(--app-shadow-panel); }
.team-card, .unassigned-card { padding: 19px; }
.team-members-heading { font-size: 10px; }
.team-members li { padding: 12px 0; }
.team-members .user-avatar { width: 34px; height: 34px; flex-basis: 34px; }
.team-members .user-identity strong { font-size: 12px; }
.team-members .user-identity small { font-size: 10px; }
.panel-heading { padding-top: 21px; }
.panel-heading h2 { font-size: 16px; }
.panel-heading p { font-size: 12px; }
.search-box, .filter-select, .filter-role { min-height: 42px; border-radius: 10px; }
.search-box input, .filter-select select, .filter-role { font-size: 12px; }
.users-table th { height: 42px; font-size: 10px; }
.users-table td { height: 64px; font-size: 12px; }
.user-avatar { width: 38px; height: 38px; flex-basis: 38px; font-size: 11px; }
.user-identity strong { font-size: 12px; }
.user-identity small { font-size: 10px; }
.role-badge { min-height: 27px; padding-inline: 10px; font-size: 11px; }
.status-badge { font-size: 11px; }
.manage-button, .user-action-button { min-height: 35px; padding-inline: 10px; border-radius: 9px; font-size: 11px; }

/* Match the manager's team table surface and row rhythm while retaining admin controls. */
.users-panel { border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: var(--app-surface); box-shadow: var(--app-shadow-panel); }
.panel-heading { padding: 18px 20px 8px; }
.panel-heading h2 { color: var(--app-text); font-size: 16px; }
.panel-heading p { color: var(--app-muted); font-size: 12px; }
.table-toolbar { flex-wrap: wrap; gap: 8px; padding: 8px 20px 16px; border-bottom: 1px solid var(--app-border); }
.search-box, .filter-select, .filter-role { min-height: 38px; border-color: var(--app-border); border-radius: 9px; background: var(--app-surface); }
.users-table thead { background: var(--app-background); }
.users-table th { height: 42px; border-color: var(--app-border); color: var(--app-muted); font-size: 10px; }
.users-table td { height: 64px; border-color: var(--app-border); color: var(--app-text); font-size: 12px; }
.users-table tbody tr:hover { background: #f8fbff; }
.user-column { width: 34%; }
.user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 10px; }
.user-identity strong { color: var(--app-text); font-size: 12px; }
.user-identity small { color: var(--app-muted); font-size: 10px; }
.role-badge { min-height: 25px; font-size: 10px; }
.status-badge { font-size: 11px; }
.action-buttons { display: flex; align-items: center; gap: 6px; }
.manage-button, .user-action-button { min-height: 34px; padding-inline: 10px; border-radius: 9px; font-size: 10px; }

@media (max-width: 760px) {
  .panel-heading { padding: 16px 14px 8px; }
  .table-toolbar { padding: 8px 14px 14px; }
  .users-panel { border-radius: 17px; }
  .stats-grid { gap: 10px; }
  .stat-card { min-height: 112px; padding: 14px; border-radius: 15px; }
  .stat-icon { width: 32px; height: 32px; }
  .stat-card > strong { font-size: 23px; }
  .stat-label { font-size: 11px; }
  .users-table tbody tr { gap: 6px 10px; padding: 10px 14px; border-radius: 10px; box-shadow: 0 2px 8px rgb(27 41 61 / 3%); }
  .users-table td { font-size: 11px; }
  .action-buttons { gap: 5px; }
  .manage-button, .user-action-button { min-height: 28px; font-size: 10.5px; }
  .teams-grid { grid-template-columns: 1fr; }
}
@media (max-width: 480px) {
  .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
  .stat-card { min-height: 104px; padding: 11px; }
  .stat-card > strong { font-size: 21px; }
  .stat-label { font-size: 10px; }
  .team-manager { gap: 9px; }
  .team-manager .user-identity strong { font-size: 12px; }
  .team-manager .user-identity small { overflow-wrap: anywhere; white-space: normal; }
  .search-box, .filter-select, .filter-role { min-height: 43px; }
}

/* Larger, clearer text and controls across administrator pages. */
.page-intro { margin-bottom: 28px; }
.admin-eyebrow { font-size: 11px; letter-spacing: 1.3px; }
.page-intro h1 { font-size: clamp(32px, 3.2vw, 40px); }
.intro-copy { font-size: 15px; line-height: 1.55; }
.teams-section { font-size: 15px; }
.team-card, .unassigned-card { padding: 24px; }
.team-manager .user-avatar { width: 44px; height: 44px; flex-basis: 44px; font-size: 12px; }
.team-manager .user-identity strong, .team-members .user-identity strong { font-size: 15px; }
.team-manager .user-identity small, .team-members .user-identity small { font-size: 12px; }
.role-badge { min-height: 30px; padding-inline: 12px; font-size: 12px; }
.team-members-heading { margin-top: 17px; font-size: 12px; }
.team-members li { gap: 12px; padding: 14px 0; }
.team-members .user-avatar { width: 40px; height: 40px; flex-basis: 40px; font-size: 11px; }
.status-badge { min-height: 26px; padding: 4px 10px; font-size: 12px; }
.team-empty-members, .teams-empty { font-size: 14px; }
.unassigned-card h3 { font-size: 16px; }
.panel-heading { padding: 21px 22px 10px; }
.panel-heading h2 { font-size: 19px; }
.panel-heading p { font-size: 14px; }
.table-toolbar { gap: 10px; padding: 10px 22px 18px; }
.search-box, .filter-select, .filter-role { min-height: 46px; gap: 10px; padding-inline: 12px; }
.search-box input, .filter-select select, .filter-role { font-size: 14px; }
.search-box svg, .filter-select > svg:first-child, .filter-role > svg:first-child { width: 18px; flex-basis: 18px; }
@media (min-width: 1000px) {
  .users-table th { height: 48px; font-size: 12px; }
  .users-table td { height: 74px; font-size: 14px; }
  .manage-button, .user-action-button { min-height: 40px; padding-inline: 12px; font-size: 12px; }
}
.user-avatar { width: 42px; height: 42px; flex-basis: 42px; font-size: 12px; }
.user-identity strong { font-size: 14px; }
.user-identity small { font-size: 12px; }
.role-badge { min-height: 25px; font-size: 11px; }
.status-badge { font-size: 12px; }
.drawer-header { padding: 26px 28px 21px; }
.drawer-body { padding: 24px 28px; }
.drawer-footer { padding: 17px 28px; }
.drawer-header h2 { font-size: 24px; }
.drawer-header > div > p:last-child, .field-hint { font-size: 14px; }
.role-fieldset legend { font-size: 16px; }
.role-option { min-height: 74px; padding: 14px; }
.role-option-copy strong, .privilege-note strong { font-size: 14px; }
.role-option-copy small, .privilege-note small { font-size: 13px; }
.confirm-toggle { font-size: 13px; }
.cancel-button, .save-role-button { min-height: 46px; font-size: 14px; }
.profile-page-heading h2 { font-size: 32px; }
.profile-page-heading > p:last-child, .profile-card p { font-size: 16px; }
.profile-card { padding: 28px; }
.profile-card h3 { font-size: 21px; }
.profile-logout { min-height: 50px; font-size: 15px; }

@media (max-width: 760px) {
  .team-card, .unassigned-card { padding: 19px; }
  .panel-heading { padding: 17px 15px 9px; }
  .table-toolbar { padding: 9px 15px 16px; }
}

@media (max-width: 480px) {
  .page-intro h1 { font-size: 27px; }
  .intro-copy { font-size: 14px; }
  .team-card, .unassigned-card { padding: 16px; }
  .team-manager .user-identity strong { font-size: 14px; }
  .team-members .user-identity strong { font-size: 13px; }
  .team-members .user-identity small { font-size: 11px; }
  .action-buttons { gap: 6px; }
  .manage-button, .user-action-button { padding-inline: 7px; font-size: 11px; }
}

.statistics-content { padding: 0; }
.drawer-team-controls { margin-top: 18px; padding-top: 16px; border-top: 1px solid var(--app-border); }
.drawer-team-add > label { display: block; margin-bottom: 7px; color: var(--app-muted); font-size: 12px; font-weight: 650; }
.drawer-team-add > div { display: flex; gap: 8px; }
.drawer-team-add select { min-width: 0; flex: 1; padding: 0 10px; border: 1px solid var(--app-border); border-radius: 7px; color: var(--app-text); background: var(--app-surface); font: inherit; font-size: 12px; }
.drawer-team-action { min-height: 38px; margin-top: 0; font-size: 12px; }
.drawer-team-add .drawer-team-action { flex: 0 0 auto; }
.drawer-team-controls > .drawer-team-action { width: 100%; }
.membership-error { margin: 0 0 10px; color: #a33636; font-size: 12px; }
.message-compose { display: grid; gap: 8px; margin-top: 18px; padding-top: 17px; border-top: 1px solid var(--app-border); }
.message-compose h3 { margin: 0; color: var(--app-text); font-size: 14px; }
.message-compose p { margin: 0; color: var(--app-muted); font-size: 11px; line-height: 1.5; }
.message-compose label { margin-top: 3px; color: #414c5d; font-size: 11px; font-weight: 650; }
.message-compose label span { color: var(--app-muted); font-weight: 400; }
.message-compose input, .message-compose textarea { width: 100%; min-width: 0; padding: 9px 10px; border: 1px solid var(--app-border); border-radius: 7px; color: var(--app-text); background: #fff; font: inherit; font-size: 12px; }
.message-compose textarea { min-height: 96px; resize: vertical; }
.message-compose input:focus, .message-compose textarea:focus { border-color: var(--app-accent); outline: 3px solid rgb(22 132 248 / 12%); }
.message-compose .message-error, .message-compose .message-success { font-size: 11px; }
.message-compose .message-error { color: #a33636; }.message-compose .message-success { color: #16734f; }
.message-submit { justify-self: start; margin-top: 3px; }
.statistics-summary { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.statistics-summary--team { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.statistics-metric { display: grid; min-width: 0; gap: 8px; padding: 17px; border: 1px solid var(--app-border); border-radius: 10px; background: var(--app-background); }
.statistics-metric span { color: var(--app-muted); font-size: 13px; }
.statistics-metric strong { overflow-wrap: anywhere; color: var(--app-text); font-size: 22px; }
.statistics-chart { margin-top: 14px; padding: 18px; border: 1px solid var(--app-border); border-radius: 10px; background: var(--app-surface); }
.statistics-chart > div { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.statistics-chart h3 { margin: 0; color: var(--app-text); font-size: 15px; }
.statistics-chart > div > strong { color: var(--app-text); font-size: 16px; }

@media (max-width: 760px) {
  .statistics-summary { grid-template-columns: 1fr; gap: 8px; }
  .statistics-metric { grid-template-columns: 1fr auto; align-items: center; padding: 13px; }
  .statistics-chart { padding: 14px; }
}
</style>
