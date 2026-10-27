import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, Timestamp, writeBatch, setLogLevel } from 'firebase/firestore';

setLogLevel('silent'); // Expected denial cases are asserted below.

let environment;
const member = { name: 'أحمد', phone: '01012345678', createdAt: Timestamp.fromDate(new Date('2026-10-27T10:00:00Z')) };
const subscription = { memberId: 'one', startDate: '2026-10-27', endDate: '2026-11-27', amount: 125, paidAt: '2026-10-27' };
const settings = { settings: { gymName: 'جيمك', defaultSubscriptionPrice: 0, defaultDropinPrice: 0 } };
const dropin = { amount: 50, date: '2026-10-27' };

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Emulator-only tests: FIRESTORE_EMULATOR_HOST is required');
  environment = await initializeTestEnvironment({ projectId: 'demo-gymk', firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') } });
});
beforeEach(() => environment.clearFirestore());
after(async () => environment?.cleanup());

function database(uid = 'owner') { return environment.authenticatedContext(uid).firestore(); }
async function seed() {
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/owner'), settings);
    await setDoc(doc(db, 'users/owner/members/one'), member);
    await setDoc(doc(db, 'users/owner/subscriptions/payment'), subscription);
    await setDoc(doc(db, 'users/owner/dropins/session'), dropin);
  });
}

test('owner can create, read, correct and permanently delete each record type', async () => {
  const db = database();
  await assertSucceeds(setDoc(doc(db, 'users/owner'), settings));
  await assertSucceeds(setDoc(doc(db, 'users/owner/members/one'), member));
  await assertSucceeds(setDoc(doc(db, 'users/owner/subscriptions/payment'), subscription));
  await assertSucceeds(setDoc(doc(db, 'users/owner/dropins/session'), dropin));
  for (const path of ['users/owner', 'users/owner/members/one', 'users/owner/subscriptions/payment', 'users/owner/dropins/session']) {
    await assertSucceeds(getDoc(doc(db, path)));
  }
  await assertSucceeds(updateDoc(doc(db, 'users/owner/members/one'), { name: 'محمود' }));
  await assertSucceeds(updateDoc(doc(db, 'users/owner/subscriptions/payment'), { amount: 150, startDate: '2026-10-01', endDate: '2026-11-01' }));
  await assertSucceeds(updateDoc(doc(db, 'users/owner/dropins/session'), { date: '2026-11-01', name: 'محمد' }));
  await assertSucceeds(setDoc(doc(db, 'users/owner'), { settings: { ...settings.settings, defaultSubscriptionPrice: 250 } }));
  for (const path of ['users/owner/subscriptions/payment', 'users/owner/members/one', 'users/owner/dropins/session', 'users/owner']) {
    await assertSucceeds(deleteDoc(doc(db, path)));
  }
});

test('unauthenticated and other-tenant reads, queries and all write operations fail', async () => {
  await seed();
  for (const db of [environment.unauthenticatedContext().firestore(), database('other')]) {
    for (const [path, value] of [['users/owner', settings], ['users/owner/members/one', member], ['users/owner/subscriptions/payment', subscription], ['users/owner/dropins/session', dropin]]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(setDoc(doc(db, path), value));
      await assertFails(deleteDoc(doc(db, path)));
    }
    for (const name of ['members', 'subscriptions', 'dropins']) await assertFails(getDocs(collection(db, `users/owner/${name}`)));
  }
});

test('zero defaults are allowed; zero, negative, fractional and malformed payments fail', async () => {
  await seed();
  const db = database();
  await assertSucceeds(setDoc(doc(db, 'users/owner'), settings));
  for (const amount of [0, -1, 1.5, '125', NaN, Infinity]) {
    await assertFails(setDoc(doc(db, 'users/owner/subscriptions/bad'), { ...subscription, amount }));
    await assertFails(setDoc(doc(db, 'users/owner/dropins/bad'), { ...dropin, amount }));
  }
  await assertFails(setDoc(doc(db, 'users/owner'), { settings: { ...settings.settings, defaultDropinPrice: -1 } }));
});

test('dates enforce real calendar dates, one month, clamping and automatic future renewal', async () => {
  await seed();
  const db = database();
  for (const [startDate, endDate] of [['2026-01-31', '2026-02-28'], ['2024-01-31', '2024-02-29'], ['2026-12-31', '2027-01-31'], ['2027-01-27', '2027-02-27']]) {
    await assertSucceeds(setDoc(doc(db, 'users/owner/subscriptions/valid'), { ...subscription, startDate, endDate }));
  }
  for (const date of ['2026-02-29', '2026-04-31', '2026-13-01', '0000-01-01', '2026-1-01', '2026-10-27T00:00:00Z']) {
    await assertFails(setDoc(doc(db, 'users/owner/dropins/bad'), { ...dropin, date }));
    await assertFails(setDoc(doc(db, 'users/owner/subscriptions/bad'), { ...subscription, paidAt: date }));
  }
  await assertFails(setDoc(doc(db, 'users/owner/subscriptions/bad'), { ...subscription, endDate: '2026-11-26' }));
});

test('member/payment references and createdAt stay immutable on correction', async () => {
  await seed();
  const db = database();
  await assertFails(updateDoc(doc(db, 'users/owner/subscriptions/payment'), { memberId: 'other' }));
  await assertFails(updateDoc(doc(db, 'users/owner/subscriptions/payment'), { paidAt: '2026-11-01' }));
  await assertFails(updateDoc(doc(db, 'users/owner/members/one'), { createdAt: Timestamp.now() }));
  await assertFails(setDoc(doc(db, 'users/owner/subscriptions/orphan'), { ...subscription, memberId: 'missing' }));
  await assertFails(setDoc(doc(db, 'users/owner/members/blank'), { ...member, name: '  ' }));
  await assertFails(setDoc(doc(db, 'users/owner/members/number'), { ...member, phone: 101234 }));
  await assertFails(setDoc(doc(db, 'users/owner/dropins/extra'), { ...dropin, memberId: 'one' }));
});

test('atomic member/history deletion leaves independent drop-ins unchanged', async () => {
  await seed();
  const db = database();
  const batch = writeBatch(db);
  batch.delete(doc(db, 'users/owner/members/one'));
  batch.delete(doc(db, 'users/owner/subscriptions/payment'));
  await assertSucceeds(batch.commit());
  const remaining = await getDoc(doc(db, 'users/owner/dropins/session'));
  if (!remaining.exists()) throw new Error('Independent drop-in was removed');
});
