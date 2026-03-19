## ADDED Requirements

### Requirement: Cache-Control headers from endpoint config
ApplicationEndpoint SHALL accept optional `cache:` in resource DSL. When configured, responses SHALL include `cache-control` header.

#### Scenario: Index with max_age
- **WHEN** endpoint declares `cache: { index: { max_age: 60 } }` and GET /parcels is called
- **THEN** response headers SHALL include `cache-control: max-age=60`

#### Scenario: Show with public cache
- **WHEN** endpoint declares `cache: { show: { max_age: 300, public: true } }` and GET /parcels/1 is called
- **THEN** response headers SHALL include `cache-control: public, max-age=300`

#### Scenario: No cache config
- **WHEN** endpoint has no `cache:` option
- **THEN** response SHALL NOT include cache-control header (default behavior)
