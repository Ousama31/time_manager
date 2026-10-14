export function createEmailDraftUrl(recipient, subject, body) {
  if (!recipient || !body.trim()) throw new Error('A recipient and message are required')

  const encodedRecipient = encodeURIComponent(recipient).replace(/%40/gi, '@')
  const parameters = [`body=${encodeURIComponent(body)}`]
  if (subject.trim()) parameters.unshift(`subject=${encodeURIComponent(subject.trim())}`)

  return `mailto:${encodedRecipient}?${parameters.join('&')}`
}