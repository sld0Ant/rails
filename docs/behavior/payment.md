# Payment — Behavioral Spec

## Contracts

  invariant: amount_cents > 0
  invariant: enrollment_id is present
  invariant: status in ["pending", "confirmed", "refunded"]

## Authorization

| Action  | admin | instructor | student | guest |
|---------|-------|------------|---------|-------|
| index   | ✓     | ✗          | own     | ✗     |
| show    | ✓     | ✗          | own     | ✗     |
| create  | ✓     | ✗          | ✓       | ✗     |
| confirm | ✓     | ✗          | ✗       | ✗     |
| refund  | ✓     | ✗          | ✗       | ✗     |

## Lifecycle

  [pending] --confirm--> [confirmed] --refund--> [refunded]

  confirm: pending → confirmed
  refund: confirmed → refunded

## Scenarios

  Given payment in status "pending"
  When admin calls POST /payments/:id/confirm
  Then 200, payment status == "confirmed"
  And enrollment status changed to "active"

  Given payment in status "confirmed"
  When admin calls POST /payments/:id/refund
  Then 200, payment status == "refunded"
  And enrollment status changed to "cancelled"

## Side Effects

  @on(confirm): set enrollment.status = "active"
  @on(refund): set enrollment.status = "cancelled"
