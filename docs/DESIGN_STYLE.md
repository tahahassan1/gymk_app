# Gymak — Design Style & UI Specification

Version: 0.0.1 · Platform: Android / Flutter · UI language: Egyptian Arabic · Direction: RTL

## 1. Purpose and authority

This document defines the visual system and interaction design for **جيمك** (Gymak), a small gym management app for an owner operating mainly from one Android phone. Read it alongside the current `PRD.md` and `ARCHITECTURE.md` before implementing screens.

The PRD owns product scope and business rules. This document owns presentation. Do not add product features because they appear convenient for a design. Implementation choices here are design defaults, not new approved business requirements.

Confirmed product decisions: ordinary editing and permanent deletion, no archiving, no soft deletion or cancellation workflow, individual membership cycles, and early renewal extending the existing expiry by one calendar month. Monthly reporting groups money by payment month.

The PRD confirms whole EGP amounts (no fractional units), zero default prices and
positive payment records. Currency display uses zero decimal places and the
selected Western digit convention. The threshold is confirmed fixed at three days
for MVP, with no configuration control. Compact persistent pending/error feedback
in the shared shell is approved, without global connectivity/sync claims.

## 2. Design direction

**A clean management interface with restrained neo-brutalist accents.**

The logo is expressive. The working interface is calm, readable, and efficient. Use bold typography, yellow accents, dark borders, and a few hard shadows to establish the brand. Use neutral surfaces, clear hierarchy, and simple rows to support repeated daily work.

The intended feeling is confident, approachable, practical, and familiar. The audience is Egyptian neighborhood gym owners. Accessibility and clear language matter more than decorative novelty. Do not interpret a local audience as a reason for low-quality visuals or exaggerated slang.

### Visual emphasis hierarchy

1. The action the owner needs now: renew, record a session, or save.
2. A member's status and expiry; a payment's amount and date.
3. Names, supporting details, and navigation.
4. Brand decoration.

Use stronger neo-brutalist styling on the main action, selected navigation, and one important summary. Keep repeated member and history rows free of heavy shadows. Do not make every surface compete for attention.

## 3. Brand and logo

- Display name: **جيمك**, always correctly joined in Arabic.
- Use the supplied yellow-and-black Arabic wordmark with dumbbell. Never redraw or replace it with generated text during implementation.
- Keep its proportions and transparency; use `BoxFit.contain`, never stretch or crop.
- Use it prominently on sign-in and modestly in branding areas. A member list does not need a giant logo above its useful content.
- Keep surrounding clear space of at least approximately one dot-height from the wordmark.
- The black outline must remain visible against a light surface. Do not put the logo directly on a black background without an approved alternative asset.
- Do not use the full horizontal wordmark as a tiny app icon. A separate compact icon is a future asset, not permission to invent another logo.

## 4. Color tokens

Use semantic theme tokens. No unexplained hex colors inside feature widgets.

| Token | Value | Use |
| --- | --- | --- |
| `brandPrimary` | `#FFD600` | Primary actions, selected controls, small brand accents |
| `onBrandPrimary` | `#181818` | Text and icons on yellow |
| `canvas` | `#FAF9F6` | Main screen background |
| `surface` | `#FFFFFF` | Forms, sheets, summary surfaces |
| `surfaceMuted` | `#F1F0EB` | Quiet secondary areas |
| `ink` | `#181818` | Main text and strong outlines |
| `textSecondary` | `#55554D` | Supporting copy |
| `divider` | `#DEDDD6` | List separators and subtle boundaries |
| `success` / `successSurface` | `#166534` / `#DCFCE7` | Active status |
| `warning` / `warningSurface` | `#9A3412` / `#FFEDD5` | Expiring soon |
| `danger` / `dangerSurface` | `#B91C1C` / `#FEE2E2` | Expired status, destructive actions, errors |
| `neutral` / `neutralSurface` | `#52525B` / `#F4F4F5` | No subscription and inactive metadata |

Yellow is an action/selection color, not the universal membership-status color. Pair status colors with visible labels. Verify actual contrast in rendered components, including disabled controls and text over pale backgrounds. Never use white body text on yellow.

Light mode only for this MVP design. Do not ship an automatic dark palette without checking the logo, status colors, contrast, and shadows.

## 5. Typography

Use **Cairo**, bundled locally with the app so first offline rendering never depends on a font download. Include only the weights used: 400, 600, and 700. Keep Arabic body text upright; do not copy the logo's stylized letterforms into UI labels.

| Role | Size / line height | Weight |
| --- | --- | --- |
| Large monetary total | 30 / 40 | 700 |
| Screen title | 24 / 34 | 700 |
| Section heading | 18 / 28 | 700 |
| Member name / primary row text | 16 / 26 | 600 |
| Body and field value | 16 / 26 | 400 |
| Button label | 16 / 24 | 700 |
| Supporting label | 14 / 22 | 400 |
| Small metadata | 12 / 20 | 400 |

Sizes are logical pixels at default text scale. Express line height as the appropriate Flutter multiplier. Support system text scaling; do not disable it to preserve a mockup. Avoid fixed row heights that clip Arabic ascenders, dots, or long names. Prefer wrapping over tiny text.

Numbers may use tabular figures if the bundled font supports them. Use one consistent digit style, with Western digits as the initial design default for amounts, dates, and phone numbers. Accept both Arabic-Indic and Western input digits. Explicitly isolate phone numbers and mixed numeric strings with LTR direction where needed.

## 6. Spacing, geometry, borders, and shadows

| Token group | Values |
| --- | --- |
| Spacing scale | 4, 8, 12, 16, 24, 32 |
| Screen horizontal inset | 16; 24 where width comfortably permits |
| Main control height | Minimum 52 |
| Touch target | Minimum 48 × 48, including icon buttons |
| Form/card radius | 12 |
| Bottom sheet top radius | 20 |
| Standard strong outline | 1.5–2, dark ink |
| Quiet list boundary | 1, divider color |
| Hard shadow | Offset (3, 3), blur 0, spread 0, dark ink |

Use the hard shadow on the primary button and occasional highlighted summary. Use flat surfaces and separators for dense lists. Shadow direction is a visual convention and does not need to mirror in RTL. Leave enough space for the painted shadow so it is not clipped.

Do not use large blurry elevations, glassmorphism, metallic textures, gradients, tilted cards, scattered stickers, or decorative gym photography in working screens. Flat UI complements the more expressive logo.

## 7. Component system

### Buttons

- Primary: yellow fill, ink text, 2px ink outline, 12px radius, small hard shadow.
- Secondary: white or neutral fill, ink text, outline, no hard shadow.
- Destructive: explicit red text/icon; use a red-filled confirmation button when finalizing deletion.
- Pressed: slightly reduce the hard-shadow offset or translate by 1px. No large bounce.
- Disabled: visibly muted with no active shadow, while remaining readable.
- Loading: preserve button width and label context; do not replace the whole screen with a spinner.
- One dominant primary action per task surface. Prevent repeated submission immediately.

### Inputs and search

- Persistent labels above or within fields; placeholders are examples, not the only labels.
- Neutral surface and 1.5px boundary; focused input gets a clear ink boundary plus a restrained yellow cue.
- Inline validation under the relevant field. Never use color alone to identify an error.
- Search label: `ابحث باسم العضو`. Keep the query and selected filter when returning from details.
- Money input uses a numeric keyboard for whole EGP and a visible currency suffix.
  Accept localized digits; reject nonzero fractions instead of rounding them.
- Phone input is LTR, optional, and uses a phone keyboard.
- Date controls show a readable date and open the date picker; do not require owners to type ISO dates.

### Member rows

Use one flat, tappable row per member. Place the name on the RTL leading edge, with status and expiry information below or alongside as space permits. Use a trailing chevron only if it clarifies navigation. Avoid a separate renew button in every crowded row; renewal is prominent on member details.

Allow names to wrap or take two lines. Do not let a long name push status or expiry off-screen. Do not add avatars, profile photos, gender icons, or member numbers as required fields: they are outside the PRD.

### Status chips

| Product status | UI label | Supporting text example |
| --- | --- | --- |
| Active | `ساري` | `فاضل ٨ أيام` |
| Expiring soon | `قرب يخلص` | `فاضل يومين` |
| Expired | `منتهي` | `انتهى يوم ٢٦ أكتوبر` |
| No subscription | `بدون اشتراك` | `لسه مفيش اشتراك مسجل` |

Number glyphs in examples illustrate copy only; format them using the app's selected digit convention. Derive all state from real dates, never a manually assigned chip. The three-day threshold comes from business policy, not a widget constant.

### Sheets and dialogs

Use a bottom sheet for add/edit forms and renewal. It must scroll above the keyboard, respect safe areas, and remain usable at large text scale. Keep labels and the confirmation action visible through scrolling; never let the keyboard cover the save button permanently.

Use a dialog for permanent deletion with the record name and specific consequences. Example member copy: `حذف أحمد محمد؟` followed by `هيتم حذف العضو وكل اشتراكاته نهائيًا، وهتتغير الإحصائيات المرتبطة بيه.` Actions: `رجوع` and `حذف نهائي`.

Do not offer undo if the system cannot restore the permanently deleted records. Do not introduce archive, cancel-record, or void actions.

## 8. Navigation and screen specifications

Keep the PRD's four bottom tabs: `الأعضاء`، `الحصص`، `الإحصائيات`، `الإعدادات`. Each has a label and an outlined icon. Selected state uses dark ink and a compact yellow highlight. Preserve scroll and filter state per tab. There is no additional dashboard tab.

### Sign-in

Light background, generous spacing, supplied wordmark, one short purpose statement: `اشتراكات الجيم وحساباته في مكان واحد`. One clear Google sign-in button. Show first-use internet requirements in plain Arabic when relevant. Do not add email/password or guest modes.

### Members — primary working screen

1. Compact header with gym name and page title. Avoid oversized greetings that push the list below the fold.
2. Clearly labeled `اشتراك جديد` action. Retain a smaller add-member action/FAB as required by the PRD, with accessible label `إضافة عضو`; do not create two equally dominant yellow buttons.
3. Search field.
4. Horizontally scrollable or wrapping status filters matching the PRD: all, active, expiring soon, expired. No extra filter is required merely because a status exists.
5. Efficient member rows, rendered lazily.

A compact count may appear within existing filter labels, but do not add a separate analytics dashboard or crowded grid above the list.

### Add/edit member and member picker

Name required, phone optional. In the subscription member picker, allow `إضافة عضو جديد` without forcing the owner to abandon the flow. Preserve entered form data while selecting or adding a member. After creating a member within the flow, return them as the selected member.

### Member details

Show name and phone, status chip, clearly labeled expiry date, and a prominent `جدّد الاشتراك` action. Below, show subscription history with amount, recording/payment date, and coverage dates. Place edit/delete actions in a secondary overflow menu, away from the main renewal target.

An early renewal updates the displayed overall expiry. Do not label the member as an upcoming subscription just because the newly recorded renewal period starts after today.

### Subscription / renewal sheet

- Member name, editable amount prefilled from settings, editable start date, computed end date.
- For early renewal show both: `الانتهاء الحالي` and `بعد التجديد`.
- Explicitly state the new expiry before confirmation. Label: `تأكيد التجديد` or `حفظ الاشتراك` depending on the task.
- A manually selected start cannot be after today. Automatic early renewal may
  start at the current future expiry. Gaps/future-only history without coverage
  today use `منتهي`, with renewal defaulting to today and remaining history dates
  preserved. Do not add an upcoming status or label a future end as current expiry.
- Payment is recorded now according to the current PRD. Do not add debt, installments, discounts, or a separate payment-date editor without a product decision.
- The subscription is one calendar month. Do not display “30 days” or align it to month boundaries.

### Drop-ins

Use `الحصص` as the navigation label and `حصة فردية` as supporting context. At the top show a compact quick-entry form: optional name, amount, `سجّل حصة`. Below show the selected day's sessions and a day picker. Use `بدون اسم` for a blank name. Keep individual edit/delete actions secondary.

### Statistics

A month picker, one emphasized total, and two quiet summary sections: `الاشتراكات` and `الحصص الفردية`, each with income and count. Label the total `إجمالي المتحصلات`; do not call it profit because expenses are not tracked. No charts, export buttons, forecasts, or invented metrics.

Always show the selected month. When data is incomplete, show that condition rather than presenting a misleading authoritative zero.

### Settings

Gym name, default subscription price, default drop-in price, save behavior, and sign out. Group fields cleanly. Do not expose debugging, cache controls, role management, currency pickers, or theme customization merely to fill the screen.

## 9. Feedback, loading, empty states, and synchronization

Use contextual states; do not use a blank screen for everything.

| Condition | Presentation |
| --- | --- |
| Initial local data not ready | Short skeleton/progress with meaningful label |
| No members | `لسه مفيش أعضاء` and `إضافة أول عضو` |
| No search matches | `مفيش أعضاء بالاسم ده` and clear-search control |
| No sessions for selected day | `مفيش حصص مسجلة في اليوم ده` |
| Complete month with no payments | Zero totals and `مفيش متحصلات مسجلة للشهر ده` |
| Failed action | Specific readable error and recovery action |
| Pending local write | Recommended compact label: `محفوظ على الجهاز — في انتظار المزامنة` |
| Remote rejection | Persistent affected-action error; do not retain a success claim |

The approved shell indicator stays low-emphasis and independent of membership
status. A cache-sourced snapshot is not proof of no internet. A successful local
write is not completed cloud sync. Avoid repeatedly interrupting normal offline
work with dialogs; keep rejected-action feedback available until dismissed.

## 10. Arabic copy and RTL behavior

- Write concise, respectful Egyptian Arabic. Prefer `جدّد الاشتراك`، `سجّل حصة`، `حفظ`، `رجوع`.
- Avoid exaggerated slang, technical SDK language, and jokes in money/deletion/error flows.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and logical start/end alignment.
- Mirror directional navigation icons; do not mirror brand artwork or every non-directional icon.
- Isolate phone numbers and mixed currency/date strings to prevent bidi reordering.
- Use the Gregorian calendar, matching PRD examples. Format display dates locally; store them independently of presentation.
- Use the selected `intl` locale for plural-aware phrases, currency, and dates rather than string concatenation.

## 11. Accessibility and responsive behavior

- Design for approximately 360 logical pixels in width and check at 320, 390, and 430.
- Also verify keyboard-open states, landscape, and large system text.
- On larger screens cap form and content width sensibly; do not scale everything proportionally.
- Give icon-only buttons semantic Arabic labels. Status remains understandable without color.
- Keep content above system navigation and account for edge-to-edge insets.
- Motion is subtle, approximately 120–200ms, and respects reduced-motion preferences.
- Keep search and primary actions reachable. Do not require precision taps on tiny overflow menus.

## 12. Flutter implementation expectations

- Define `ThemeData`, semantic colors, spacing, radii, typography, and border/shadow tokens centrally.
- Shared primitives should include primary/secondary buttons, labeled input, status chip, empty/error state, deletion dialog, and consistent sheet shell.
- Extract a component when it is reused or has meaningful behavior; do not wrap every Flutter widget in a custom abstraction.
- Use logical sizes and layout constraints; do not globally scale every dimension with screen width.
- Keep business rules, Firebase reads, and membership calculations out of widgets.
- Follow the BLoC presentation pattern in `ARCHITECTURE.md`: views render Bloc/Cubit state and dispatch intent; Business Logic uses repositories; Data Providers own Firebase APIs. Do not implement MVVM or ViewModel classes.
- Bundle the font and logo. Normal rendering must not need remote image/font requests.

## 13. Agent acceptance checklist

- [ ] The interface is visibly related to the supplied yellow logo.
- [ ] Member and history lists remain calm, readable, and fast.
- [ ] Only a few important components use hard shadows.
- [ ] RTL, mixed-direction numbers, long names, large text, and keyboard-open sheets work.
- [ ] Active, expiring, expired, and no-subscription states are labeled, not just colored.
- [ ] The renewal preview preserves remaining days and shows the correct new expiry.
- [ ] Deletion wording matches actual permanent deletion and member cascade behavior.
- [ ] Currency and threshold assumptions are centralized and unresolved PRD decisions remain visible.
- [ ] Loading, empty, filtered-empty, incomplete-cache, pending-write, and failure states are distinct.
- [ ] No dashboard, charts, archives, roles, or extra subscription types have been invented.
