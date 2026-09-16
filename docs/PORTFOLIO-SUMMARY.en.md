# PaynEat POS

**A full-stack restaurant point-of-sale system — server, kitchen, cashier and manager, one codebase.**
Flutter (phone/tablet/web) + Node.js/Express backend, built with real restaurant business logic,
not a CRUD demo. [Live demo](https://suruchboss.github.io/PaynEat/) · [Full source](https://github.com/SuruchBoss/PaynEat)

## Numbers that are verified, not estimated

| | |
|---|---|
| **558** | automated tests, all passing (246 backend + 312 Flutter) |
| **32,400+** | lines of Dart |
| **6,900+** | lines of JavaScript |
| **82** | REST API endpoints |
| **29** | screens across 5 roles (server, kitchen, cashier, manager, admin) |
| **3 layers** | Clean Architecture (domain / data / presentation) on both sides |

## Why it's more than a CRUD demo

- **Money is calculated correctly, every time** — VAT, service charge and promotions are computed server-side only, never trusted from the client. Amounts are stored as whole units internally, eliminating decimal rounding drift.
- **A financial audit trail that cannot be edited or deleted** — every action that touches money (order cancellations, refunds, shift open/close, promotion redemption) is written inside the same database transaction as the change itself. If the log write fails, the change is rolled back too.
- **A real PromptPay QR code** — generated to the EMV QR standard with the amount locked automatically. A shared test suite proves the backend (JS) and app (Dart) implementations produce byte-identical output.
- **Real ESC/POS Bluetooth receipt printing**, an offline mode that keeps taking orders through a network outage, a customer loyalty/points system, and moving tables / merging bills / splitting a bill per guest.
- **Role permissions enforced server-side**, not just hidden in the UI — a direct API call is still checked against the signed-in role.

## Stack

**Frontend**: Flutter · GetX (state management) · Clean Architecture
**Backend**: Node.js · Express · SQLite · Socket.IO (real-time sync across every device)
**Deploy**: Docker Compose — the whole system runs on one machine, no internet dependency

## More detail

[28-page feature walkthrough with real screenshots](PaynEat-POS-Features-EN.pdf) ·
[2-minute demo video](video/PaynEat-POS-Demo-EN.mp4) ·
[Full README](../README.en.md)
