// Runs against the Firebase Emulator Suite (see `npm run test:integration`),
// which sets FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST.
import assert from 'node:assert/strict';
import { before, test } from 'node:test';

import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = 'demo-pennywise';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsUrl = `http://127.0.0.1:5001/${projectId}/europe-central2/deleteAccount`;

initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();

async function createUserWithData(email) {
  const user = await auth.createUser({ email, password: 'password123' });
  const root = db.doc(`users/${user.uid}`);
  await root.set({ displayName: 'Test', currency: 'PLN', themeMode: 'system' });
  await root.collection('transactions').doc('t1').set({ amountMinor: 4599 });
  await root.collection('budgets').doc('2026-10_food').set({ limitMinor: 120000 });
  await root.collection('categories').doc('custom_abc12345').set({ name: 'Coffee' });
  return user;
}

async function signIn(email) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'password123', returnSecureToken: true }),
    },
  );
  return (await response.json()).idToken;
}

function callDeleteAccount(idToken) {
  return fetch(functionsUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
    },
    body: JSON.stringify({ data: {} }),
  });
}

async function countDocs(uid) {
  const root = db.doc(`users/${uid}`);
  const subcollections = await Promise.all(
    ['transactions', 'budgets', 'categories'].map((c) => root.collection(c).get()),
  );
  const profile = await root.get();
  return subcollections.reduce((sum, s) => sum + s.size, profile.exists ? 1 : 0);
}

let alice;
let bob;

before(async () => {
  alice = await createUserWithData('alice@example.com');
  bob = await createUserWithData('bob@example.com');
});

test('rejects calls without a signed-in user', async () => {
  const response = await callDeleteAccount(null);
  assert.equal(response.status, 401);
  assert.equal(await countDocs(alice.uid), 4);
});

test("deletes the caller's data and account, and nobody else's", async () => {
  const response = await callDeleteAccount(await signIn('alice@example.com'));
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).result, { deleted: true });

  assert.equal(await countDocs(alice.uid), 0);
  await assert.rejects(auth.getUser(alice.uid), { code: 'auth/user-not-found' });

  assert.equal(await countDocs(bob.uid), 4);
  assert.ok(await auth.getUser(bob.uid));
});
