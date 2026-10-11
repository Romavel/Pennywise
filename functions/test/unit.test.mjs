import assert from 'node:assert/strict';
import { test } from 'node:test';

import recentLogin from '../lib/recent_login.js';

const { isRecentLogin, MAX_AUTH_AGE_SECONDS } = recentLogin;
const now = Date.UTC(2026, 9, 11, 12, 0, 0);
const seconds = now / 1000;

test('accepts a sign-in within the last five minutes', () => {
  assert.equal(isRecentLogin(seconds, now), true);
  assert.equal(isRecentLogin(seconds - MAX_AUTH_AGE_SECONDS, now), true);
});

test('rejects older sign-ins', () => {
  assert.equal(isRecentLogin(seconds - MAX_AUTH_AGE_SECONDS - 1, now), false);
  assert.equal(isRecentLogin(seconds - 24 * 3600, now), false);
});

test('rejects a missing auth_time and times far in the future', () => {
  assert.equal(isRecentLogin(undefined, now), false);
  assert.equal(isRecentLogin(seconds + 3600, now), false);
});
