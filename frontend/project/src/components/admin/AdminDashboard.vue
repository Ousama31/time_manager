<template>
  <AppShell class="admin-dashboard" :navigation="navigation" :active-tab="activeSection" @navigate="navigateSection" @logout="disconnect">
      <div id="users" class="admin-content dashboard-content">
        <div v-if="activeSection !== 'profile'" class="page-intro dashboard-heading">
          <div>
            <p class="admin-eyebrow dashboard-eyebrow">PEOPLE &amp; ACCESS</p>
            <h1 class="dashboard-title">{{ activeSection === 'teams' ? 'Teams' : 'User Management' }}</h1>
            <p v-if="activeSection === 'teams'" class="intro-copy dashboard-description">Managers and their assigned employees.</p>
            <p v-else class="intro-copy dashboard-description">Manage your team, roles, and access in one place.</p>
          </div>
        </div>

        <div v-if="activeSection !== 'profile' && usersError" class="inline-notice error-notice" role="alert">{{ usersError }}</div>

        <AdminTeamsSection v-if="activeSection === 'teams'" :loading-users="loadingUsers" :manager-teams="managerTeams" :unassigned-employees="unassignedEmployees" @open-statistics="openStatistics" />

        <AdminUsersSection v-if="activeSection === 'users'" :filtered-users="filteredUsers" :loading-users="loadingUsers" v-model:search-query="searchQuery" v-model:status-filter="statusFilter" v-model:role-filter="roleFilter" :user-id="userId" @open-statistics="openStatistics" @open-role-editor="openRoleEditor" @toggle-user-status="toggleUserStatus" @delete-user="deleteUser" />

        <AdminProfileSection v-if="activeSection === 'profile'" :initials="initials" :display-name="displayName" :profile="profile" @logout="disconnect" />
      </div>
    <AdminRoleEditorDrawer v-if="editingUser" :editing-user="editingUser" :role-options="roleOptions" v-model:selected-role="selectedRole" v-model:confirm-role-change="confirmRoleChange" :saving-role="savingRole" @close="closeRoleEditor" @save="saveRoleChange" />
    <AdminStatisticsDrawer
      v-if="statsUser"
      :stats-user="statsUser"
      :is-manager-stats="isManagerStats"
      :stats-team-members="statsTeamMembers"
      :stats-active-team-count="statsActiveTeamCount"
      :stats-today-minutes="statsTodayMinutes"
      :stats-week-minutes="statsWeekMinutes"
      :stats-week-bars="statsWeekBars"
      :stats-clock="statsClock"
      :stats-loading="statsLoading"
      :stats-error="statsError"
      :team-action-error="teamActionError"
      :team-action-busy="teamActionBusy"
      v-model:selected-stats-manager-id="selectedStatsManagerId"
      :manager-teams="managerTeams"
      v-model:message-subject="messageSubject"
      v-model:message-body="messageBody"
      :message-error="messageError"
      :message-success="messageSuccess"
      @close="closeStatistics"
      @update-team-assignment="updateTeamAssignment"
      @add-user-to-team="addStatsUserToTeam"
      @send-message="sendStatsMessage"
    />
  </AppShell>
</template>

<script>
/** @component Administrator workspace for team assignment, user access management, profiles, and time statistics. API permissions are enforced by the backend. */
import api from '../../api'
import { getDisplayName, getInitials } from '../../utils/identity'
import AppShell from '../dashboard/AppShell.vue'
import AdminTeamsSection from './sections/AdminTeamsSection.vue'
import AdminUsersSection from './sections/AdminUsersSection.vue'
import AdminProfileSection from './sections/AdminProfileSection.vue'
import AdminRoleEditorDrawer from './drawers/AdminRoleEditorDrawer.vue'
import AdminStatisticsDrawer from './drawers/AdminStatisticsDrawer.vue'
import { createEmailDraftUrl } from '../../utils/emailDraft'
import { startOfLocalDay, startOfLocalWeek, sumWorkMinutes as sumMinutes, formatMinutes as formatWorkMinutes } from '../../utils/time'
import { useAdminDashboard } from '../../composables/useAdminDashboard'

const adminDashboard = useAdminDashboard()

export default {
  name: 'AdminDashboard',
  components: { AppShell, AdminTeamsSection, AdminUsersSection, AdminProfileSection, AdminRoleEditorDrawer, AdminStatisticsDrawer },
  /** Create the reactive state for user lists, filters, selected drawers, and statistics requests. */
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
    /** Define the administrator sections shown in the shared dashboard navigation. */
    navigation() {
      return [
        { key: 'teams', label: 'Teams', icon: 'teams' },
        { key: 'users', label: 'User management', icon: 'users' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    /** Build the display name shown for the signed-in administrator. */
    displayName() {
      return getDisplayName(this.profile, 'Admin User')
    },
    /** Build initials for the administrator profile avatar. */
    initials() {
      return getInitials(this.displayName, 'AD')
    },
    /** Filter users by search, status, and role, then sort by role and name. */
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
    /** Group employee accounts under their assigned managers. */
    managerTeams() {
      return this.users
        .filter((user) => user.role === 'Manager')
        .sort((first, second) => first.name.localeCompare(second.name))
        .map((manager) => ({
          manager,
          employees: this.users.filter((user) => user.role === 'Employee' && String(user.managerId) === String(manager.id))
        }))
    },
    /** Select employee accounts that do not currently have a manager. */
    unassignedEmployees() {
      return this.users.filter((user) => user.role === 'Employee' && !user.managerId)
    },
    /** Indicate whether the open statistics panel belongs to a manager. */
    isManagerStats() {
      return this.statsUser?.role === 'Manager'
    },
    /** Count active employees in the selected manager’s team. */
    statsActiveTeamCount() {
      return this.statsTeamMembers.filter((member) => member.status === 'Active').length
    },
    /** Calculate today’s work minutes for the selected user or manager team. */
    statsTodayMinutes() {
      if (this.isManagerStats) {
        const dayStart = startOfLocalDay(this.now)
        return this.statsTeamMembers.reduce((total, member) => total + sumMinutes(member.records, dayStart, this.now, member.clock, this.now), 0)
      }
      return sumMinutes(this.statsRecords, startOfLocalDay(this.now), this.now, this.statsClock, this.now)
    },
    /** Calculate this week’s work minutes for the selected user or manager team. */
    statsWeekMinutes() {
      if (this.isManagerStats) {
        const weekStart = startOfLocalWeek(this.now)
        return this.statsTeamMembers.reduce((total, member) => total + sumMinutes(member.records, weekStart, this.now, member.clock, this.now), 0)
      }
      return sumMinutes(this.statsRecords, startOfLocalWeek(this.now), this.now, this.statsClock, this.now)
    },
    /** Build daily work-minute values and chart heights for the open statistics panel. */
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
  /** Load the administrator profile and workspace users when the view is mounted. */
  mounted() {
    this.loadProfile()
    this.loadUsers()
  },
  methods: {
    /** Switch the active administrator section. */
    navigateSection(section) {
      this.activeSection = section
    },
    /** Fetch the signed-in administrator profile from the API. */
    async loadProfile() {
      if (!this.userId) return
      try {
        this.profile = await adminDashboard.loadProfile(this.userId)
      } catch (error) {
        console.error('Could not load profile:', error)
      }
    },
    /** Fetch workspace users and normalize role, status, display, and avatar fields for the UI. */
    async loadUsers() {
      this.loadingUsers = true
      this.usersError = ''
      try {
        this.users = await adminDashboard.loadUsers()
      } catch (error) {
        this.usersError = error.response?.status === 403
          ? 'Admin access is required to view workspace users.'
          : 'Could not load users. Please try again.'
      } finally {
        this.loadingUsers = false
      }
    },
    /** Fetch clock and interval data for a selected user or all employees on a selected manager’s team. */
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
          const members = await adminDashboard.loadManagerTeamTimeData(employees)
          if (requestId !== this.statsRequestId) return
          this.statsTeamMembers = members
          this.statsRecords = []
          this.statsClock = null
        } else {
          const timeData = await adminDashboard.loadUserTimeData(userId)
          if (requestId !== this.statsRequestId) return
          this.statsRecords = timeData.records
          this.statsClock = timeData.clock
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
    /** Select a user, reset drawer state, and load their statistics. */
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
    /** Close the statistics drawer and invalidate any in-flight statistics request. */
    closeStatistics() {
      this.statsUser = null
      this.selectedStatsManagerId = ''
      this.teamActionError = ''
      this.messageError = ''
      this.messageSuccess = ''
      this.statsRequestId += 1
      this.statsLoading = false
    },
    /** Open a prefilled email draft addressed to the selected user. */
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
    /** Format a minute count as hours and zero-padded minutes. */
    formatMinutes(minutes) {
      return formatWorkMinutes(minutes)
    },
    /** Map a display role to the CSS class used for its badge. */
    roleClass(role) {
      return { Admin: 'role-admin', Manager: 'role-manager', Employee: 'role-member' }[role] || 'role-member'
    },
    /** Check whether a user row represents the signed-in administrator. */
    isCurrentUser(user) {
      return String(user.id) === String(this.userId)
    },
    /** Open the role editor with the selected user’s current role. */
    openRoleEditor(user) {
      this.editingUser = user
      this.selectedRole = user.role
      this.confirmRoleChange = false
    },
    /** Close the role editor and clear its confirmation state. */
    closeRoleEditor() {
      this.editingUser = null
      this.confirmRoleChange = false
    },
    /** Save the confirmed role change through the API and update the selected user. */
    async saveRoleChange() {
      if (!this.editingUser || !this.confirmRoleChange || this.savingRole) return
      this.savingRole = true
      this.usersError = ''
      try {
        const role = { Admin: 'admin', Manager: 'manager', Employee: 'employee' }[this.selectedRole]
        await adminDashboard.updateRole(this.editingUser.id, role)
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
    /** Assign the selected unassigned employee to the manager chosen in the statistics drawer. */
    async addStatsUserToTeam() {
      if (!this.statsUser || !this.selectedStatsManagerId) return
      await this.updateTeamAssignment(this.statsUser, this.selectedStatsManagerId)
    },
    /** Save an employee’s manager assignment and synchronize drawer state. */
    async updateTeamAssignment(employee, managerId) {
      if (this.teamActionBusy) return
      this.teamActionBusy = true
      this.teamActionError = ''
      try {
        await adminDashboard.updateManagerAssignment(employee.id, managerId)
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
    /** Activate or suspend a user account, preventing changes to the current administrator. */
    async toggleUserStatus(user) {
      if (user.actionBusy || this.isCurrentUser(user)) return
      const nextStatus = user.status === 'Active' ? 'Inactive' : 'Active'
      user.actionBusy = true
      this.usersError = ''
      try {
        await adminDashboard.updateStatus(user.id, nextStatus)
        user.status = nextStatus
      } catch (error) {
        this.usersError = error.response?.data?.error || 'Could not update this account status. Please try again.'
      } finally {
        user.actionBusy = false
      }
    },
    /** Confirm and permanently delete a user account and its related records through the API. */
    async deleteUser(user) {
      if (user.actionBusy || this.isCurrentUser(user)) return
      const confirmed = window.confirm(`Delete ${user.name} (${user.email}) and their clock and work-time records permanently? This cannot be undone.`)
      if (!confirmed) return

      user.actionBusy = true
      this.usersError = ''
      try {
        await adminDashboard.deleteUser(user.id)
        this.users = this.users.filter((currentUser) => currentUser.id !== user.id)
      } catch (error) {
        this.usersError = error.response?.data?.error || 'Could not delete this user. Please try again.'
      } finally {
        user.actionBusy = false
      }
    },
    /** Sign out through the API, clear the session, and navigate to sign-in. */
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

<style>
.admin-dashboard .admin-content {
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
.admin-dashboard .stats-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 13px; margin: 0 0 18px; }
.admin-dashboard .stat-card { min-width: 0; padding: 16px 18px; border: 1px solid var(--app-border); border-radius: 12px; background: var(--app-surface); box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.admin-dashboard .stat-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.admin-dashboard .stat-icon { display: grid; width: 32px; height: 32px; place-items: center; border-radius: 9px; }
.admin-dashboard .stat-icon svg { width: 18px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.admin-dashboard .stat-icon-violet { color: #6657d9; background: #efedff; }
.admin-dashboard .stat-icon-green { color: #17976f; background: #e8f8f1; }
.admin-dashboard .stat-icon-blue { color: #3b78d4; background: #e9f2ff; }
.admin-dashboard .stat-icon-amber { color: #b98227; background: #fff5df; }
.admin-dashboard .stat-card > strong { display: block; color: var(--app-text); font-size: 25px; font-weight: 730; letter-spacing: -.5px; }
.admin-dashboard .stat-label { display: block; margin-top: 3px; color: var(--app-muted); font-size: 12px; }
.admin-dashboard .admin-content { width: 100%; margin: 0; padding: 0; }
.admin-dashboard .page-intro { display: flex; align-items: flex-end; justify-content: space-between; gap: 20px; margin-bottom: 25px; }
.admin-dashboard .admin-eyebrow { margin: 0 0 8px; color: #818da0; font-size: 9px; font-weight: 750; letter-spacing: 1.2px; }
.admin-dashboard .page-intro h1 { margin: 0; color: #192432; font-size: clamp(24px, 2.2vw, 30px); font-weight: 740; letter-spacing: -.9px; }
.admin-dashboard .intro-copy { margin: 7px 0 0; color: #7b8797; font-size: 12px; }
.admin-dashboard .inline-notice { margin: -10px 0 18px; padding: 10px 13px; border: 1px solid #dfe4fb; border-radius: 8px; color: #4959bd; background: #f3f5ff; font-size: 11px; }
.admin-dashboard .stats-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 13px; margin-bottom: 19px; }
.admin-dashboard .stat-card { min-width: 0; padding: 14px 16px 15px; border: 1px solid #e8ecf2; border-radius: 10px; background: #fff; box-shadow: 0 2px 7px rgb(25 38 60 / 2%); }
.admin-dashboard .stat-top { display: flex; align-items: center; justify-content: space-between; gap: 7px; margin-bottom: 12px; }
.admin-dashboard .stat-icon { display: grid; width: 29px; height: 29px; place-items: center; border-radius: 8px; }
.admin-dashboard .stat-icon svg { width: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.admin-dashboard .stat-icon-violet { color: #6657d9; background: #efedff; }
.admin-dashboard .stat-icon-green { color: #17976f; background: #e8f8f1; }
.admin-dashboard .stat-icon-blue { color: #3b78d4; background: #e9f2ff; }
.admin-dashboard .stat-icon-amber { color: #b98227; background: #fff5df; }
.admin-dashboard .stat-change { color: #188460; font-size: 9px; font-weight: 650; }
.admin-dashboard .stat-change i { font-size: 11px; font-style: normal; }
.admin-dashboard .stat-period { overflow: hidden; color: #969faf; font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.admin-dashboard .stat-card > strong { display: block; color: #202b3a; font-size: 23px; font-weight: 730; letter-spacing: -.5px; }
.admin-dashboard .stat-label { display: block; margin-top: 3px; color: #7f8a9a; font-size: 10px; }
.admin-dashboard .teams-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin: 3px 0 14px; }
.admin-dashboard .teams-heading h2 { margin: 0; color: #202b3a; font-size: 18px; font-weight: 720; letter-spacing: -.35px; }
.admin-dashboard .teams-heading p:last-child { margin: 5px 0 0; color: #7f8a9a; font-size: 11px; }
.admin-dashboard .teams-total { padding: 7px 10px; border: 1px solid #e8ecf2; border-radius: 8px; color: #697587; background: #fff; font-size: 10px; }
.admin-dashboard .user-avatar, .admin-dashboard .drawer-avatar { display: grid; width: 32px; height: 32px; flex: 0 0 32px; place-items: center; border: 1px solid rgb(35 49 70 / 5%); border-radius: 50%; font-size: 9px; font-weight: 700; }
.admin-dashboard .tone-lilac { color: #5d4db1; background: #efebff; }
.admin-dashboard .tone-peach { color: #a95236; background: #fff0e8; }
.admin-dashboard .tone-mint { color: #247458; background: #e7f7ef; }
.admin-dashboard .tone-sky { color: #3869a5; background: #e8f2ff; }
.admin-dashboard .tone-rose { color: #a94a70; background: #ffedf3; }
.admin-dashboard .tone-gold { color: #8a6827; background: #fff5d9; }
.admin-dashboard .tone-blue { color: #4260a9; background: #e8eeff; }
.admin-dashboard .role-admin { border-color: #e7e1ff; color: #6551c8; background: #f3f0ff; }
.admin-dashboard .role-member { border-color: #e5e8ed; color: #657082; background: #f5f6f8; }
.admin-dashboard .status-active { color: #18835f; }
.admin-dashboard .status-inactive { color: #9ba3af; }
.admin-dashboard .suspend-button { border-color: #f0d58a; color: #87600b; background: #fff7df; }
.admin-dashboard .suspend-button:hover:not(:disabled) { border-color: #e4c35b; background: #ffefbd; }
.admin-dashboard .activate-button { border-color: #bfe4d4; color: #16734f; background: #eaf8f1; }
.admin-dashboard .activate-button:hover:not(:disabled) { border-color: #91d1b5; background: #d9f2e6; }
.admin-dashboard .drawer-avatar { width: 38px; height: 38px; flex-basis: 38px; font-size: 10px; }
.admin-dashboard .role-option-selected { border-color: #777fe0; background: #f7f7ff; box-shadow: 0 0 0 2px rgb(70 87 216 / 8%); }
.admin-dashboard .option-member { color: #677486; background: #f0f2f5; }
.admin-dashboard .option-manager { color: #3475bf; background: #eaf3ff; }
.admin-dashboard .option-admin { color: #6653c7; background: #efecff; }
.admin-dashboard .privilege-note-admin { border-color: #e5defb; color: #6550ac; background: #f7f4ff; }
.admin-dashboard .privilege-note-manager { border-color: #dce9f7; color: #405b84; background: #f2f7ff; }
.admin-dashboard .drawer-fade-enter-active, .admin-dashboard .drawer-fade-leave-active { transition: opacity .2s ease; }
.admin-dashboard .drawer-fade-enter-from, .admin-dashboard .drawer-fade-leave-to { opacity: 0; }
.admin-dashboard .admin-content { padding: 0; }
.admin-dashboard .admin-eyebrow { font-size: 10px; }
.admin-dashboard .page-intro h1 { color: var(--app-text); font-size: clamp(28px, 3vw, 34px); letter-spacing: -.8px; }
.admin-dashboard .intro-copy { color: var(--app-muted); font-size: 14px; }
.admin-dashboard .stat-card { border-color: var(--app-border); border-radius: 12px; padding: 17px 18px; }
.admin-dashboard .stat-card > strong { color: var(--app-text); font-size: 27px; }
.admin-dashboard .stat-label { color: var(--app-muted); font-size: 12px; }
.admin-dashboard .stat-period, .admin-dashboard .stat-change { font-size: 10px; }
.admin-dashboard .teams-heading h2 { font-size: 20px; }
.admin-dashboard .teams-total { font-size: 11px; }
.admin-dashboard .user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 10px; }
  .admin-dashboard .stats-grid { gap: 10px; }
  .admin-dashboard .stat-card { padding: 13px 14px; }
  .admin-dashboard .stat-card > strong { font-size: 22px; }
  .admin-dashboard .stat-label { font-size: 11px; }
  .admin-dashboard .teams-heading { align-items: flex-start; flex-direction: column; }
  .admin-dashboard .stats-grid { gap: 9px; }
  .admin-dashboard .stat-card { padding: 12px; }
  .admin-dashboard .stat-icon { width: 29px; height: 29px; }
  .admin-dashboard .page-intro { align-items: flex-start; }
  .admin-dashboard .page-intro h1 { font-size: 25px; }
  .admin-dashboard .intro-copy { max-width: 300px; font-size: 13px; line-height: 1.5; }
  .admin-dashboard .teams-total { white-space: normal; }
.admin-dashboard .admin-content { color: var(--app-text); }
.admin-dashboard .page-intro h1 { letter-spacing: -.7px; }
.admin-dashboard .page-intro { margin-bottom: 22px; }
.admin-dashboard .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; margin-bottom: 20px; }
.admin-dashboard .stat-card { min-height: 124px; padding: 17px 18px; border-radius: 17px; box-shadow: var(--app-shadow-panel); }
.admin-dashboard .stat-top { margin-bottom: 12px; }
.admin-dashboard .stat-icon { width: 36px; height: 36px; border-radius: 11px; }
.admin-dashboard .stat-icon svg { width: 19px; }
.admin-dashboard .stat-card > strong { font-size: 25px; }
.admin-dashboard .stat-label { font-size: 12px; }
.admin-dashboard .teams-heading h2 { font-size: 20px; }
.admin-dashboard .teams-heading p:last-child { font-size: 12px; }
.admin-dashboard .teams-total { border-radius: 10px; font-size: 11px; }
.admin-dashboard .user-avatar { width: 38px; height: 38px; flex-basis: 38px; font-size: 11px; }
.admin-dashboard .user-avatar { width: 36px; height: 36px; flex-basis: 36px; font-size: 10px; }
  .admin-dashboard .stats-grid { gap: 10px; }
  .admin-dashboard .stat-card { min-height: 112px; padding: 14px; border-radius: 15px; }
  .admin-dashboard .stat-icon { width: 32px; height: 32px; }
  .admin-dashboard .stat-card > strong { font-size: 23px; }
  .admin-dashboard .stat-label { font-size: 11px; }
  .admin-dashboard .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
  .admin-dashboard .stat-card { min-height: 104px; padding: 11px; }
  .admin-dashboard .stat-card > strong { font-size: 21px; }
  .admin-dashboard .stat-label { font-size: 10px; }
.admin-dashboard .page-intro { margin-bottom: 28px; }
.admin-dashboard .admin-eyebrow { font-size: 11px; letter-spacing: 1.3px; }
.admin-dashboard .page-intro h1 { font-size: clamp(32px, 3.2vw, 40px); }
.admin-dashboard .intro-copy { font-size: 15px; line-height: 1.55; }
.admin-dashboard .user-avatar { width: 42px; height: 42px; flex-basis: 42px; font-size: 12px; }
  .admin-dashboard .page-intro h1 { font-size: 27px; }
  .admin-dashboard .intro-copy { font-size: 14px; }
</style>
