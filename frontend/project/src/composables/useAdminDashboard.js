import api from '../api'
import { getAvatarTone, getDisplayName, getInitials } from '../utils/identity'

/**
 * Provide administrator account, team assignment, and statistics operations.
 * User responses are normalized for display by the admin screens.
 */
export function useAdminDashboard() {
  /** Fetch one user's profile fields from the API. */
  async function loadProfile(userId) {
    const response = await api.get(`/users/${userId}`)
    return response.data.data || {}
  }

  /** Fetch workspace users and add display-ready role, status, name, and avatar fields. */
  async function loadUsers() {
    const response = await api.get('/users')
    return (response.data.data || []).map((user, index) => {
      const name = getDisplayName(user, 'Unnamed user')
      return {
        ...user,
        managerId: user.manager_id,
        name,
        initials: getInitials(name, 'U'),
        role: { admin: 'Admin', manager: 'Manager', employee: 'Employee' }[user.role] || 'Employee',
        status: user.status === 'inactive' ? 'Inactive' : 'Active',
        joined: user.joined_at ? new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: '2-digit', timeZone: 'UTC' }).format(new Date(user.joined_at)) : '—',
        avatarTone: getAvatarTone(index)
      }
    })
  }

  /** Fetch a user's completed intervals and latest clock record. */
  async function loadUserTimeData(userId) {
    const [recordsResponse, clockResponse] = await Promise.all([
      api.get(`/workingtime/${userId}`),
      api.get(`/clocks/${userId}`)
    ])
    return { records: recordsResponse.data.data || [], clock: clockResponse.data.data }
  }

  /** Load time data for every employee in the selected manager's team. */
  async function loadManagerTeamTimeData(employees) {
    return Promise.all(employees.map(async (employee) => ({
      ...employee,
      ...await loadUserTimeData(employee.id)
    })))
  }

  /** Change a user's workspace role. */
  async function updateRole(userId, role) {
    return api.patch(`/users/${userId}`, { user: { role } })
  }

  /** Assign an employee to a manager, or remove the assignment with a null managerId. */
  async function updateManagerAssignment(userId, managerId) {
    return api.patch(`/users/${userId}`, { user: { manager_id: managerId } })
  }

  /** Activate or suspend a user's account. */
  async function updateStatus(userId, status) {
    return api.patch(`/users/${userId}`, { user: { status: status.toLowerCase() } })
  }

  /** Permanently delete a user through the backend API. */
  async function deleteUser(userId) {
    return api.delete(`/users/${userId}`)
  }

  /** Expose the admin data operations to the view. */
  return { loadProfile, loadUsers, loadUserTimeData, loadManagerTeamTimeData, updateRole, updateManagerAssignment, updateStatus, deleteUser }
}
