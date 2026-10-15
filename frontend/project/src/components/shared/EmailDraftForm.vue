<template>
  <form class="message-compose" @submit.prevent="$emit('send')">
    <h3>Send an email</h3>
    <p>To {{ recipient }}. Your email app chooses the sender account.</p>
    <label :for="`${idPrefix}-subject`">Subject <span>Optional</span></label>
    <input :id="`${idPrefix}-subject`" :value="subject" @input="$emit('update:subject', $event.target.value)" type="text" maxlength="160" placeholder="A short subject" />
    <label :for="`${idPrefix}-body`">Message</label>
    <textarea :id="`${idPrefix}-body`" :value="body" @input="$emit('update:body', $event.target.value)" required maxlength="5000" rows="4" placeholder="Write your message…"></textarea>
    <p v-if="error" class="message-error" role="alert">{{ error }}</p>
    <p v-if="success" class="message-success" role="status">{{ success }}</p>
    <button class="team-action message-submit" type="submit" :disabled="!body.trim()">Open email draft</button>
  </form>
</template>

<script>
export default {
  name: 'EmailDraftForm',
  props: {
    recipient: { type: String, required: true },
    idPrefix: { type: String, required: true },
    subject: { type: String, required: true },
    body: { type: String, required: true },
    error: { type: String, default: '' },
    success: { type: String, default: '' }
  },
  emits: ['send', 'update:subject', 'update:body']
}
</script>

<style>
.workspace-shell .message-compose { display: grid; gap: 8px; margin-top: 17px; padding-top: 16px; border-top: 1px solid var(--app-border); }
.workspace-shell .message-compose h3 { margin: 0; color: var(--app-text); font-size: 14px; }
.workspace-shell .message-compose p { margin: 0; color: var(--app-muted); font-size: 11px; line-height: 1.5; }
.workspace-shell .message-compose label { margin-top: 3px; color: #414c5d; font-size: 11px; font-weight: 650; }
.workspace-shell .message-compose label span { color: var(--app-muted); font-weight: 400; }
.workspace-shell .message-compose input, .workspace-shell .message-compose textarea { width: 100%; min-width: 0; padding: 9px 10px; border: 1px solid var(--app-border); border-radius: 7px; color: var(--app-text); background: #fff; font: inherit; font-size: 12px; }
.workspace-shell .message-compose textarea { min-height: 96px; resize: vertical; }
.workspace-shell .message-compose input:focus, .workspace-shell .message-compose textarea:focus { border-color: var(--app-accent); outline: 3px solid rgb(22 132 248 / 12%); }
.workspace-shell .message-compose .message-error, .workspace-shell .message-compose .message-success { font-size: 11px; }
.workspace-shell .message-compose .message-error { color: #a33636; }
.workspace-shell .message-compose .message-success { color: #16734f; }
.workspace-shell .message-submit { justify-self: start; margin-top: 3px; }
</style>
