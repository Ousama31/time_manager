<template>


          <div class="page-heading dashboard-heading"><div><p class="eyebrow dashboard-eyebrow">TEAM COMMUNICATION</p><h1 class="dashboard-title">Feedback</h1><p class="date-line dashboard-description">Send a private message to your assigned manager.</p></div></div>
          <article class="card feedback-panel dashboard-surface">
            <div class="feedback-recipient"><span class="feedback-recipient-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 6.5h16v11H4z"/><path d="m4.5 7 7.5 6 7.5-6"/></svg></span><span><strong>To your manager</strong><small>Your manager is selected from your account assignment.</small></span></div>
            <p v-if="!profile.manager_id" class="feedback-unassigned" role="status">No manager is assigned to your account yet. Contact an administrator to join a team.</p>
            <form v-else class="feedback-form" @submit.prevent="$emit('send-feedback')">
              <label for="feedback-subject">Subject <span>Optional</span></label>
              <input id="feedback-subject" :value="feedbackSubject" @input="$emit('update:feedbackSubject', $event.target.value.trim())" type="text" maxlength="160" placeholder="A short subject" />
              <label for="feedback-message">Message</label>
              <textarea id="feedback-message" :value="feedbackBody" @input="$emit('update:feedbackBody', $event.target.value)" required maxlength="5000" rows="7" placeholder="Write your message…"></textarea>
              <p class="sender-note">Your email app chooses the sender account. Review it and send the draft there.</p>
              <p v-if="feedbackError" class="feedback-error" role="alert">{{ feedbackError }}</p>
              <p v-if="feedbackSuccess" class="feedback-success" role="status">{{ feedbackSuccess }}</p>
              <button class="feedback-submit" type="submit" :disabled="feedbackBusy || !feedbackBody.trim()"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m21 3-7.5 18-3.7-7.8L2 9.5 21 3Z"/><path d="M9.8 13.2 21 3"/></svg>{{ feedbackBusy ? 'Opening…' : 'Open email draft' }}</button>
            </form>
          </article>

</template>

<script>
export default {
  name: 'EmployeeFeedbackSection',

  props: {
    profile: { type: Object, required: true },
    feedbackSubject: { type: String, required: true },
    feedbackBody: { type: String, required: true },
    feedbackBusy: { type: Boolean, required: true },
    feedbackError: { type: String, default: '' },
    feedbackSuccess: { type: String, default: '' }
  },
}
</script>

<style>
.employee-dashboard .feedback-panel { max-width: 760px; padding: 24px; }
.employee-dashboard .feedback-recipient { display: flex; align-items: center; gap: 12px; padding-bottom: 20px; border-bottom: 1px solid var(--app-border); }
.employee-dashboard .feedback-recipient-icon { display: grid; width: 40px; height: 40px; flex: 0 0 40px; place-items: center; border-radius: 10px; color: #1674bf; background: #eaf5f6; }
.employee-dashboard .feedback-recipient-icon svg { width: 20px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.employee-dashboard .feedback-recipient > span:last-child { display: grid; gap: 4px; }
.employee-dashboard .feedback-recipient strong { font-size: 14px; }
.employee-dashboard .feedback-recipient small, .employee-dashboard .sender-note { color: var(--app-muted); font-size: 12px; }
.employee-dashboard .feedback-form { display: grid; gap: 9px; margin-top: 20px; }
.employee-dashboard .feedback-form label { margin-top: 5px; color: #414c5d; font-size: 13px; font-weight: 650; }
.employee-dashboard .feedback-form label span { margin-left: 5px; color: var(--app-muted); font-size: 11px; font-weight: 400; }
.employee-dashboard .feedback-form input, .employee-dashboard .feedback-form textarea { width: 100%; min-width: 0; padding: 11px 12px; border: 1px solid var(--app-border); border-radius: 8px; color: var(--app-text); background: #fff; font: inherit; font-size: 14px; }
.employee-dashboard .feedback-form textarea { min-height: 156px; resize: vertical; }
.employee-dashboard .feedback-form input:focus, .employee-dashboard .feedback-form textarea:focus { border-color: var(--app-accent); outline: 3px solid rgb(22 132 248 / 12%); }
.employee-dashboard .sender-note { margin: 2px 0 0; line-height: 1.5; }
.employee-dashboard .feedback-error, .employee-dashboard .feedback-success { margin: 0; font-size: 13px; }
.employee-dashboard .feedback-error { color: #a83232; }.employee-dashboard .feedback-success { color: #16734f; }
.employee-dashboard .feedback-unassigned { margin: 18px 0 0; color: #80591a; font-size: 13px; line-height: 1.5; }
.employee-dashboard .feedback-submit { display: inline-flex; min-height: 43px; align-items: center; justify-content: center; gap: 8px; justify-self: start; margin-top: 4px; padding: 0 16px; border: 0; border-radius: 8px; color: #fff; background: #1679a3; font: inherit; font-size: 13px; font-weight: 650; cursor: pointer; }
.employee-dashboard .feedback-submit:disabled { opacity: .55; cursor: not-allowed; }
.employee-dashboard .feedback-submit svg { width: 17px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
  .employee-dashboard .feedback-panel { padding: 19px; }
</style>
