# Organization — Behavioral Spec

## Contracts

  invariant: name is present
  invariant: plan in ["free", "pro", "enterprise"]

## Authorization

| Action  | admin | instructor | student | guest |
|---------|-------|------------|---------|-------|
| index   | ✓     | ✗          | ✗       | ✗     |
| show    | ✓     | own        | own     | ✗     |
| create  | ✓     | ✗          | ✗       | ✗     |
| update  | ✓     | ✗          | ✗       | ✗     |
| destroy | ✓     | ✗          | ✗       | ✗     |
