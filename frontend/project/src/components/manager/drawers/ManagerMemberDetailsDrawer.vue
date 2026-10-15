<template>
      <div v-if="selectedMember" class="detail-backdrop" @click.self="close">
        <section class="detail-dialog" role="dialog" aria-modal="true" aria-labelledby="detail-heading">
          <header>
            <div><p class="eyebrow">TEAM MEMBER</p><h2 id="detail-heading">{{ selectedMember.name }}</h2><p>{{ selectedMember.email }}</p></div>
            <button class="close-button" aria-label="Close details" @click="close">×</button>
          </header>
          <p v-if="selectedMemberLoading" class="membership-loading">Loading employee statistics...</p>
          <template v-else-if="selectedMember.managerId">
            <div class="detail-metrics">
              <div><small>Today</small><strong>{{ formatMinutes(todayMinutes) }}</strong></div>
              <div><small>This week</small><strong>{{ formatMinutes(weekMinutes) }}</strong></div>
            </div>
            <div class="detail-chart">
              <div><h3>Working hours this week</h3><strong>{{ formatMinutes(weekMinutes) }}</strong></div>
              <WeeklyHoursChart variant="manager" :days="selectedMemberWeekBars" :label="`${selectedMember.name} hours this week: ${formatMinutes(weekMinutes)}`" />
            </div>
            <div class="detail-clock">
              <span class="status-group">
                <span class="work-status" :class="selectedMember.status === 'Inactive' ? 'suspended' : selectedMember.clockState !== 'off' ? 'working' : 'off-clock'"><i></i>{{ selectedMember.status === 'Inactive' ? 'Suspended' : selectedMember.clockState !== 'off' ? 'Working now' : 'Off the clock' }}</span>
                <span v-if="selectedMember.status === 'Active' && selectedMember.clockState === 'break'" class="break-indicator"><i></i>On break</span>
              </span>
              <small v-if="selectedMember.clockedInSince">{{ selectedMember.clockState === 'break' ? 'Break started' : 'Since' }} {{ formatTime(selectedMember.clockedInSince) }}</small>
            </div>
          </template>
          <p v-else class="membership-loading">Statistics are available after this employee joins your team.</p>
          <p v-if="membershipError" class="membership-error" role="alert">{{ membershipError }}</p>
          <EmailDraftForm
            v-if="selectedMember.role === 'Employee' && selectedMember.managerId"
            :subject="messageSubject"
            :body="messageBody"
            :recipient="selectedMember.email"
            :id-prefix="`manager-message-${selectedMember.id}`"
            :error="messageError"
            :success="messageSuccess"
            @update:subject="emitModel('messageSubject', $event)"
            @update:body="emitModel('messageBody', $event)"
            @send="$emit('send-message')"
          />
          <button v-if="selectedMember.role === 'Employee'" type="button" class="team-action drawer-team-action" :class="{ 'team-remove': selectedMember.managerId }" :disabled="teamActionBusy || selectedMemberLoading" @click="toggleMembership">{{ teamActionBusy ? 'Saving...' : selectedMember.managerId ? 'Remove from my team' : 'Add to my team' }}</button>
        </section>
      </div>
</template>

<script>
import WeeklyHoursChart from '../../dashboard/WeeklyHoursChart.vue'
import EmailDraftForm from '../../shared/EmailDraftForm.vue'
import { formatMinutes, formatTime as formatLocalizedTime } from '../../../utils/time'
export default {
  name: 'ManagerMemberDetailsDrawer',
  components: { WeeklyHoursChart, EmailDraftForm },
  props: {
    selectedMember: { type: Object, default: null },
    selectedMemberLoading: { type: Boolean, required: true },
    membershipError: { type: String, default: '' },
    teamActionBusy: { type: Boolean, required: true },
    todayMinutes: { type: Number, default: 0 },
    weekMinutes: { type: Number, default: 0 },
    selectedMemberWeekBars: { type: Array, default: () => [] },
    messageSubject: { type: String, required: true },
    messageBody: { type: String, required: true },
    messageError: { type: String, default: '' },
    messageSuccess: { type: String, default: '' },
    now: { type: Date, required: true }
  },
  methods: {
    emitModel(name, value) { this.$emit(`update:${name}`, value) },
    formatMinutes,
    formatTime(value) { return formatLocalizedTime(value, { hour: 'numeric', minute: '2-digit' }) },
    close() { this.$emit('close') },
    toggleMembership() { this.$emit('toggle-membership') }
  }
}
</script>

<style>
.manager-dashboard .membership-loading { margin: 12px 0 0; color: var(--app-muted); font-size: 12px; }
.manager-dashboard .status-group { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.manager-dashboard .break-indicator { display: inline-flex; align-items: center; gap: 4px; padding: 3px 7px; border-radius: 999px; color: #875900; background: #fff2cf; font-size: 9px; font-weight: 650; white-space: nowrap; }
.manager-dashboard .break-indicator i { width: 6px; height: 6px; border-radius: 50%; background: #f3b536; }
.manager-dashboard .detail-backdrop { position: fixed; z-index: 10; inset: 0; display: grid; place-items: center; padding: 16px; background: rgb(18 28 43 / 35%); backdrop-filter: blur(2px); }
.manager-dashboard .detail-dialog { width: min(100%, 390px); padding: 18px; border: 1px solid #e8ebf0; border-radius: 12px; background: #fff; box-shadow: 0 18px 50px rgb(18 28 43 / 20%); }
.manager-dashboard .detail-dialog > header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.manager-dashboard .detail-dialog h2 { margin: 0; color: #202936; font-size: 18px; }
.manager-dashboard .detail-dialog header p:last-child { margin: 5px 0 0; color: #8994a3; font-size: 10px; }
.manager-dashboard .close-button { width: 27px; height: 27px; border: 1px solid #e5e8ed; border-radius: 6px; color: #788393; background: white; font-size: 20px; line-height: 1; cursor: pointer; }
.manager-dashboard .detail-metrics { display: grid; grid-template-columns: 1fr 1fr; gap: 9px; margin-top: 18px; }
.manager-dashboard .detail-metrics > div { display: grid; gap: 6px; padding: 12px; border: 1px solid #edf0f4; border-radius: 8px; background: #fafbfc; }
.manager-dashboard .detail-metrics small, .manager-dashboard .detail-clock small { color: #8994a3; font-size: 9px; }
.manager-dashboard .detail-metrics strong { color: #303a49; font-size: 15px; }
.manager-dashboard .detail-clock { display: flex; justify-content: space-between; gap: 10px; margin-top: 14px; }
.manager-dashboard .detail-dialog { border-color: var(--app-border); background: var(--app-surface); }
.manager-dashboard .detail-dialog h2 { color: var(--app-text); }
.manager-dashboard .detail-dialog header p:last-child, .manager-dashboard .detail-metrics small, .manager-dashboard .detail-clock small { color: var(--app-muted); font-size: 11px; }
.manager-dashboard .detail-metrics strong { color: var(--app-text); font-size: 16px; }
.manager-dashboard .detail-metrics > div { border-color: var(--app-border); background: var(--app-background); }
.manager-dashboard .detail-chart { margin-top: 14px; padding: 12px; border: 1px solid var(--app-border); border-radius: 9px; }
.manager-dashboard .detail-chart > div { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.manager-dashboard .detail-chart h3 { margin: 0; color: var(--app-text); font-size: 12px; }
.manager-dashboard .detail-chart > div > strong { color: var(--app-text); font-size: 13px; }
</style>
