import api from '../api'
import { getAvatarTone, getDisplayName, getInitials } from '../utils/identity'
import { startOfLocalDay, startOfLocalWeek, sumWorkMinutes } from '../utils/time'

/**
 * Provide manager dashboard data operations and normalize API responses
 * into the shapes used by the team and member views.
 */
export function useManagerDashboard() {
  /** Load the manager profile, team members, unassigned employees, and their time summaries. */
  async function loadDashboard(managerId) {
    const [profileResponse, teamResponse, unassignedResponse] = await Promise.all([
      managerId ? api.get(`/users/${managerId}`) : Promise.resolve({ data: { data: {} } }),
      api.get('/users'),
      api.get('/users/unassigned')
    ])
    const profile = profileResponse.data.data || {}
    const unassignedEmployees = (unassignedResponse.data.data || []).map((user, index) => {
      const name = getDisplayName(user, 'Unnamed employee')
      return {
        ...user,
        name,
        managerId: null,
        role: 'Employee',
        status: user.status === 'inactive' ? 'Inactive' : 'Active',
        avatarTone: getAvatarTone(index),
        initials: getInitials(name, 'U')
      }
    })
    const now = new Date()
    const dayStart = startOfLocalDay(now)
    const weekStart = startOfLocalWeek(now)
    const team = await Promise.all((teamResponse.data.data || []).map(async (user, index) => {
      const [clockResult, recordsResult] = await Promise.allSettled([
        api.get(`/clocks/${user.id}`),
        api.get(`/workingtime/${user.id}`)
      ])
      const clock = clockResult.status === 'fulfilled' ? clockResult.value.data.data : null
      const records = recordsResult.status === 'fulfilled' ? recordsResult.value.data.data || [] : []
      const name = getDisplayName(user, 'Unnamed employee')
      return {
        id: user.id,
        name,
        email: user.email,
        initials: getInitials(name, 'U'),
        status: user.status === 'inactive' ? 'Inactive' : 'Active',
        managerId,
        role: 'Employee',
        avatarTone: getAvatarTone(index),
        clock,
        clockState: clock?.state || (clock?.status ? 'working' : 'off'),
        clockedIn: Boolean(clock?.status),
        clockedInSince: clock && (clock.state ? clock.state !== 'off' : clock.status) ? clock.time : null,
        records,
        todayMinutes: sumWorkMinutes(records, dayStart, now, clock, now),
        weekMinutes: sumWorkMinutes(records, weekStart, now, clock, now)
      }
    }))
    return { profile, team, unassignedEmployees }
  }

  /** Refresh team clock states; failed member requests are omitted from the returned updates. */
  async function refreshClockStatuses(team) {
    const results = await Promise.allSettled(team.map((member) => api.get(`/clocks/${member.id}`)))
    return results.flatMap((result, index) => {
      if (result.status !== 'fulfilled') return []
      const clock = result.value.data.data
      const clockState = clock?.state || (clock?.status ? 'working' : 'off')
      return [{
        id: team[index].id,
        clock,
        clockState,
        clockedIn: clockState === 'working',
        clockedInSince: clockState !== 'off' ? clock.time : null
      }]
    })
  }

  /** Load one member's clock and intervals, tolerating either request failing independently. */
  async function loadMemberTimeData(memberId) {
    const [clockResult, recordsResult] = await Promise.allSettled([
      api.get(`/clocks/${memberId}`),
      api.get(`/workingtime/${memberId}`)
    ])
    const clock = clockResult.status === 'fulfilled' ? clockResult.value.data.data : null
    const records = recordsResult.status === 'fulfilled' ? recordsResult.value.data.data || [] : []
    return {
      clock,
      records,
      clockState: clock?.state || (clock?.status ? 'working' : 'off'),
      clockedInSince: clock && (clock.state ? clock.state !== 'off' : clock.status) ? clock.time : null
    }
  }

  /** Assign an employee to a manager, or clear the assignment when managerId is null. */
  async function updateMembership(employeeId, managerId) {
    return api.patch(`/users/${employeeId}`, { user: { manager_id: managerId } })
  }

  /** Expose the manager data operations to the view. */
  return { loadDashboard, refreshClockStatuses, loadMemberTimeData, updateMembership }
}
