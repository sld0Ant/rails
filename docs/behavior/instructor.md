# Instructor — Behavioral Spec

## Contracts

  invariant: name is present
  invariant: email matches URI::MailTo::EMAIL_REGEXP
  invariant: organization_id is present

## Authorization

| Action  | admin | instructor | student | guest |
|---------|-------|------------|---------|-------|
| index   | ✓     | ✓          | ✓       | ✓     |
| show    | ✓     | ✓          | ✓       | ✓     |
| create  | ✓     | ✗          | ✗       | ✗     |
| update  | ✓     | own        | ✗       | ✗     |
| destroy | ✓     | ✗          | ✗       | ✗     |
