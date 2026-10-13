<template>
  <AppShell :navigation="navigation" :active-tab="activeTab" @navigate="navigateTab" @logout="disconnect">
    <div class="manager-main">
      <div class="manager-content">
        <section v-if="activeTab === 'team'" id="dashboard" class="dashboard-section">
          <div class="page-heading"><div><p class="eyebrow">TEAM OVERVIEW</p><h1>Team</h1><p class="page-subtitle">Attendance and working times for your team.</p></div></div>

          <div v-if="loadError" class="load-error" role="alert">{{ loadError }} <button @click="loadDashboard">Try again</button></div>

          <section class="summary-grid" aria-label="Team summary">
            <article class="summary-card"><span class="summary-icon icon-blue"><svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M16 5.5a3.2 3.2 0 0 1 0 6.2M17 14a5 5 0 0 1 3.5 4.8"/></svg></span><strong>{{ team.length }}</strong><span>Team members</span></article>
            <article class="summary-card"><span class="summary-icon icon-green"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><strong>{{ clockedInCount }}</strong><span>Clocked in now</span></article>
            <article class="summary-card"><span class="summary-icon icon-amber"><svg viewBox="0 0 24 24"><path d="M9 5v14M15 5v14"/></svg></span><strong>{{ onBreakCount }}</strong><span>On break</span></article>
            <article class="summary-card"><span class="summary-icon icon-amber"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span><strong>{{ formatMinutes(todayTeamMinutes) }}</strong><span>Team hours today</span></article>
          </section>

          <section class="insights-grid" aria-label="Working time overview">
            <article class="insight-card hours-card"><div class="insight-heading"><div><h2>Team working hours</h2><p>This week</p></div><strong>{{ formatMinutes(weekTeamMinutes) }}</strong></div>
              <WeeklyHoursChart variant="manager" :days="weekBars" :label="`Team hours this week: ${formatMinutes(weekTeamMinutes)}`" />
            </article>
            <article class="insight-card live-card"><h2>Live team status</h2><p class="live-count"><strong>{{ clockedInCount }}</strong><span>of {{ activeTeamCount }} active members working</span></p><div class="live-progress" role="progressbar" :aria-valuenow="clockedInCount" :aria-valuemin="0" :aria-valuemax="activeTeamCount || 1"><span :style="{ width: `${clockedInPercent}%` }"></span></div><div class="live-legend"><span><i class="dot-working"></i>Working <strong>{{ clockedInCount }}</strong></span><span><i class="dot-break"></i>Break <strong>{{ onBreakCount }}</strong></span><span><i class="dot-off"></i>Off <strong>{{ offClockCount }}</strong></span></div></article>
          </section>

          <section id="team" class="team-panel" aria-labelledby="team-heading">
            <header class="team-panel-heading"><div><h2 id="team-heading">Team members <span class="count-pill">{{ filteredTeam.length }}</span></h2><p>Clock status refreshes automatically; hours come from recorded work times.</p></div><label class="team-search"><svg viewBox="0 0 24 24"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 4.5 4.5"/></svg><input v-model="searchQuery" type="search" placeholder="Search team…" aria-label="Search team members" /></label></header>
            <div v-if="loading" class="team-empty">Loading your team…</div>
            <div v-else-if="!filteredTeam.length" class="team-empty">{{ team.length ? 'No team members match your search.' : 'No employees are assigned to your team yet.' }}</div>
            <div v-else class="team-table-scroll"><table class="team-table"><thead><tr><th>EMPLOYEE</th><th>STATUS</th><th>TODAY</th><th>THIS WEEK</th></tr></thead><tbody>
              <tr v-for="member in filteredTeam" :key="member.id"><td><button type="button" class="employee-cell" :aria-label="`View statistics for ${member.name}`" @click="selectedMember = member"><InitialAvatar variant="employee-avatar" :tone="member.avatarTone" :initials="member.initials" /><span><strong>{{ member.name }}</strong><small>{{ member.email }}</small></span></button></td><td><span class="status-group"><span class="work-status" :class="member.status === 'Inactive' ? 'suspended' : member.clockState !== 'off' ? 'working' : 'off-clock'"><i></i>{{ member.status === 'Inactive' ? 'Suspended' : member.clockState !== 'off' ? 'Working' : 'Off the clock' }}</span><span v-if="member.status === 'Active' && member.clockState === 'break'" class="break-indicator"><i></i>On break</span></span></td><td>{{ formatMinutes(memberTodayMinutes(member)) }}</td><td>{{ formatMinutes(memberWeekMinutes(member)) }}</td></tr>
            </tbody></table></div>
          </section>
        </section>
        <section v-else class="manager-profile-section">
          <div class="page-heading"><div><p class="eyebrow">ACCOUNT DETAILS</p><h1>Profile</h1><p class="page-subtitle">Your Time Manager account information.</p></div></div>
          <article class="card profile-card"><InitialAvatar variant="profile-avatar" :initials="initials" /><div><h2>{{ displayName }}</h2><p>{{ profile.email || 'Email not available' }}</p><span class="profile-role">Manager</span></div></article>
          <button class="profile-logout" type="button" @click="disconnect">Log out</button>
        </section>
      </div>
    </div>
    <Transition name="detail-fade"><div v-if="selectedMember" class="detail-backdrop" @click.self="selectedMember = null"><section class="detail-dialog" role="dialog" aria-modal="true" aria-labelledby="detail-heading"><header><div><p class="eyebrow">TEAM MEMBER</p><h2 id="detail-heading">{{ selectedMember.name }}</h2><p>{{ selectedMember.email }}</p></div><button class="close-button" aria-label="Close details" @click="selectedMember = null">×</button></header><div class="detail-metrics"><div><small>Today</small><strong>{{ formatMinutes(memberTodayMinutes(selectedMember)) }}</strong></div><div><small>This week</small><strong>{{ formatMinutes(memberWeekMinutes(selectedMember)) }}</strong></div></div><div class="detail-chart"><div><h3>Working hours this week</h3><strong>{{ formatMinutes(memberWeekMinutes(selectedMember)) }}</strong></div><WeeklyHoursChart variant="manager" :days="selectedMemberWeekBars" :label="`${selectedMember.name} hours this week: ${formatMinutes(memberWeekMinutes(selectedMember))}`" /></div><div class="detail-clock"><span class="status-group"><span class="work-status" :class="selectedMember.status === 'Inactive' ? 'suspended' : selectedMember.clockState !== 'off' ? 'working' : 'off-clock'"><i></i>{{ selectedMember.status === 'Inactive' ? 'Suspended' : selectedMember.clockState !== 'off' ? 'Working now' : 'Off the clock' }}</span><span v-if="selectedMember.status === 'Active' && selectedMember.clockState === 'break'" class="break-indicator"><i></i>On break</span></span><small v-if="selectedMember.clockedInSince">{{ selectedMember.clockState === 'break' ? 'Break started' : 'Since' }} {{ formatTime(selectedMember.clockedInSince) }}</small></div></section></div></Transition>
  </AppShell>
</template>

<script>
import api from '../api'
import { getAvatarTone, getDisplayName, getInitials } from '../utils/identity'
import InitialAvatar from './InitialAvatar.vue'
import AppShell from './AppShell.vue'
import WeeklyHoursChart from './WeeklyHoursChart.vue'

function startOfLocalDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function startOfLocalWeek(date) {
  const start = startOfLocalDay(date)
  const daysSinceMonday = (start.getDay() + 6) % 7
  start.setDate(start.getDate() - daysSinceMonday)
  return start
}

function overlappingMinutes(startValue, endValue, rangeStart, rangeEnd) {
  const start = Math.max(new Date(startValue).getTime(), rangeStart.getTime())
  const end = Math.min(new Date(endValue).getTime(), rangeEnd.getTime())
  return Number.isFinite(start) && Number.isFinite(end) && end > start ? Math.floor((end - start) / 60000) : 0
}

function sumMinutes(records, rangeStart, rangeEnd, activeClock, now) {
  const recorded = records.reduce((total, record) => {
    if (record.kind === 'break') return total
    if (!record.start || !record.end) return total
    return total + overlappingMinutes(record.start, record.end, rangeStart, rangeEnd)
  }, 0)
  if (activeClock?.status && activeClock.time) {
    return recorded + overlappingMinutes(activeClock.time, now, rangeStart, rangeEnd)
  }
  return recorded
}

export default {
  name: 'ManagerDashboard',
  components: { AppShell, InitialAvatar, WeeklyHoursChart },
  data() {
    return {
      userId: sessionStorage.getItem('userId'),
      activeTab: 'team',
      profile: {},
      team: [],
      loading: true,
      refreshingClockStatuses: false,
      loadError: '',
      searchQuery: '',
      selectedMember: null,
      now: new Date()
    }
  },
  computed: {
    navigation() {
      return [
        { key: 'team', label: 'Team', icon: 'teams' },
        { key: 'profile', label: 'Profile', icon: 'profile' }
      ]
    },
    displayName() {
      return getDisplayName(this.profile, 'Manager')
    },
    initials() {
      return getInitials(this.displayName)
    },
    filteredTeam() {
      const query = this.searchQuery.trim().toLowerCase()
      return this.team.filter((member) => !query || `${member.name} ${member.email}`.toLowerCase().includes(query))
    },
    activeTeamCount() {
      return this.team.filter((member) => member.status === 'Active').length
    },
    clockedInCount() {
      return this.team.filter((member) => member.status === 'Active' && member.clockedIn).length
    },
    offClockCount() {
      return Math.max(this.activeTeamCount - this.clockedInCount - this.onBreakCount, 0)
    },
    onBreakCount() {
      return this.team.filter((member) => member.status === 'Active' && member.clockState === 'break').length
    },
    clockedInPercent() {
      return this.activeTeamCount ? Math.round(this.clockedInCount / this.activeTeamCount * 100) : 0
    },
    todayTeamMinutes() {
      return this.team.reduce((total, member) => total + this.memberTodayMinutes(member), 0)
    },
    weekTeamMinutes() {
      return this.team.reduce((total, member) => total + this.memberWeekMinutes(member), 0)
    },
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
  beforeUnmount() {
    window.clearInterval(this.refreshTimer)
    document.removeEventListener('visibilitychange', this.handleVisibilityChange)
    window.removeEventListener('focus', this.handleVisibilityChange)
  },
  methods: {
    navigateTab(tab) {
      this.activeTab = tab
      this.selectedMember = null
    },
    formatMinutes(minutes) {
      const safeMinutes = Math.max(0, Math.floor(minutes || 0))
      return `${Math.floor(safeMinutes / 60)}h ${String(safeMinutes % 60).padStart(2, '0')}m`
    },
    formatTime(value) {
      return new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' }).format(new Date(value))
    },
    memberTodayMinutes(member) {
      return sumMinutes(member.records, startOfLocalDay(this.now), this.now, member.clock, this.now)
    },
    memberWeekMinutes(member) {
      return sumMinutes(member.records, startOfLocalWeek(this.now), this.now, member.clock, this.now)
    },
    async refreshClockStatuses() {
      if (this.refreshingClockStatuses || this.team.length === 0) return
      this.refreshingClockStatuses = true
      try {
        const results = await Promise.allSettled(this.team.map((member) => api.get(`/clocks/${member.id}`)))
        results.forEach((result, index) => {
          if (result.status !== 'fulfilled') return
          const clock = result.value.data.data
          const member = this.team[index]
          member.clock = clock
          member.clockState = clock?.state || (clock?.status ? 'working' : 'off')
          member.clockedIn = member.clockState === 'working'
          member.clockedInSince = member.clockState !== 'off' ? clock.time : null
        })
        this.now = new Date()
      } finally {
        this.refreshingClockStatuses = false
      }
    },
    async loadDashboard() {
      this.loading = true
      this.loadError = ''
      try {
        const [profileResponse, teamResponse] = await Promise.all([
          this.userId ? api.get(`/users/${this.userId}`) : Promise.resolve({ data: { data: {} } }),
          api.get('/users')
        ])
        this.profile = profileResponse.data.data || {}
        const users = teamResponse.data.data || []
        const now = new Date()
        const dayStart = startOfLocalDay(now)
        const weekStart = startOfLocalWeek(now)
        this.team = await Promise.all(users.map(async (user, index) => {
          const [clockResult, recordsResult] = await Promise.allSettled([
            api.get(`/clocks/${user.id}`),
            api.get(`/workingtime/${user.id}`)
          ])
          const clock = clockResult.status === 'fulfilled' ? clockResult.value.data.data : null
          const records = recordsResult.status === 'fulfilled' ? recordsResult.value.data.data || [] : []
          const displayName = getDisplayName(user, 'Unnamed employee')
          const initials = getInitials(displayName, 'U')
          return {
            id: user.id,
            name: displayName,
            email: user.email,
            initials,
            status: user.status === 'inactive' ? 'Inactive' : 'Active',
            avatarTone: getAvatarTone(index),
            clock,
            clockState: clock?.state || (clock?.status ? 'working' : 'off'),
            clockedIn: Boolean(clock?.status),
            clockedInSince: clock && (clock.state ? clock.state !== 'off' : clock.status) ? clock.time : null,
            records,
            todayMinutes: sumMinutes(records, dayStart, now, clock, now),
            weekMinutes: sumMinutes(records, weekStart, now, clock, now)
          }
        }))
      } catch (error) {
        console.error('Could not load manager dashboard:', error)
        this.loadError = error.response?.status === 403
          ? 'Manager access is required to view your team.'
          : 'Could not load your team. Please try again.'
      } finally {
        this.loading = false
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
.manager-main { --manager-ink: var(--app-text); --manager-muted: var(--app-muted); min-width: 0; }
.manager-content { width: 100%; margin: 0; padding: 0; color: var(--manager-ink); }
.manager-profile-section { max-width: 720px; }
.manager-profile-section .page-heading { margin-bottom: 20px; }
.manager-profile-section .page-heading h1 { font-size: 28px; }
.profile-card { display: flex; align-items: center; gap: 18px; padding: 24px; border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: #fff; box-shadow: var(--app-shadow-profile); }
.profile-avatar { display: grid; width: 62px; height: 62px; flex: 0 0 62px; place-items: center; border-radius: 50%; color: #fff; background: var(--app-accent); font-size: 19px; font-weight: 700; }
.profile-card h2 { margin: 0 0 6px; font-size: 18px; }
.profile-card p { margin: 0; color: var(--app-muted); font-size: 14px; }
.profile-role { display: inline-block; margin-top: 10px; padding: 5px 9px; border-radius: 999px; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 11px; font-weight: 650; }
.profile-logout { min-height: 44px; margin-top: 16px; padding: 0 17px; border: 1px solid var(--app-border); border-radius: 11px; color: #48515c; background: #fff; font: inherit; font-weight: 600; cursor: pointer; transition: background .16s ease, border-color .16s ease; }
.profile-logout:hover, .profile-logout:focus-visible { border-color: #d2d8e2; background: #f7f9fc; outline: none; }
.page-heading { margin-bottom: 17px; }
.eyebrow { margin: 0 0 5px; color: #8290a1; font-size: 8px; font-weight: 750; letter-spacing: 1px; }
.page-heading h1 { margin: 0; color: #1f2937; font-size: 23px; font-weight: 740; letter-spacing: -.55px; }
.page-subtitle { margin: 5px 0 0; color: #8994a3; font-size: 10px; }
.load-error { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 14px; padding: 10px 12px; border: 1px solid #f0c9c9; border-radius: 7px; color: #a33636; background: #fff4f4; font-size: 10px; }
.load-error button { border: 0; color: #a33636; background: none; font: inherit; font-weight: 700; cursor: pointer; }
.summary-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 11px; margin-bottom: 12px; }
.summary-card { display: grid; min-height: 116px; align-content: start; justify-items: start; padding: 14px; border: 1px solid #eceef2; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); }
.summary-icon { display: grid; width: 29px; height: 29px; place-items: center; margin-bottom: 10px; border-radius: 8px; }
.summary-icon svg { width: 16px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.icon-blue { color: #1683f8; background: #eaf3ff; }
.icon-green { color: #25bd5a; background: #eaf9ee; }
.icon-red { color: #e9514e; background: #fff0ef; }
.icon-amber { color: #f29a20; background: #fff5e7; }
.summary-card > strong { color: #202936; font-size: 21px; font-weight: 730; letter-spacing: -.45px; }
.summary-card > span:last-child { margin-top: 3px; color: #929baa; font-size: 9px; }
.insights-grid { display: grid; grid-template-columns: minmax(0, 1.55fr) minmax(245px, 1fr); gap: 12px; margin-bottom: 13px; }
.insight-card { min-height: 154px; padding: 16px 18px; border: 1px solid #eceef2; border-radius: 11px; background: white; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); }
.insight-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.insight-heading h2, .live-card h2 { margin: 0; color: #303a49; font-size: 11px; font-weight: 700; }
.insight-heading p { margin: 4px 0 0; color: #929baa; font-size: 9px; }
.insight-heading > strong { color: #202936; font-size: 18px; font-weight: 730; }
.live-card { display: flex; flex-direction: column; justify-content: center; }
.live-count { display: flex; align-items: baseline; gap: 7px; margin: 13px 0 9px; }
.live-count strong { color: #202936; font-size: 24px; font-weight: 730; }
.live-count span { color: #929baa; font-size: 9px; }
.live-progress { height: 7px; overflow: hidden; border-radius: 9px; background: #edf0f4; }
.live-progress span { display: block; height: 100%; border-radius: inherit; background: #31c765; transition: width .2s ease; }
.live-legend { display: flex; justify-content: space-between; gap: 10px; margin-top: 12px; color: #7f8998; font-size: 8px; }
.live-legend span { display: flex; align-items: center; gap: 5px; }
.live-legend strong { color: #495565; }
.live-legend i { width: 7px; height: 7px; border-radius: 50%; }
.dot-working { background: #31c765; }
.dot-break { background: #f2a52b; }
.dot-off { background: #c4cad3; }
.team-panel { overflow: hidden; border: 1px solid #eceef2; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(25 39 61 / 4%); scroll-margin-top: 73px; }
.team-panel-heading { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 14px 16px; border-bottom: 1px solid #eceef2; }
.team-panel-heading h2 { display: flex; align-items: center; gap: 7px; margin: 0; color: #303a49; font-size: 11px; font-weight: 700; }
.count-pill { padding: 3px 6px; border-radius: 999px; color: #657184; background: #f0f2f5; font-size: 8px; }
.team-panel-heading p { margin: 4px 0 0; color: #929baa; font-size: 9px; }
.team-search { display: flex; width: min(225px, 45%); min-height: 31px; align-items: center; gap: 7px; padding: 0 9px; border: 1px solid #e5e8ed; border-radius: 6px; background: #fff; }
.team-search:focus-within { border-color: #82b8f3; box-shadow: 0 0 0 3px rgb(22 131 248 / 9%); }
.team-search svg { width: 13px; fill: none; stroke: #929baa; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; }
.team-search input { width: 100%; min-width: 0; border: 0; outline: 0; color: #354153; background: transparent; font: inherit; font-size: 9px; }
.team-search input::placeholder { color: #a1a9b5; }
.team-table-scroll { width: 100%; overflow-x: auto; }
.team-table { width: 100%; border-collapse: collapse; text-align: left; white-space: nowrap; }
.team-table th { height: 33px; padding: 0 13px; border-bottom: 1px solid #eceef2; color: #929baa; font-size: 8px; font-weight: 720; letter-spacing: .6px; }
.team-table th:first-child, .team-table td:first-child { padding-left: 16px; }
.team-table td { height: 51px; padding: 0 13px; border-bottom: 1px solid #f0f2f5; color: #536071; font-size: 9px; }
.team-table tbody tr:last-child td { border-bottom: 0; }
.employee-cell { display: flex; width: 100%; align-items: center; gap: 9px; padding: 0; border: 0; color: inherit; background: transparent; font: inherit; text-align: left; cursor: pointer; }
.employee-cell:focus-visible { border-radius: 8px; outline: 2px solid var(--app-accent); outline-offset: 3px; }
.employee-cell:hover strong { color: var(--app-accent-strong); }
.employee-avatar { display: grid; width: 29px; height: 29px; flex: 0 0 29px; place-items: center; border-radius: 50%; font-size: 8px; font-weight: 700; }
.employee-cell > span:last-child { display: grid; gap: 3px; }
.employee-cell strong { color: #354153; font-size: 9px; font-weight: 650; }
.employee-cell small { color: #929baa; font-size: 8px; }
.tone-lilac { color: #5d4db1; background: #efebff; }.tone-peach { color: #a95236; background: #fff0e8; }.tone-mint { color: #247458; background: #e7f7ef; }.tone-sky { color: #3869a5; background: #e8f2ff; }.tone-rose { color: #a94a70; background: #ffedf3; }.tone-gold { color: #8a6827; background: #fff5d9; }.tone-blue { color: #4260a9; background: #e8eeff; }
.status-group { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.work-status { display: inline-flex; align-items: center; gap: 5px; color: #788393; font-size: 8px; }
.work-status i { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.work-status.working { color: #178b50; }.work-status.off-clock { color: #8b95a3; }.work-status.suspended { color: #b34848; }
.break-indicator { display: inline-flex; align-items: center; gap: 4px; padding: 3px 7px; border-radius: 999px; color: #875900; background: #fff2cf; font-size: 9px; font-weight: 650; white-space: nowrap; }
.break-indicator i { width: 6px; height: 6px; border-radius: 50%; background: #f3b536; }
.view-button { min-height: 25px; padding: 0 9px; border: 1px solid #dbeaff; border-radius: 6px; color: #1677df; background: #edf5ff; font: inherit; font-size: 8px; font-weight: 680; cursor: pointer; }
.view-button:hover, .view-button:focus-visible { border-color: #b6d6fc; background: #e2efff; outline: none; }
.member-actions { text-align: right; padding-right: 16px !important; }
.team-empty { padding: 27px 15px; color: #8994a3; font-size: 10px; text-align: center; }
.detail-backdrop { position: fixed; z-index: 10; inset: 0; display: grid; place-items: center; padding: 16px; background: rgb(18 28 43 / 35%); backdrop-filter: blur(2px); }
.detail-dialog { width: min(100%, 390px); padding: 18px; border: 1px solid #e8ebf0; border-radius: 12px; background: #fff; box-shadow: 0 18px 50px rgb(18 28 43 / 20%); }
.detail-dialog > header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.detail-dialog h2 { margin: 0; color: #202936; font-size: 18px; }
.detail-dialog header p:last-child { margin: 5px 0 0; color: #8994a3; font-size: 10px; }
.close-button { width: 27px; height: 27px; border: 1px solid #e5e8ed; border-radius: 6px; color: #788393; background: white; font-size: 20px; line-height: 1; cursor: pointer; }
.detail-metrics { display: grid; grid-template-columns: 1fr 1fr; gap: 9px; margin-top: 18px; }
.detail-metrics > div { display: grid; gap: 6px; padding: 12px; border: 1px solid #edf0f4; border-radius: 8px; background: #fafbfc; }
.detail-metrics small, .detail-clock small { color: #8994a3; font-size: 9px; }
.detail-metrics strong { color: #303a49; font-size: 15px; }
.detail-clock { display: flex; justify-content: space-between; gap: 10px; margin-top: 14px; }
.detail-fade-enter-active, .detail-fade-leave-active { transition: opacity .16s ease; }
.detail-fade-enter-from, .detail-fade-leave-to { opacity: 0; }

/* Keep the manager workspace on the same palette and readable type scale as employee and admin. */
.manager-content { color: var(--app-text); }
.eyebrow { font-size: 10px; }
.page-heading h1 { color: var(--app-text); font-size: 30px; }
.page-subtitle { color: var(--app-muted); font-size: 14px; }
.summary-card, .insight-card, .team-panel { border-color: var(--app-border); background: var(--app-surface); }
.summary-card > strong { color: var(--app-text); font-size: 26px; }
.summary-card > span:last-child { color: var(--app-muted); font-size: 12px; }
.insight-heading h2, .live-card h2, .team-panel-heading h2 { color: var(--app-text); font-size: 15px; }
.insight-heading p, .team-panel-heading p { color: var(--app-muted); font-size: 12px; }
.insight-heading > strong { color: var(--app-text); font-size: 21px; }
.live-count strong { color: var(--app-text); }
.live-count span, .live-legend { font-size: 11px; }
.team-panel-heading { border-color: var(--app-border); }
.team-table th { border-color: var(--app-border); font-size: 10px; }
.team-table td { border-color: var(--app-border); font-size: 12px; }
.employee-cell strong { font-size: 12px; }
.employee-cell small { font-size: 10px; }
.employee-avatar { font-size: 10px; }
.work-status { font-size: 10px; }
.view-button { border-color: #d7e9fb; color: var(--app-accent-strong); background: var(--app-accent-soft); font-size: 10px; }
.team-empty { color: var(--app-muted); font-size: 12px; }
.detail-dialog { border-color: var(--app-border); background: var(--app-surface); }
.detail-dialog h2 { color: var(--app-text); }
.detail-dialog header p:last-child, .detail-metrics small, .detail-clock small { color: var(--app-muted); font-size: 11px; }
.detail-metrics strong { color: var(--app-text); font-size: 16px; }
.detail-metrics > div { border-color: var(--app-border); background: var(--app-background); }
.detail-chart { margin-top: 14px; padding: 12px; border: 1px solid var(--app-border); border-radius: 9px; }
.detail-chart > div { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.detail-chart h3 { margin: 0; color: var(--app-text); font-size: 12px; }
.detail-chart > div > strong { color: var(--app-text); font-size: 13px; }
.team-search { border-color: var(--app-border); background: var(--app-surface); }
.team-search input { color: var(--app-text); font-size: 12px; }
.team-search:focus-within { border-color: var(--app-accent); box-shadow: 0 0 0 3px rgb(22 132 248 / 12%); }

@media (max-width: 940px) { .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }.insights-grid { grid-template-columns: minmax(0, 1.3fr) minmax(210px, 1fr); } }
@media (max-width: 680px) {
  .manager-content { padding-bottom: 5px; }
  .page-heading { margin-bottom: 15px; }
  .page-heading h1 { font-size: 27px; }
  .page-subtitle { font-size: 12px; }
  .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; margin-bottom: 12px; }
  .summary-card { min-height: 110px; padding: 13px; border-radius: 16px; }
  .summary-icon { width: 34px; height: 34px; margin-bottom: 8px; border-radius: 10px; }
  .summary-icon svg { width: 18px; }
  .summary-card > strong { font-size: 22px; }
  .summary-card > span:last-child { font-size: 11px; }
  .insights-grid { grid-template-columns: 1fr; }
  .insight-card { min-height: 140px; padding: 17px; border-radius: 17px; }
  .team-panel { border-radius: 17px; }
  .team-panel-heading { padding: 16px; }
  .team-panel-heading h2 { font-size: 15px; }
  .team-panel-heading p { font-size: 11px; line-height: 1.45; }
  .team-panel-heading { align-items: flex-start; flex-direction: column; }
  .team-search { width: 100%; min-height: 42px; padding: 0 12px; border-radius: 11px; }
  .team-search svg { width: 17px; }
  .team-table-scroll { overflow: visible; padding: 10px; }
  .team-table { display: block; width: 100%; min-width: 0; white-space: normal; }
  .team-table thead { display: none; }
  .team-table tbody { display: grid; gap: 11px; }
  .team-table tbody tr { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 12px; padding: 14px; border: 1px solid var(--app-border); border-radius: 15px; background: var(--app-surface); box-shadow: 0 4px 13px rgb(27 41 61 / 4%); }
  .team-table td { display: block; height: auto; min-width: 0; padding: 0 !important; border: 0; font-size: 13px; }
  .team-table td:first-child, .team-table td:nth-child(2) { grid-column: 1 / -1; }
  .team-table td:nth-child(3), .team-table td:nth-child(4) { display: grid; gap: 4px; }
  .team-table td:nth-child(3)::before, .team-table td:nth-child(4)::before { color: var(--app-muted); content: 'Today'; font-size: 10px; font-weight: 650; letter-spacing: .04em; text-transform: uppercase; }
  .team-table td:nth-child(4)::before { content: 'This week'; }
  .team-table td.member-actions { grid-column: 1 / -1; padding: 3px 0 0 !important; text-align: right; }
  .member-actions .view-button { min-height: 40px; padding: 0 16px; border-radius: 10px; font-size: 12px; }
  .employee-cell { min-width: 0; }
  .employee-cell strong, .employee-cell small { overflow-wrap: anywhere; }
  .live-legend { flex-wrap: wrap; justify-content: flex-start; gap: 8px 14px; }
}

@media (max-width: 360px) {
  .summary-card { min-height: 102px; padding: 11px; }
  .summary-card > span:last-child { font-size: 10px; }
  .team-table tbody tr { padding: 12px; }
}

/* Shared light workspace styling across employee, manager, and admin pages. */
.manager-main { color: var(--app-text); }
.page-heading h1 { letter-spacing: -.7px; }
.summary-card, .insight-card, .team-panel { border-radius: var(--app-radius-panel); box-shadow: var(--app-shadow-panel); }
.summary-card { min-height: 132px; padding: 17px; }
.summary-icon { width: 36px; height: 36px; border-radius: 11px; }
.summary-card > strong { font-size: 25px; }
.summary-card > span:last-child { font-size: 12px; }
.insight-card { min-height: 190px; padding: 20px; }
.insight-heading h2, .live-card h2, .team-panel-heading h2 { font-size: 16px; }
.insight-heading p, .team-panel-heading p { font-size: 12px; }
.insight-heading > strong { font-size: 24px; }
.team-panel-heading { padding: 18px 20px; }
.team-table th { height: 42px; }
.team-table td { height: 64px; }
.employee-avatar { width: 36px; height: 36px; flex-basis: 36px; }
.employee-cell { gap: 11px; }
.employee-cell strong { font-size: 13px; }
.employee-cell small { font-size: 11px; }
.work-status { font-size: 11px; }
.view-button { min-height: 34px; padding-inline: 13px; border-radius: 9px; font-size: 11px; }

@media (max-width: 680px) {
  .summary-card { min-height: 116px; padding: 14px; }
  .summary-card > strong { font-size: 23px; }
  .summary-card > span:last-child { font-size: 11px; }
  .insight-card { min-height: 155px; padding: 17px; }
  .team-panel-heading { padding: 16px; }
  .team-table tbody tr { border-radius: 17px; }
}

/* Larger type and controls throughout the manager workspace. */
.page-heading { margin-bottom: 30px; }
.page-heading h1 { font-size: 36px; }
.page-subtitle { font-size: 15px; }
.eyebrow { font-size: 12px; }
.summary-grid { gap: 16px; }
.summary-card { min-height: 148px; padding: 20px; }
.summary-icon { width: 42px; height: 42px; margin-bottom: 11px; }
.summary-icon svg { width: 22px; }
.summary-card > strong { font-size: 29px; }
.summary-card > span:last-child { font-size: 14px; }
.insights-grid { gap: 16px; }
.insight-card { min-height: 215px; padding: 24px; }
.insight-heading h2, .live-card h2 { font-size: 18px; }
.insight-heading p { font-size: 14px; }
.insight-heading > strong { font-size: 27px; }
.live-count strong { font-size: 29px; }
.live-count span, .live-legend { font-size: 13px; }
.team-panel-heading { padding: 21px 23px; }
.team-panel-heading h2 { font-size: 18px; }
.team-panel-heading p { font-size: 14px; }
.team-search { min-height: 42px; width: min(280px, 45%); }
.team-search input { font-size: 14px; }
.team-table th { height: 48px; font-size: 12px; }
.team-table td { height: 72px; font-size: 14px; }
.employee-avatar { width: 42px; height: 42px; flex-basis: 42px; font-size: 11px; }
.employee-cell { gap: 13px; }
.employee-cell strong { font-size: 15px; }
.employee-cell small { font-size: 12px; }
.work-status, .break-indicator { font-size: 12px; }
.view-button { min-height: 40px; padding-inline: 15px; font-size: 13px; }
.profile-card { padding: 28px; }
.profile-card h2 { font-size: 21px; }
.profile-card p { font-size: 16px; }
.profile-role { font-size: 13px; }
.profile-logout { min-height: 50px; padding-inline: 20px; font-size: 15px; }

@media (max-width: 680px) {
  .page-heading h1 { font-size: 30px; }
  .summary-card { min-height: 124px; padding: 15px; }
  .summary-card > strong { font-size: 25px; }
  .summary-card > span:last-child { font-size: 12px; }
  .insight-card { min-height: 165px; padding: 19px; }
  .team-panel-heading { padding: 17px; }
  .team-search { width: 100%; min-height: 46px; }
  .team-table tbody tr { gap: 12px 14px; padding: 16px; }
  .team-table td { font-size: 14px; }
  .employee-cell strong { font-size: 14px; }
  .employee-cell small { font-size: 12px; }
}
</style>
