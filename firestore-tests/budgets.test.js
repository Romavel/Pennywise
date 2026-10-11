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
  writeBatch,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-pennywise-budgets',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();

const budgetPath = (uid, id = '2026-10_food') => `users/${uid}/budgets/${id}`;

const validBudget = (overrides = {}) => ({
  categoryId: 'food',
  monthKey: '2026-10',
  limitMinor: 120000,
  currency: 'PLN',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const seedAliceBudget = () =>
  env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), budgetPath('alice')), {
      ...validBudget(),
      createdAt: Timestamp.fromDate(new Date('2026-10-01')),
      updatedAt: Timestamp.fromDate(new Date('2026-10-01')),
    }),
  );

describe('budgets: ownership', () => {
  test('the owner can create and read a budget', async () => {
    await assertSucceeds(setDoc(doc(alice(), budgetPath('alice')), validBudget()));
    await assertSucceeds(getDoc(doc(alice(), budgetPath('alice'))));
  });

  test('other users cannot read or write it', async () => {
    await seedAliceBudget();
    await assertFails(getDoc(doc(bob(), budgetPath('alice'))));
    await assertFails(
      updateDoc(doc(bob(), budgetPath('alice')), { limitMinor: 1, updatedAt: serverTimestamp() }),
    );
    await assertFails(deleteDoc(doc(bob(), budgetPath('alice'))));
    await assertFails(setDoc(doc(bob(), budgetPath('alice', '2026-11_food')), validBudget({ monthKey: '2026-11' })));
  });
});

describe('budgets: validation', () => {
  const rejects = (name, overrides, id) =>
    test(`rejects ${name}`, () =>
      assertFails(setDoc(doc(alice(), budgetPath('alice', id)), validBudget(overrides))));

  rejects('an id that does not match month and category', {}, '2026-10_transport');
  rejects('a zero limit', { limitMinor: 0 });
  rejects('a fractional limit', { limitMinor: 10.5 });
  rejects('an invalid month key', { monthKey: '2026-13' }, '2026-13_food');
  rejects('an invalid category id', { categoryId: 'Food!' }, '2026-10_Food!');
  rejects('a lowercase currency', { currency: 'pln' });
  rejects('extra fields', { spentMinor: 5 });

  test('a batch copying several budgets succeeds', async () => {
    const db = alice();
    const batch = writeBatch(db);
    batch.set(doc(db, budgetPath('alice', '2026-11_food')), validBudget({ monthKey: '2026-11' }));
    batch.set(
      doc(db, budgetPath('alice', '2026-11_housing')),
      validBudget({ monthKey: '2026-11', categoryId: 'housing', limitMinor: 170000 }),
    );
    await assertSucceeds(batch.commit());
  });
});

describe('budgets: updates', () => {
  beforeEach(seedAliceBudget);

  test('the limit can change', () =>
    assertSucceeds(
      updateDoc(doc(alice(), budgetPath('alice')), { limitMinor: 150000, updatedAt: serverTimestamp() }),
    ));

  test('category, month and currency cannot change', async () => {
    for (const change of [{ categoryId: 'transport' }, { monthKey: '2026-11' }, { currency: 'EUR' }]) {
      await assertFails(
        updateDoc(doc(alice(), budgetPath('alice')), { ...change, updatedAt: serverTimestamp() }),
      );
    }
  });

  test('re-creating an existing budget is rejected', () =>
    assertFails(setDoc(doc(alice(), budgetPath('alice')), validBudget({ limitMinor: 1 }))));

  test('the owner can delete it', () => assertSucceeds(deleteDoc(doc(alice(), budgetPath('alice')))));
});
