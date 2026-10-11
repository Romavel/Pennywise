/** How recently the user must have signed in to delete their account. */
export const MAX_AUTH_AGE_SECONDS = 5 * 60;

/**
 * Whether a token's `auth_time` (seconds since the epoch) is recent enough
 * for a sensitive operation. A stolen long-lived session therefore cannot
 * delete the account without the password.
 */
export function isRecentLogin(
  authTimeSeconds: number | undefined,
  nowMs: number = Date.now(),
): boolean {
  if (typeof authTimeSeconds !== 'number') return false;
  const ageSeconds = nowMs / 1000 - authTimeSeconds;
  return ageSeconds >= -60 && ageSeconds <= MAX_AUTH_AGE_SECONDS;
}
