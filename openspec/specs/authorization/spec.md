## ADDED Requirements

### Requirement: Endpoint authorization DSL
ApplicationEndpoint SHALL accept `authorize:` in resource DSL mapping operations to role arrays.

#### Scenario: Authorized request
- **WHEN** endpoint declares `authorize: { create: ["admin"] }` and request has `X-User-Role: admin`
- **THEN** request SHALL proceed normally

#### Scenario: Unauthorized request
- **WHEN** endpoint declares `authorize: { create: ["admin"] }` and request has `X-User-Role: viewer`
- **THEN** response SHALL be `[403, headers, {"error": "Forbidden", "status": 403}]`

#### Scenario: Public operation
- **WHEN** endpoint declares `authorize: { index: ["*"] }`
- **THEN** any request SHALL proceed regardless of role

#### Scenario: No authorization config
- **WHEN** endpoint has no `authorize:` option
- **THEN** all operations SHALL be public (backward compatible)

### Requirement: IR authorization field
IR resource MAY contain `authorization` object mapping operations to role arrays.

#### Scenario: IR output
- **WHEN** endpoint has `authorize: { create: ["admin"], index: ["*"] }`
- **THEN** IR SHALL include `"authorization": {"create": ["admin"], "index": ["*"]}`
