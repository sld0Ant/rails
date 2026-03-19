## Why

Endpoints have no error handling — `RecordNotFound` propagates as unhandled 500. No standardized error format. No caching headers. These are REST requirements: self-descriptive messages (error format) and cache constraint (Cache-Control headers).

## What Changes

- Endpoint dispatch catches `ActiveRecord::RecordNotFound` → 404 JSON, `StandardError` → 500 JSON
- Standardized error response format: `{ "error": "message", "status": 404 }`
- Endpoint DSL gains `cache:` option per action (max_age, etag support)
- Endpoint responses include Cache-Control headers when configured
- IR format gains optional `errors` and `cache` fields

## Capabilities

### New Capabilities
- `error-handling`: Standardized JSON error responses with proper HTTP status codes
- `cache-headers`: Cache-Control and ETag headers on endpoint responses

### Modified Capabilities
- `declarative-endpoints`: Endpoint dispatch wraps actions in error rescue
- `endpoint-routing`: endpoint_dispatch lambda catches exceptions and returns JSON errors
- `ddd-ir-format`: IR gains optional `cache` field per resource

## Impact

- **Modified**: endpoint_resources.rb (error handling in dispatch), application_endpoint.rb (cache headers), SchemaRegistry, IR format
- **No new dependencies**
