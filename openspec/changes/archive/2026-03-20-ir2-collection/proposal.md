## Why

`Repository#all` loads the entire table into memory. Real APIs need pagination, filtering, sorting, and search. Without collection semantics, every index endpoint returns unbounded results — unusable in production.

## What Changes

- Endpoint DSL gains `sort:`, `filter:`, `search:`, `per_page:` options
- Repository gains `paginate(page:, per:, sort:, filter:, search:)` method
- Service passes collection params from endpoint to repository
- Endpoint `index` method parses query params and delegates with collection options
- IR format gains `collection` field per resource
- SchemaRegistry collects collection config from Endpoint
- OpenAPI emitter adds query parameters for pagination/filter/sort

## Capabilities

### New Capabilities
- `collection-semantics`: Pagination, filtering, sorting, search in Endpoint → Service → Repository pipeline

### Modified Capabilities
- `declarative-endpoints`: Endpoint DSL extended with `sort:`, `filter:`, `search:`, `per_page:`
- `repository-pattern`: Repository gains `paginate` method with AR scoping
- `application-services`: Service `list_all` accepts and passes collection params
- `ddd-ir-format`: IR resource gains optional `collection` field
- `schema-registry`: Collects collection config from Endpoint class attributes
- `emitter-openapi`: Index operation gains query parameters (page, per_page, sort, filter fields)

## Impact

- **Modified**: ApplicationEndpoint, ApplicationRepository, ApplicationService templates; SchemaRegistry; OpenAPI emitter; IR format
- **No new files** — extends existing base classes
- **No new dependencies**
