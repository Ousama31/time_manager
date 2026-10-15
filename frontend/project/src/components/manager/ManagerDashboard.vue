<template>
  <AppShell class="manager-dashboard" :navigation="navigation" :active-tab="activeTab" @navigate="navigateTab" @logout="disconnect">
  <div class="manager-main">
      <div class="manager-content">
        <ManagerOverviewSection v-if="activeTab === 'statistics'" :load-error="loadError" :clocked-in-count="clockedInCount" :active-team-count="activeTeamCount" :clocked-in-percent="clockedInPercent" :on-break-count="onBreakCount" :off-clock-count="offClockCount" :team="team" :today-team-minutes="todayTeamMinutes" :week-team-minutes="weekTeamMinutes" :week-bars="weekBars" @retry="loadDashboard" />
        <ManagerTeamSection v-else-if="activeTab === 'team'" :load-error="loadError" v-model:search-query="searchQuery" :filtered-team="filteredTeam" :filtered-unassigned="filteredUnassigned" :team="team" :unassigned-employees="unassignedEmployees" :loading="loading" @retry="loadDashboard" @open-statistics="openStatistics" />
        <ManagerProfileSection v-else :initials="initials" :display-name="displayName" :profile="profile" @logout="disconnect" />
      </div>
    </div>
    <ManagerMemberDetailsDrawer v-if="selectedMember" :selected-member="selectedMember" :selected-member-loading="selectedMemberLoading" :membership-error="membershipError" :team-action-busy="teamActionBusy" :today-minutes="selectedMember ? memberTodayMinutes(selectedMember) : 0" :week-minutes="selectedMember ? memberWeekMinutes(selectedMember) : 0" :selected-member-week-bars="selectedMemberWeekBars" v-model:message-subject="messageSubject" v-model:message-body="messageBody" :message-error="messageError" :message-success="messageSuccess" :now="now" @close="closeStatistics" @toggle-membership="toggleSelectedMembership" @send-message="sendMemberMessage" />
  </AppShell>
</template>

<script>
/** @component Manager workspace for team status, work-hour summaries, member details, team assignments, and profile. API permissions are enforced by the backend. */
import api from '../../api'
import { getDisplayName, getInitials } from '../../utils/identity'
import ManagerOverviewSection from './sections/ManagerOverviewSection.vue'
import ManagerTeamSection from './sections/ManagerTeamSection.vue'
import ManagerProfileSection from './sections/ManagerProfileSection.vue'
import ManagerMemberDetailsDrawer from './drawers/ManagerMemberDetailsDrawer.vue'
import AppShell from '../dashboard/AppShell.vue'
import { createEmailDraftUrl } from '../../utils/emailDraft'
import { startOfLocalDay, startOfLocalWeek, sumWorkMinutes as sumMinutes, formatMinutes as formatWorkMinutes, formatTime as formatLocalizedTime } from '../../utils/time'
import { useManagerDashboard } from '../../composables/useManagerDashboard'

const managerDashboard = useManagerDashboard()

export default {
  name: 'ManagerDashboard',
  components: { AppShell, ManagerOverviewSection, ManagerTeamSection, ManagerProfileSection, ManagerMemberDetailsDrawer },
  /** Create reactive team, profile, filter, drawer, and request state for the manager view. */
  data() {
    return {
      userId: sessionStorage.getItem('userId'),
      activeTab: 'statistics',
      profile: {},
      team: [],
      unassignedEmployees: [],
      teamActionBusy: false,
      loading: true,
      refreshingClockStatuses: false,
      loadError: '',
      searchQuery: '',
      selectedMember: null,
      selectedMemberLoading: false,
      membershipError: '',
      messageSubject: '',
      messageBody: '',
      messageError: '',
      messageSuccess: '',
      statsRequestId: 0,
      now: new Date()
    }
  },
  computed: {
    /** Define the manager sections shown in the shared dashboard navigation. */
    navigation() {
      return [
        { key: 'statistics', label: 'Statistics', icon: 'chart' },
        { key: 'team', label: 'My team', icon: 'teams' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    /** Build the display name shown for the signed-in manager. */
    displayName() {
      return getDisplayName(this.profile, 'Manager')
    },
    /** Build initials for the manager profile avatar. */
    initials() {
      return getInitials(this.displayName)
    },
    /** Filter assigned team members by name or email. */
    filteredTeam() {
      const query = this.searchQuery.trim().toLowerCase()
      return this.team.filter((member) => !query || `${member.name} ${member.email}`.toLowerCase().includes(query))
    },
    /** Filter employees available to join this manager’s team. */
    filteredUnassigned() {
      const query = this.searchQuery.trim().toLowerCase()
      return this.unassignedEmployees.filter((employee) => !query || `${employee.name} ${employee.email}`.toLowerCase().includes(query))
    },
    /** Count active employees assigned to this manager. */
    activeTeamCount() {
      return this.team.filter((member) => member.status === 'Active').length
    },
    /** Count active employees currently working. */
    clockedInCount() {
      return this.team.filter((member) => member.status === 'Active' && member.clockedIn).length
    },
    /** Count active employees who are neither working nor on break. */
    offClockCount() {
      return Math.max(this.activeTeamCount - this.clockedInCount - this.onBreakCount, 0)
    },
    /** Count active employees currently on break. */
    onBreakCount() {
      return this.team.filter((member) => member.status === 'Active' && member.clockState === 'break').length
    },
    /** Calculate the share of active team members currently working. */
    clockedInPercent() {
      return this.activeTeamCount ? Math.round(this.clockedInCount / this.activeTeamCount * 100) : 0
    },
    /** Sum the team’s work minutes for today. */
    todayTeamMinutes() {
      return this.team.reduce((total, member) => total + this.memberTodayMinutes(member), 0)
    },
    /** Sum the team’s work minutes for the current week. */
    weekTeamMinutes() {
      return this.team.reduce((total, member) => total + this.memberWeekMinutes(member), 0)
    },
    /** Build daily team work-minute values and chart heights for this week. */
    weekBars() {
      const monday = startOfLocalWeek(this.now)
      const values = Array.from({ length: 7 }, (_, index) => {
        const dayStart = new Date(monday)
        dayStart.setDate(monday.getDate() + index)
        const dayEnd = new Date(dayStart)
        dayEnd.setDate(dayStart.getDate() + 1)
        const end = dayEnd > this.now ? this.now : dayEnd
        const minutes = this.team.reduce((total, member) => total + sumMinutes(member.records, dayStart, end, member.clock, this.now), 0)
        return { key: index, label: new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(dayStart), minutes }
      })
      const max = Math.max(...values.map((day) => day.minutes), 1)
      return values.map((day) => ({ ...day, height: day.minutes ? Math.max(8, Math.round(day.minutes / max * 100)) : 0 }))
    },
    /** Build daily work-minute values and chart heights for the selected member. */
    selectedMemberWeekBars() {
      if (!this.selectedMember) return []
      const monday = startOfLocalWeek(this.now)
      const days = Array.from({ length: 7 }, (_, index) => {
        const dayStart = new Date(monday)
        dayStart.setDate(monday.getDate() + index)
        const dayEnd = new Date(dayStart)
        dayEnd.setDate(dayStart.getDate() + 1)
        const end = dayEnd > this.now ? this.now : dayEnd
        const minutes = sumMinutes(this.selectedMember.records, dayStart, end, this.selectedMember.clock, this.now)
        return { key: index, label: new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(dayStart), minutes }
      })
      const max = Math.max(...days.map((day) => day.minutes), 1)
      return days.map((day) => ({ ...day, height: day.minutes ? Math.max(8, Math.round(day.minutes / max * 100)) : 0 }))
    }
  },
  /** Load manager data and start refreshing clock statuses while the view is active. */
  mounted() {
    this.loadDashboard()
    this.handleVisibilityChange = () => {
      if (!document.hidden) {
        this.now = new Date()
        this.refreshClockStatuses()
      }
    }
    document.addEventListener('visibilitychange', this.handleVisibilityChange)
    window.addEventListener('focus', this.handleVisibilityChange)
    this.refreshTimer = window.setInterval(() => {
      this.now = new Date()
      if (!document.hidden) this.refreshClockStatuses()
    }, 6000)
  },
  /** Clear the refresh timer and remove visibility/focus listeners when leaving the view. */
  beforeUnmount() {
    window.clearInterval(this.refreshTimer)
    document.removeEventListener('visibilitychange', this.handleVisibilityChange)
    window.removeEventListener('focus', this.handleVisibilityChange)
  },
  methods: {
    /** Switch manager sections and clear stale member-detail state. */
    navigateTab(tab) {
      this.activeTab = tab
      this.selectedMember = null
          this.selectedMemberLoading = false
          this.membershipError = ''
          this.statsRequestId += 1
    },
    /** Format a minute count as hours and zero-padded minutes. */
    formatMinutes(minutes) {
      return formatWorkMinutes(minutes)
    },
    /** Format a timestamp as a localized hour and minute. */
    formatTime(value) {
      return formatLocalizedTime(value, { hour: 'numeric', minute: '2-digit' })
    },
    /** Calculate today’s recorded and active work minutes for one member. */
    memberTodayMinutes(member) {
      return sumMinutes(member.records || [], startOfLocalDay(this.now), this.now, member.clock, this.now)
    },
    /** Calculate this week’s recorded and active work minutes for one member. */
    memberWeekMinutes(member) {
      return sumMinutes(member.records || [], startOfLocalWeek(this.now), this.now, member.clock, this.now)
    },
    /** Refresh each team member’s latest clock state without failing the whole refresh if one request fails. */
    async refreshClockStatuses() {
      if (this.refreshingClockStatuses || this.team.length === 0) return
      this.refreshingClockStatuses = true
      try {
        const updates = await managerDashboard.refreshClockStatuses(this.team)
        const updatesById = new Map(updates.map((update) => [String(update.id), update]))
        this.team.forEach((member) => Object.assign(member, updatesById.get(String(member.id)) || {}))
        this.now = new Date()
      } finally {
        this.refreshingClockStatuses = false
      }
    },
    /** Fetch profile, assigned/unassigned users, clocks, and time intervals for the manager dashboard. */
    async loadDashboard() {
      this.loading = true
      this.loadError = ''
      try {
        const dashboard = await managerDashboard.loadDashboard(this.userId)
        this.profile = dashboard.profile
        this.team = dashboard.team
        this.unassignedEmployees = dashboard.unassignedEmployees
      } catch (error) {
        console.error('Could not load manager dashboard:', error)
        this.loadError = error.response?.status === 403
          ? 'Manager access is required to view your team.'
          : 'Could not load your team. Please try again.'
      } finally {
        this.loading = false
      }
    },
    /** Open a member details drawer and fetch their clock and intervals if they are not already loaded. */
    async openStatistics(member) {
      const requestId = ++this.statsRequestId
      this.selectedMember = member
      this.selectedMemberLoading = false
      this.membershipError = ''
      this.messageSubject = ''
      this.messageBody = ''
      this.messageError = ''
      this.messageSuccess = ''
      if (Array.isArray(member.records)) return

      this.selectedMemberLoading = true
      const timeData = await managerDashboard.loadMemberTimeData(member.id)
      if (requestId !== this.statsRequestId) return

      this.selectedMember = {
        ...member,
        ...timeData
      }
      this.selectedMemberLoading = false
    },
    /** Close the member drawer, clear messages, and invalidate any in-flight statistics request. */
    closeStatistics() {
      this.selectedMember = null
      this.selectedMemberLoading = false
      this.membershipError = ''
      this.messageError = ''
      this.messageSuccess = ''
      this.statsRequestId += 1
    },
    /** Open a prefilled email draft addressed to the selected team member. */
    sendMemberMessage() {
      if (!this.selectedMember || !this.messageBody.trim()) return
      this.messageError = ''
      this.messageSuccess = ''
      try {
        window.location.href = createEmailDraftUrl(this.selectedMember.email, this.messageSubject, this.messageBody)
        this.messageSuccess = 'Your email draft should open in your email app. Send it there to deliver your message.'
      } catch (error) {
        this.messageError = 'Could not open an email draft. Please check the recipient address and your email app.'
      }
    },
    /** Add the selected employee to this manager’s team or remove them, then update the displayed lists. */
    async toggleSelectedMembership() {
      if (!this.selectedMember || this.teamActionBusy) return
      const employee = this.selectedMember
      const managerId = employee.managerId ? null : this.userId
      this.teamActionBusy = true
      this.membershipError = ''
      try {
        await managerDashboard.updateMembership(employee.id, managerId)
        const updatedEmployee = { ...employee, managerId, manager_id: managerId }
        this.team = this.team.filter((member) => String(member.id) !== String(employee.id))
        this.unassignedEmployees = this.unassignedEmployees.filter((member) => String(member.id) !== String(employee.id))
        const drawerIsOpenForEmployee = String(this.selectedMember?.id) === String(employee.id)
        if (managerId) {
          if (drawerIsOpenForEmployee) {
            updatedEmployee.records = undefined
            await this.openStatistics(updatedEmployee)
            this.team = [...this.team, this.selectedMember]
          } else {
            this.team = [...this.team, updatedEmployee]
          }
        } else {
          this.unassignedEmployees = [...this.unassignedEmployees, updatedEmployee]
          if (drawerIsOpenForEmployee) this.selectedMember = updatedEmployee
        }
      } catch (error) {
        this.membershipError = error.response?.data?.error || 'Could not update this team assignment. Please try again.'
      } finally {
        this.teamActionBusy = false
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
.manager-dashboard .manager-main { --manager-ink: var(--app-text); --manager-muted: var(--app-muted); min-width: 0; }
.manager-dashboard .manager-content { width: 100%; margin: 0; padding: 0; color: var(--manager-ink); }
.manager-dashboard .profile-avatar { display: grid; width: 62px; height: 62px; flex: 0 0 62px; place-items: center; border-radius: 50%; color: #fff; background: var(--app-accent); font-size: 19px; font-weight: 700; }
.manager-dashboard .icon-red { color: #e9514e; background: #fff0ef; }
.manager-dashboard .team-action { min-height: 31px; padding: 0 10px; border: 1px solid #b9d8f8; border-radius: 6px; color: #146fc7; background: #edf5ff; font: inherit; font-size: 9px; font-weight: 680; cursor: pointer; }
.manager-dashboard .team-action:disabled { opacity: .55; cursor: not-allowed; }
.manager-dashboard .team-remove { min-height: 25px; color: #a54b4b; border-color: #f0dada; background: #fff; }
.manager-dashboard .drawer-team-action { width: 100%; min-height: 42px; margin-top: 16px; font-size: 13px; }
.manager-dashboard .membership-error { margin: 14px 0 0; color: #a33636; font-size: 12px; }
.manager-dashboard .message-compose { display: grid; gap: 8px; margin-top: 17px; padding-top: 16px; border-top: 1px solid var(--app-border); }
.manager-dashboard .message-compose h3 { margin: 0; color: var(--app-text); font-size: 14px; }
.manager-dashboard .message-compose p { margin: 0; color: var(--app-muted); font-size: 11px; line-height: 1.5; }
.manager-dashboard .message-compose label { margin-top: 3px; color: #414c5d; font-size: 11px; font-weight: 650; }
.manager-dashboard .message-compose label span { color: var(--app-muted); font-weight: 400; }
.manager-dashboard .message-compose input, .manager-dashboard .message-compose textarea { width: 100%; min-width: 0; padding: 9px 10px; border: 1px solid var(--app-border); border-radius: 7px; color: var(--app-text); background: #fff; font: inherit; font-size: 12px; }
.manager-dashboard .message-compose textarea { min-height: 96px; resize: vertical; }
.manager-dashboard .message-compose input:focus, .manager-dashboard .message-compose textarea:focus { border-color: var(--app-accent); outline: 3px solid rgb(22 132 248 / 12%); }
.manager-dashboard .message-compose .message-error, .manager-dashboard .message-compose .message-success { font-size: 11px; }
.manager-dashboard .message-compose .message-error { color: #a33636; }.manager-dashboard .message-compose .message-success { color: #16734f; }
.manager-dashboard .message-submit { justify-self: start; margin-top: 3px; }
.manager-dashboard .team-table-scroll { width: 100%; overflow-x: auto; }
.manager-dashboard .team-table { width: 100%; border-collapse: collapse; text-align: left; white-space: nowrap; }
.manager-dashboard .team-table th { height: 33px; padding: 0 13px; border-bottom: 1px solid #eceef2; color: #929baa; font-size: 8px; font-weight: 720; letter-spacing: .6px; }
.manager-dashboard .team-table th:first-child, .manager-dashboard .team-table td:first-child { padding-left: 16px; }
.manager-dashboard .team-table td { height: 51px; padding: 0 13px; border-bottom: 1px solid #f0f2f5; color: #536071; font-size: 9px; }
.manager-dashboard .team-table tbody tr:last-child td { border-bottom: 0; }
.manager-dashboard .employee-avatar { display: grid; width: 29px; height: 29px; flex: 0 0 29px; place-items: center; border-radius: 50%; font-size: 8px; font-weight: 700; }
.manager-dashboard .tone-lilac { color: #5d4db1; background: #efebff; }.manager-dashboard .tone-peach { color: #a95236; background: #fff0e8; }.manager-dashboard .tone-mint { color: #247458; background: #e7f7ef; }.manager-dashboard .tone-sky { color: #3869a5; background: #e8f2ff; }.manager-dashboard .tone-rose { color: #a94a70; background: #ffedf3; }.manager-dashboard .tone-gold { color: #8a6827; background: #fff5d9; }.manager-dashboard .tone-blue { color: #4260a9; background: #e8eeff; }
.manager-dashboard .view-button { min-height: 25px; padding: 0 9px; border: 1px solid #dbeaff; border-radius: 6px; color: #1677df; background: #edf5ff; font: inherit; font-size: 8px; font-weight: 680; cursor: pointer; }
.manager-dashboard .view-button:hover, .manager-dashboard .view-button:focus-visible { border-color: #b6d6fc; background: #e2efff; outline: none; }
.manager-dashboard .member-actions { text-align: right; padding-right: 16px !important; }
.manager-dashboard .detail-fade-enter-active, .manager-dashboard .detail-fade-leave-active { transition: opacity .16s ease; }
.manager-dashboard .detail-fade-enter-from, .manager-dashboard .detail-fade-leave-to { opacity: 0; }
.manager-dashboard .manager-content { color: var(--app-text); }
.manager-dashboard .team-table th { border-color: var(--app-border); font-size: 10px; }
.manager-dashboard .team-table td { border-color: var(--app-border); font-size: 12px; }
.manager-dashboard .employee-avatar { font-size: 10px; }
.manager-dashboard .view-button { border-color: #d7e9fb; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 10px; }
  .manager-dashboard .manager-content { padding-bottom: 5px; }
  .manager-dashboard .team-action { min-height: 42px; }
  .manager-dashboard .team-table-scroll { overflow: visible; padding: 10px; }
  .manager-dashboard .team-table { display: block; width: 100%; min-width: 0; white-space: normal; }
  .manager-dashboard .team-table thead { display: none; }
  .manager-dashboard .team-table tbody { display: grid; gap: 11px; }
  .manager-dashboard .team-table tbody tr { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 12px; padding: 14px; border: 1px solid var(--app-border); border-radius: 15px; background: var(--app-surface); box-shadow: 0 4px 13px rgb(27 41 61 / 4%); }
  .manager-dashboard .team-table td { display: block; height: auto; min-width: 0; padding: 0 !important; border: 0; font-size: 13px; }
  .manager-dashboard .team-table td:first-child, .manager-dashboard .team-table td:nth-child(2) { grid-column: 1 / -1; }
  .manager-dashboard .team-table td:nth-child(3), .manager-dashboard .team-table td:nth-child(4) { display: grid; gap: 4px; }
  .manager-dashboard .team-table td:nth-child(3)::before, .manager-dashboard .team-table td:nth-child(4)::before { color: var(--app-muted); content: 'Today'; font-size: 10px; font-weight: 650; letter-spacing: .04em; text-transform: uppercase; }
  .manager-dashboard .team-table td:nth-child(4)::before { content: 'This week'; }
  .manager-dashboard .team-table td.member-actions { grid-column: 1 / -1; padding: 3px 0 0 !important; text-align: right; }
  .manager-dashboard .member-actions .view-button { min-height: 40px; padding: 0 16px; border-radius: 10px; font-size: 12px; }
  .manager-dashboard .team-table tbody tr { padding: 12px; }
.manager-dashboard .manager-main { color: var(--app-text); }
.manager-dashboard .team-table th { height: 42px; }
.manager-dashboard .team-table td { height: 64px; }
.manager-dashboard .employee-avatar { width: 36px; height: 36px; flex-basis: 36px; }
.manager-dashboard .view-button { min-height: 34px; padding-inline: 13px; border-radius: 9px; font-size: 11px; }
  .manager-dashboard .team-table tbody tr { border-radius: 17px; }
.manager-dashboard .team-table th { height: 48px; font-size: 12px; }
.manager-dashboard .team-table td { height: 72px; font-size: 14px; }
.manager-dashboard .employee-avatar { width: 42px; height: 42px; flex-basis: 42px; font-size: 11px; }
.manager-dashboard .view-button { min-height: 40px; padding-inline: 15px; font-size: 13px; }
  .manager-dashboard .team-table tbody tr { gap: 12px 14px; padding: 16px; }
  .manager-dashboard .team-table td { font-size: 14px; }
</style>
