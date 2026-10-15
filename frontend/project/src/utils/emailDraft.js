export function createEmailDraftUrl(recipient, subject, body) {
  if (!recipient || !body.trim()) throw new Error('A recipient and message are required')

  const encodedRecipient = encodeURIComponent(recipient).replace(/%40/gi, '@')
  const parameters = [`body=${encodeURIComponent(body)}`]
  if (subject.trim()) parameters.unshift(`subject=${encodeURIComponent(subject.trim())}`)

  return `mailto:${encodedRecipient}?${parameters.join('&')}`
}

/** Open an email draft and return user-facing result messages for the form. */
export function openEmailDraft(recipient, subject, body, errorMessage = 'Could not open an email draft. Please check the recipient address and your email app.') {
  try {
    window.location.href = createEmailDraftUrl(recipient, subject, body)
    return {
      success: 'Your email draft should open in your email app. Send it there to deliver your message.',
      error: ''
    }
  } catch (error) {
    return { success: '', error: errorMessage }
  }
}
