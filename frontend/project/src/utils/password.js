export async function hashPassword(password) {
  if (!globalThis.crypto?.subtle) {
    const error = new Error('Secure password hashing requires HTTPS or localhost.');
    error.name = 'PasswordHashingError';
    throw error;
  }

  const passwordBytes = new TextEncoder().encode(password);
  const digest = await globalThis.crypto.subtle.digest('SHA-256', passwordBytes);

  return Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, '0')).join('');
}