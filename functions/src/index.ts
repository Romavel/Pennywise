import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { isRecentLogin } from './recent_login';

initializeApp();

/** Must match `functionsRegion` in the Flutter app. */
const REGION = 'europe-central2';

/**
 * Permanently deletes the calling user's data and account.
 *
 * Data goes first: if deleting the sign-in account then fails, the user can
 * simply retry, and no data is ever left behind without an owner.
 */
export const deleteAccount = onCall({ region: REGION }, async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in to delete your account.');
  }
  if (!isRecentLogin(auth.token.auth_time)) {
    throw new HttpsError(
      'failed-precondition',
      'Sign in again before deleting your account.',
    );
  }

  const uid = auth.uid;
  const firestore = getFirestore();
  // Deletes users/{uid} and every subcollection: transactions, budgets,
  // categories.
  await firestore.recursiveDelete(firestore.doc(`users/${uid}`));
  await getAuth().deleteUser(uid);

  // Only the id is logged, never any of the deleted data.
  logger.info('Account deleted', { uid });
  return { deleted: true };
});
