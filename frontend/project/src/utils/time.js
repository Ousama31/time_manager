/** Return local midnight for a date. */
export function startOfLocalDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

/** Return Monday at local midnight for the week containing the given date. */
export function startOfLocalWeek(date) {
  const start = startOfLocalDay(date)
  start.setDate(start.getDate() - (start.getDay() + 6) % 7)
  return start
}

/** Count the minutes where an interval overlaps a requested date range. */
export function overlappingMinutes(startValue, endValue, rangeStart, rangeEnd) {
  const start = Math.max(new Date(startValue).getTime(), rangeStart.getTime())
  const end = Math.min(new Date(endValue).getTime(), rangeEnd.getTime())
  return Number.isFinite(start) && Number.isFinite(end) && end > start ? Math.floor((end - start) / 60000) : 0
}

/** Sum work intervals in a range, ignoring breaks and adding a running clock when present. */
export function sumWorkMinutes(records, rangeStart, rangeEnd, activeClock, now) {
  const recorded = records.reduce((total, record) => {
    if (record.kind === 'break' || !record.start || !record.end) return total
    return total + overlappingMinutes(record.start, record.end, rangeStart, rangeEnd)
  }, 0)
  return activeClock?.status && activeClock.time
    ? recorded + overlappingMinutes(activeClock.time, now, rangeStart, rangeEnd)
    : recorded
}

/** Return a non-negative interval duration in seconds, or zero for invalid dates. */
export function durationSeconds(start, end) {
  if (!start || !end) return 0
  const seconds = Math.floor((new Date(end).getTime() - new Date(start).getTime()) / 1000)
  return Number.isFinite(seconds) ? Math.max(0, seconds) : 0
}

/** Format a duration in seconds as hours and zero-padded minutes. */
export function formatDuration(seconds) {
  const safeSeconds = Math.max(0, Math.floor(seconds || 0))
  const hours = Math.floor(safeSeconds / 3600)
  const minutes = Math.floor((safeSeconds % 3600) / 60)
  return `${hours}h ${String(minutes).padStart(2, '0')}m`
}

/** Format a minute count as hours and zero-padded minutes. */
export function formatMinutes(minutes) {
  const safeMinutes = Math.max(0, Math.floor(minutes || 0))
  return `${Math.floor(safeMinutes / 60)}h ${String(safeMinutes % 60).padStart(2, '0')}m`
}

/** Format a timestamp as a localized time, or an em dash when it is missing. */
export function formatTime(value, options = { hour: '2-digit', minute: '2-digit' }) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(undefined, options).format(new Date(value))
}

/** Format a timestamp as a localized date, or an em dash when it is missing. */
export function formatDate(value, options = { month: 'short', day: 'numeric', year: 'numeric' }) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(undefined, options).format(new Date(value))
}

/** Build daily chart values and normalized bar heights for a Monday-to-Sunday week. */
export function buildWeeklyWorkBars(sources, now) {
  const monday = startOfLocalWeek(now)
  const days = Array.from({ length: 7 }, (_, index) => {
    const dayStart = new Date(monday)
    dayStart.setDate(monday.getDate() + index)
    const dayEnd = new Date(dayStart)
    dayEnd.setDate(dayStart.getDate() + 1)
    const end = dayEnd > now ? now : dayEnd
    const minutes = sources.reduce((total, source) => (
      total + sumWorkMinutes(source.records || [], dayStart, end, source.clock, now)
    ), 0)
    return { key: index, label: new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(dayStart), minutes }
  })
  const max = Math.max(...days.map((day) => day.minutes), 1)
  return days.map((day) => ({ ...day, height: day.minutes ? Math.max(8, Math.round(day.minutes / max * 100)) : 0 }))
}
