## Why

Three remaining DDD/production gaps: (1) Aggregate boundaries — no enforcement that child resources are accessed through their root. Comment should only exist via /parcels/:id/comments, never /comments directly. (2) Value Objects — no way to embed address, coordinates, money without separate table. (3) Authorization — no role-based access control per operation.

## What Changes

- Entity DSL: `aggregate_root true` and `aggregate :ParentName` declarations
- Routing enforces aggregate boundaries — child resources only accessible under parent scope
- Value Objects embedded as JSON columns via `value_object` attribute type
- Endpoint DSL: `authorize:` option mapping operations to required roles
- Before-hook in endpoint dispatch checks authorization

## Capabilities

### New Capabilities
- `aggregate-boundaries`: Aggregate root/child declarations enforcing scoped access
- `value-objects`: Embeddable objects without identity stored as JSON columns
- `authorization`: Per-operation role-based access control in Endpoint

### Modified Capabilities
- `declarative-endpoints`: Endpoint gains `authorize:` option
- `endpoint-routing`: Enforces aggregate scoping for child resources
- `ddd-ir-format`: IR gains `aggregate`, `value_objects`, `authorization` fields

## Impact

- **Modified**: ApplicationEntity, ApplicationEndpoint, endpoint_resources.rb, IR, SchemaRegistry
- **No new dependencies**
