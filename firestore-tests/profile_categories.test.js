import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-pennywise-profile',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();

const profile = (overrides = {}) => ({
  displayName: 'Alice',
  currency: 'PLN',
  themeMode: 'dark',
  updatedAt: serverTimestamp(),
  ...overrides,
});

const custom = (overrides = {}) => ({
  name: 'Coffee',
  type: 'expense',
  icon: 'coffee',
  tone: 'brown',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

describe('profile', () => {
  test('the owner can write and read their profile', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice'), profile()));
    await assertSucceeds(getDoc(doc(alice(), 'users/alice')));
  });

  test('other users cannot read or write it', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice'), profile()));
    await assertFails(getDoc(doc(bob(), 'users/alice')));
    await assertFails(setDoc(doc(bob(), 'users/alice'), profile()));
  });

  test('rejects invalid values', async () => {
    for (const bad of [
      { displayName: '' },
      { displayName: 'x'.repeat(41) },
      { currency: 'zloty' },
      { themeMode: 'sepia' },
      { isAdmin: true },
    ]) {
      await assertFails(setDoc(doc(alice(), 'users/alice'), profile(bad)));
    }
  });

  test('the app cannot delete the profile', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice'), profile()));
    await assertFails(deleteDoc(doc(alice(), 'users/alice')));
  });
});

describe('categories', () => {
  test('built-in categories can be renamed and reset', async () => {
    const ref = doc(alice(), 'users/alice/categories/food');
    await assertSucceeds(setDoc(ref, { name: 'Groceries', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref));
  });

  test('a rename can only carry a name', () =>
    assertFails(
      setDoc(doc(alice(), 'users/alice/categories/food'), {
        name: 'Groceries',
        icon: 'cart',
        updatedAt: serverTimestamp(),
      }),
    ));

  test('custom categories need a custom id and a valid shape', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice/categories/custom_abc12345'), custom()));
    await assertFails(setDoc(doc(alice(), 'users/alice/categories/coffee'), custom()));
    await assertFails(setDoc(doc(alice(), 'users/alice/categories/total'), custom()));
    await assertFails(setDoc(doc(alice(), 'users/alice/categories/custom_abc12346'), custom({ type: 'transfer' })));
    await assertFails(setDoc(doc(alice(), 'users/alice/categories/custom_abc12347'), custom({ name: '' })));
  });

  test('a custom category can be restyled but not change its type', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/alice/categories/custom_abc12345'), {
        ...custom(),
        createdAt: Timestamp.fromDate(new Date('2026-10-01')),
        updatedAt: Timestamp.fromDate(new Date('2026-10-01')),
      }),
    );
    const ref = doc(alice(), 'users/alice/categories/custom_abc12345');
    await assertSucceeds(updateDoc(ref, { name: 'Cafés', tone: 'orange', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { type: 'income', updatedAt: serverTimestamp() }));
  });

  test('other users cannot touch them', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice/categories/custom_abc12345'), custom()));
    await assertFails(getDoc(doc(bob(), 'users/alice/categories/custom_abc12345')));
    await assertFails(deleteDoc(doc(bob(), 'users/alice/categories/custom_abc12345')));
  });
});
