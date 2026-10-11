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
    projectId: 'demo-pennywise',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const guest = () => env.unauthenticatedContext().firestore();

const txPath = (uid, id = 't1') => `users/${uid}/transactions/${id}`;

const validTransaction = (overrides = {}) => ({
  type: 'expense',
  amountMinor: 4599,
  currency: 'PLN',
  categoryId: 'food',
  note: 'Groceries',
  occurredAt: Timestamp.fromDate(new Date('2026-10-11T12:00:00Z')),
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

/** Writes a valid transaction for alice, bypassing the rules. */
const seedAliceTransaction = () =>
  env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), txPath('alice')), {
      ...validTransaction(),
      createdAt: Timestamp.fromDate(new Date('2026-10-11T12:00:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-10-11T12:00:00Z')),
    }),
  );

describe('ownership', () => {
  test('a user can create and read their own transaction', async () => {
    await assertSucceeds(setDoc(doc(alice(), txPath('alice')), validTransaction()));
    await assertSucceeds(getDoc(doc(alice(), txPath('alice'))));
  });

  test("a user cannot read another user's transaction", async () => {
    await seedAliceTransaction();
    await assertFails(getDoc(doc(bob(), txPath('alice'))));
  });

  test("a user cannot write another user's transactions", async () => {
    await seedAliceTransaction();
    await assertFails(setDoc(doc(bob(), txPath('alice', 't2')), validTransaction()));
    await assertFails(updateDoc(doc(bob(), txPath('alice')), { amountMinor: 1, updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(bob(), txPath('alice'))));
  });

  test('signed-out users cannot do anything', async () => {
    await seedAliceTransaction();
    await assertFails(getDoc(doc(guest(), txPath('alice'))));
    await assertFails(setDoc(doc(guest(), txPath('alice', 't2')), validTransaction()));
  });

  test('other collections are denied', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice'), { name: 'Alice' }));
    await assertFails(setDoc(doc(alice(), 'anything/else'), { a: 1 }));
  });
});

describe('validation on create', () => {
  const rejects = (name, overrides) =>
    test(`rejects ${name}`, () =>
      assertFails(setDoc(doc(alice(), txPath('alice')), validTransaction(overrides))));

  rejects('a zero amount', { amountMinor: 0 });
  rejects('a negative amount', { amountMinor: -100 });
  rejects('a fractional amount', { amountMinor: 45.99 });
  rejects('an amount as text', { amountMinor: '4599' });
  rejects('an amount above the limit', { amountMinor: 100000000001 });
  rejects('an unknown type', { type: 'transfer' });
  rejects('an invalid currency', { currency: 'pln' });
  rejects('an empty category', { categoryId: '' });
  rejects('a note over 200 characters', { note: 'x'.repeat(201) });
  rejects('a date as text', { occurredAt: '2026-10-11' });
  rejects('a client-chosen createdAt', { createdAt: Timestamp.fromDate(new Date('2020-01-01')) });
  rejects('extra fields', { isAdmin: true });

  test('rejects missing fields', async () => {
    const { note, ...withoutNote } = validTransaction();
    await assertFails(setDoc(doc(alice(), txPath('alice')), withoutNote));
  });

  test('accepts income and a note of exactly 200 characters', () =>
    assertSucceeds(
      setDoc(
        doc(alice(), txPath('alice')),
        validTransaction({ type: 'income', categoryId: 'salary', note: 'x'.repeat(200) }),
      ),
    ));
});

describe('updates and deletes', () => {
  beforeEach(seedAliceTransaction);

  test('the owner can update editable fields', () =>
    assertSucceeds(
      updateDoc(doc(alice(), txPath('alice')), {
        amountMinor: 8640,
        note: 'Weekly groceries',
        updatedAt: serverTimestamp(),
      }),
    ));

  test('updates must refresh updatedAt', () =>
    assertFails(updateDoc(doc(alice(), txPath('alice')), { amountMinor: 8640 })));

  test('createdAt and currency cannot change', async () => {
    await assertFails(
      updateDoc(doc(alice(), txPath('alice')), {
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(alice(), txPath('alice')), { currency: 'EUR', updatedAt: serverTimestamp() }),
    );
  });

  test('updates are validated too', () =>
    assertFails(
      updateDoc(doc(alice(), txPath('alice')), { amountMinor: 0, updatedAt: serverTimestamp() }),
    ));

  test('the owner can delete', () => assertSucceeds(deleteDoc(doc(alice(), txPath('alice')))));
});
