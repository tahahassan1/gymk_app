# PRD — Small Gym Management App

Version: `v0.0.1` (MVP)

## 1. Overview

An `Android` app for owners of small gyms. The owner manages members and their monthly subscriptions, logs drop-in sessions for people without a subscription, and sees monthly income split between the two.

Each user is one independent gym. No data is shared between accounts.

## 2. Problem

Small gym owners track subscriptions on paper or in their heads. They don't know whose subscription is about to expire, they can't see the month's income accurately, and gym internet is unreliable.

## 3. Goals

- See every member's status (active, expiring soon, expired) at a glance.
- Record a new subscription or renewal in as few steps as possible.
- Record a drop-in session in seconds.
- Show clear monthly statistics.
- Work fully offline; changes sync automatically when the connection returns.

## 4. Out of Scope (MVP)

- Roles and permissions (`RBAC`) or staff accounts.
- Multiple subscription types. There is one type: one month.
- Archiving, soft deletion, and void/cancellation workflows. Records use ordinary permanent deletion.
- Expiry notifications.
- Report export and charts.
- A custom conflict-resolution strategy.
- `iOS` support.

## 5. User

A small gym owner who runs the gym alone from a single phone. One `Google` account = one gym.

## 6. Architecture Decisions

| Decision | Choice |
| --- | --- |
| App | `Flutter` on `Android` |
| Backend | `Firebase` (`Firestore` + `Auth`) |
| Offline | `Firestore` offline persistence only, no `hive_ce` |
| Auth | `Google OAuth` |
| Tenancy | All data lives under `users/{uid}` |
| Statistics | Computed on-device from cached data |
| Conflicts | `Firestore` default `last-write-wins`, accepted |

## 7. Data Model

```
users/{uid}
  settings: gymName, defaultSubscriptionPrice, defaultDropinPrice

users/{uid}/members/{id}
  name (required), phone?, createdAt

users/{uid}/subscriptions/{id}
  memberId, startDate, endDate, amount, paidAt

users/{uid}/dropins/{id}
  name?, amount, date
```

**Notes:**

- Dates are stored as dates only (no time) to avoid timezone issues.
- A member's status is derived from their remaining subscription records; it is not stored. Early renewal extends their current membership expiry without interrupting their active status.
- A drop-in is not linked to a member.
- Money is stored as integer whole Egyptian pounds (EGP): the app's smallest
  monetary unit is one pound, scale 1, with no fractional-pound payments. Zero
  default prices are allowed; subscription and drop-in payment records must be
  strictly positive. Negative and invalid amounts are always rejected.

## 8. Business Rules

### 8.1 Subscription duration

`endDate` = `startDate` + one month. If the target month has no such day, use its last day (for example, 31 January gives 28 February). A subscription is active while today is before `endDate`.

### 8.2 Subscription dates and early renewal

- Each member has an individual subscription cycle based on when they join. Subscriptions are not aligned to the first day of the calendar month.
- If the member has an active subscription: the renewal's `startDate` = the current membership `endDate`, and its `endDate` = that date + one calendar month, using rule 8.1. All remaining days are preserved.
- If the member's subscription is expired or none exists: `startDate` = today and `endDate` = `startDate` + one calendar month.
- The owner can edit `startDate` manually to today or an earlier date; `endDate`
  is recalculated using rule 8.1. Manual future start selection is prohibited.
  This restriction does not apply to automatic early renewal, which starts at
  the current continuous expiry even when that date is in the future.
- Early renewal is presented as an extension of the existing membership. No separate "upcoming subscription" status is needed for this renewal flow. The member remains active and the UI shows the extended expiry date.
- Example: a member joins on 26 October and initially expires on 26 November. If they renew on 10 November, their new expiry is 26 December. The renewal payment belongs to November's income.
- A month means a calendar month, not a fixed 30-day duration.

### 8.3 Member status

| Status | Condition |
| --- | --- |
| Active | `endDate` is more than 3 days away |
| Expiring soon | 3 days or fewer remain |
| Expired | `endDate` reached or passed |
| No subscription | No subscription recorded |

Adjacent or overlapping periods form continuous coverage. Only coverage
containing today is current; a disconnected future period does not extend the
current expiry. If edits/deletions leave records but no coverage for today,
including future-only history, classify the membership as expired and default
renewal to today. Preserve all remaining historical dates. Do not introduce an
upcoming status. Current expiry is absent when no period covers today; a past
expiry and remaining future date ranges are separate history facts.

### 8.4 Statistics

- Subscription income = sum of `amount` for subscriptions whose `paidAt` falls in the selected month.
- Drop-in income = sum of `amount` for drop-ins whose `date` falls in the selected month.
- A subscription counts as income in the month it was paid, not spread over its duration.
- Calendar-month reporting does not determine a member's subscription cycle.
- Editing or deleting a subscription or drop-in updates the affected statistics from the remaining data.

### 8.5 Editing and permanent deletion

- Members, subscriptions, and drop-ins can be edited or permanently deleted to correct mistakes.
- There is no archiving, soft deletion, `voidedAt`, or cancellation workflow.
- Deleting a subscription or drop-in removes it from income and count calculations. Deleting a subscription also recalculates the member's status and displayed expiry from their remaining subscription records.
- Deleting a member also deletes all subscriptions belonging to that member. Independent drop-ins are unaffected.
- Show a confirmation before deletion. The member-deletion confirmation must explicitly state that all of their subscriptions will also be deleted and historical statistics will change.
- Member deletion must explicitly remove their subscription documents as well as the member document; do not assume deleting one document cascades to related records.

## 9. Functional Requirements

### 9.1 Login

- A single `Sign in with Google` button.
- The first sign-in requires internet. After that the session works offline.
- First sign-in creates the user document and default settings.

### 9.2 Members (main tab)

- List showing name, status and expiry date.
- Search by name.
- Filters: All, Active, Expiring soon, Expired.
- Floating button to add a member.
- A "New subscription" button opens a member search; if the member doesn't exist, they can be added from the same screen.

### 9.3 Add / edit member

- Name is required; phone is optional.
- Member name and phone can be edited.

### 9.4 Member details

- Member info and current status.
- History of past subscriptions.
- A prominent `Renew` button.
- Edit and delete actions for subscription records (amount and start date are editable; end date is computed).
- A delete-member action with the confirmation and cascading behavior in rule 8.5.

### 9.5 New subscription / renewal (`bottom sheet`)

- Amount is prefilled from settings and editable.
- `startDate` follows rule 8.2 and is editable.
- `endDate` is computed automatically. For early renewal, show the current expiry and the new extended expiry before saving.
- `paidAt` is the moment of recording.

### 9.6 Drop-in sessions

- Quick form: name optional, amount prefilled from settings.
- Today's sessions listed below the form.
- Browse previous days.
- Edit a session's name, amount, or date, or permanently delete it after confirmation.

### 9.7 Statistics

- Month picker.
- Subscription income and count.
- Drop-in income and count.
- Grand total.

### 9.8 Settings

- Gym name.
- Default subscription price.
- Default drop-in price.
- Sign out.

## 10. Navigation

`Bottom navigation` with 4 tabs: Members, Drop-ins, Statistics, Settings.

## 11. Offline Requirements

- All screens work offline for reads and writes.
- Writes are cached locally and uploaded automatically when the connection returns.
- The cache size is set to `unlimited` so no data is evicted.
- Statistics are computed on-device because server-side aggregation needs a connection.
- The first sign-in is the only operation that requires internet.

## 12. Security

Core `Firestore` rule:

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

There are no roles. A user reads and writes only their own data. The owner may create, read, update, and delete their own records, including the subscription records removed when deleting a member.

## 13. Non-Functional Requirements

- The member list and search must stay instant for a gym with hundreds of members.
- Core actions (add member, renew, log drop-in) never wait on the network.
- Arabic `RTL` interface.

## 14. Decisions Made

- Ordinary permanent deletion and editing are supported for members, subscriptions, and drop-ins. No archiving or void/cancellation workflow.
- Deleting a member also deletes their subscriptions and changes the relevant historical statistics.
- Subscription cycles follow each member's own start date. Early renewal preserves remaining days and extends the current expiry by one calendar month.
- Monthly statistics group payments by payment month; they do not align subscriptions to month boundaries.
- Confirmed on 27 October 2026: whole EGP (scale 1); zero defaults allowed,
  positive payment records required; manual future starts prohibited while
  automatic early renewal remains allowed. Uncovered gaps/future-only history
  are expired, renewal defaults to today, and remaining dates are preserved.
- `last-write-wins` is accepted for the same account on two devices.

## 15. Open Questions

1. **Near-expiry threshold:** fixed at 3 days for the MVP, configurable later?
2. **Fixing mistakes — resolved:** members, subscriptions, and drop-ins support editing and ordinary permanent deletion, as specified in rule 8.5.
3. **Currency — resolved:** whole EGP, scale 1, under the validation above.
4. **Sync indicator:** should the UI show that some changes haven't uploaded yet?
