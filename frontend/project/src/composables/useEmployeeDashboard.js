import api from '../api'
import offlineSync from '../offlineSync'

/**
 * Provide the employee dashboard with profile, clock, and interval operations.
 * Time data uses the offline cache when the device has no connection.
 */
export function useEmployeeDashboard() {
  /** Load a profile from the API, falling back to its cached copy when offline or on failure. */
  async function loadProfile(userId) {
    if (!userId) return null
    const cached = offlineSync.getLocalCache(`profile_${userId}`)
    if (!offlineSync.isOnline) return cached

    try {
      const response = await api.get(`/users/${userId}`)
      const profile = response.data.data || {}
      offlineSync.saveLocalCache(`profile_${userId}`, profile)
      return profile
    } catch (error) {
      console.error('Could not load profile:', error)
      return cached
    }
  }

  /** Load current clock state and intervals, returning cached values if the request cannot complete. */
  async function loadTimeData(userId) {
    if (!userId) return { clock: null, workingTimes: null, error: null, offline: false }
    const cachedClock = offlineSync.getLocalCache(`clock_${userId}`)
    const cachedWorkingTimes = offlineSync.getLocalCache(`workingtimes_${userId}`)
    if (!offlineSync.isOnline) {
      return { clock: cachedClock, workingTimes: cachedWorkingTimes, error: null, offline: true }
    }

    try {
      const [clockResponse, timesResponse] = await Promise.all([
        api.get(`/clocks/${userId}`),
        api.get(`/workingtime/${userId}`)
      ])
      const clock = clockResponse.data.data
      const workingTimes = timesResponse.data.data || []
      offlineSync.saveLocalCache(`clock_${userId}`, clock)
      offlineSync.saveLocalCache(`workingtimes_${userId}`, workingTimes)
      return { clock, workingTimes, error: null, offline: false }
    } catch (error) {
      console.error('Could not load time data:', error)
      return { clock: cachedClock, workingTimes: cachedWorkingTimes, error, offline: true }
    }
  }

  /** Fetch the employee's assigned manager for the feedback email workflow. */
  async function loadAssignedManager(userId) {
    const response = await api.get(`/users/${userId}/manager`)
    return response.data.data
  }

  /** Send a clock-in/out or break action for the employee. */
  async function submitClockAction(userId, action) {
    return api.post(`/clocks/${userId}`, { action })
  }

  /** Save a completed work or break interval for the employee. */
  async function saveWorkingInterval(userId, interval) {
    return api.post(`/workingtime/${userId}`, { workingtime: interval })
  }

  /** Expose the employee dashboard operations to the view. */
  return { loadProfile, loadTimeData, loadAssignedManager, submitClockAction, saveWorkingInterval }
}
